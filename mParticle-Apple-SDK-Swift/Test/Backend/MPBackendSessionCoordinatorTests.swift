import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendSessionCoordinatorTests: MPBackendWorkflowTestCase {
    func testSessionStartKeepsSDKInstanceSelectedBeforeTrackingRead() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let replacement = MPBackendSessionFixture()
            fixture.onAutomaticSessionTrackingRead = { [weak fixture] in
                fixture?.replacementStateMachine = replacement.machine
                fixture?.automaticTracking = false
            }
            fixture.coordinator.beginSession(isManual: false, date: Date(timeIntervalSince1970: 200))
            XCTAssertNotNil(fixture.state.session)
            XCTAssertTrue(fixture.machine.currentSession === fixture.state.session)
            XCTAssertNil(replacement.machine.currentSession)
        }
    }

    func testAutomaticTrackingGatesBeginAndEndButManualCallsWork() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.automaticTracking = false
            fixture.coordinator.beginSession()
            XCTAssertNil(fixture.state.session)
            fixture.coordinator.beginSession(isManual: true, date: nil)
            XCTAssertNotNil(fixture.state.session)
            fixture.coordinator.endSession()
            XCTAssertNotNil(fixture.state.session)
            fixture.coordinator.endSession(isManual: true)
            XCTAssertNil(fixture.state.session)
        }
    }

    func testOptOutPreventsBeginningAndEnding() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.machine.optOut = true
            fixture.coordinator.beginSession(isManual: true, date: nil)
            XCTAssertNil(fixture.state.session)
            let session = fixture.session()
            fixture.coordinator.endSession(isManual: true)
            XCTAssertTrue(fixture.state.session === session)
            XCTAssertTrue(fixture.persistence.calls.isEmpty)
        }
    }

    func testExistingSessionDoesNotLoadMetadataOrBroadcastAgain() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.coordinator.beginSession()
            XCTAssertTrue(fixture.state.session === session)
            XCTAssertEqual(fixture.applicationReads, 0)
            XCTAssertEqual(fixture.deviceReads, 0)
            XCTAssertTrue(fixture.began.isEmpty)
        }
    }

    func testBeginPublishesOnlyAfterSessionAndStartMessageArePersisted() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.persistence.onSaveMessage = { [unowned fixture] in
                XCTAssertNil(fixture.machine.currentSession)
                XCTAssertTrue(fixture.persistence.savedSessions.first === fixture.state.session)
            }
            fixture.onBegin = { [unowned fixture] session in
                XCTAssertTrue(fixture.machine.currentSession === session)
                XCTAssertEqual(fixture.persistence.calls, ["saveSession", "previous", "message", "updateSession"])
            }
            fixture.coordinator.beginSession()
            XCTAssertEqual(fixture.began.count, 1)
            XCTAssertTrue(fixture.state.session === fixture.machine.currentSession)
            XCTAssertEqual(fixture.applicationReads, 1)
            XCTAssertEqual(fixture.deviceReads, 1)
        }
    }

    func testTemporarySessionIsImmediateAndAdoptsUUIDWithoutSecondBroadcast() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.isMessageQueue = false
            fixture.coordinator.createTempSession()
            let uuid = fixture.pendingUUID
            XCTAssertNotNil(uuid)
            XCTAssertEqual(fixture.pendingStartTime, 200000)
            XCTAssertEqual(fixture.began.count, 1)
            XCTAssertNil(fixture.state.session)
            fixture.clearPending = { [unowned fixture] in XCTAssertNotNil(fixture.machine.currentSession) }
            fixture.dependencies.now = { 250 }
            fixture.coordinator.beginSession()
            fixture.dependencies.now = { 300 }
            fixture.enqueued.removeFirst()()
            XCTAssertEqual(fixture.state.session?.uuid, uuid)
            XCTAssertEqual(fixture.state.session?.startTime, 250)
            XCTAssertEqual(fixture.began.count, 1)
            XCTAssertNil(fixture.pendingUUID)
            XCTAssertNil(fixture.state.pendingSessionUUID)
        }
    }

    func testPendingEndRetriesUntilRealSessionIsAvailable() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.coordinator.createTempSession()
            fixture.coordinator.endSession(isManual: true)
            XCTAssertEqual(fixture.scheduled.map(\.0), [0.1])
            XCTAssertTrue(fixture.ended.isEmpty)
            fixture.coordinator.beginSession()
            fixture.scheduled.removeFirst().1()
            XCTAssertEqual(fixture.ended.count, 1)
            XCTAssertNil(fixture.state.session)
        }
    }

    func testReentrantTemporaryCreationPublishesOnlyOneSession() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let coordinator = fixture.coordinator
            fixture.onBegin = { [unowned fixture] _ in
                if fixture.began.count == 1 { coordinator.createTempSession() }
            }
            coordinator.createTempSession()
            XCTAssertEqual(fixture.began.count, 1)
            XCTAssertEqual(fixture.pendingUUID, fixture.began.first?.uuid)
            coordinator.beginSession()
            XCTAssertEqual(fixture.state.session?.uuid, fixture.began.first?.uuid)
            XCTAssertEqual(fixture.began.count, 1)
            XCTAssertNil(fixture.pendingUUID)
        }
    }

    func testPreviousSessionLengthUsesIntegerJSONAndHandlesInvalidValues() {
        onMessageQueue {
            let cases: [(Double, Int)] = [
                (12.75, 12), (-0.2, 0), (-12.75, -12),
                (.nan, 0), (.infinity, 0), (-.infinity, 0),
                (Double(Int.max), 0), (Double(Int.min), Int.min), (.greatestFiniteMagnitude, 0)
            ]
            for (length, expected) in cases {
                let fixture = MPBackendSessionFixture()
                let previous = MPSessionPRIVATE(startTime: 10, userId: 1, uuid: "previous")
                previous.length = length
                fixture.persistence.previousSession = previous
                fixture.coordinator.beginSession(isManual: true, date: nil)
                let data = try XCTUnwrap(fixture.persistence.savedMessages.first?.messageData)
                let json = try XCTUnwrap(String(data: data, encoding: .utf8))
                XCTAssertNotNil(json.range(of: "\"psl\":\\s*\(expected)(?=[,}])", options: .regularExpression), json)
            }
        }
    }

    func testConcurrentTemporaryCreationAndAdoptionKeepPublishedUUID() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let coordinator = fixture.coordinator
            let published = DispatchSemaphore(value: 0)
            let finishPublication = DispatchSemaphore(value: 0)
            let started = DispatchSemaphore(value: 0)
            let group = DispatchGroup()
            let queue = DispatchQueue.global(qos: .userInitiated)
            fixture.onBegin = { [unowned fixture] _ in
                fixture.onBegin = nil
                published.signal()
                XCTAssertEqual(finishPublication.wait(timeout: .now() + 2), .success)
            }
            queue.async(group: group) { coordinator.createTempSession() }
            XCTAssertEqual(published.wait(timeout: .now() + 2), .success)
            queue.async(group: group) { started.signal(); coordinator.createTempSession() }
            queue.async(group: group) { started.signal(); coordinator.beginSession(isManual: true, date: nil) }
            XCTAssertEqual(started.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(started.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(group.wait(timeout: .now() + 0.1), .timedOut)
            finishPublication.signal()
            XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(fixture.began.count, 1)
            XCTAssertEqual(fixture.state.session?.uuid, fixture.began.first?.uuid)
            XCTAssertEqual(fixture.persistence.savedSessions.first?.uuid, fixture.began.first?.uuid)
            XCTAssertNil(fixture.pendingUUID)
            XCTAssertNil(fixture.state.pendingSessionUUID)
        }
    }

    func testPreviousSessionFieldsAndCapturedStartDate() throws {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let previous = MPSessionPRIVATE(startTime: 10, userId: 1, uuid: "previous")
            previous.endTime = 22.75
            fixture.persistence.previousSession = previous
            fixture.coordinator.beginSession(isManual: true, date: Date(timeIntervalSince1970: 150))
            let message = try XCTUnwrap(fixture.persistence.savedMessages.first)
            let payload = try XCTUnwrap(message.dictionaryRepresentation())
            XCTAssertEqual(message.timestamp, 150)
            XCTAssertEqual(payload["pid"] as? String, "previous")
            XCTAssertEqual(payload["pss"] as? Double, 10000)
            XCTAssertEqual(payload["psl"] as? Int, 12)
        }
    }

    func testEndCopiesThenConfirmsArchivesBroadcastsAndClears() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            session.userId = 2
            session.sessionUserIds = "1,2"
            fixture.machine.currentSession = session
            fixture.onEnd = { [unowned fixture] ended in
                XCTAssertFalse(ended === session)
                XCTAssertEqual(ended.userId, 2)
                XCTAssertEqual(ended.sessionUserIds, "1,2")
                XCTAssertTrue(fixture.state.session === session)
                XCTAssertTrue(fixture.machine.currentSession === session)
            }
            fixture.coordinator.endSession()
            XCTAssertEqual(fixture.persistence.calls, ["fetchEnd", "message", "archive", "broadcastEnd"])
            XCTAssertNil(fixture.state.session)
            XCTAssertNil(fixture.machine.currentSession)
            fixture.coordinator.endSession()
            XCTAssertEqual(fixture.ended.count, 1)
        }
    }

    func testRecoveryBroadcastsBeforeConfirmationAndExcludesCurrentSession() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let current = fixture.session()
            current.sessionId = 42
            let old = MPSessionPRIVATE(startTime: 10, userId: 1)
            old.sessionId = 7
            fixture.persistence.sessions = [old, current]
            var completed = false
            fixture.coordinator.processOpenSessions(endingCurrent: false) { completed = true }
            XCTAssertEqual(fixture.ended.count, 1)
            XCTAssertTrue(fixture.ended.first === old)
            XCTAssertTrue(fixture.state.session === current)
            XCTAssertEqual(fixture.persistence.calls, ["fetchSessions", "broadcastEnd", "fetchEnd", "message", "upload"])
            XCTAssertTrue(completed)
            XCTAssertTrue(fixture.persistence.archived.isEmpty)
        }
    }

    func testRecoveryClearsBothReferencesAndRoutesCompletionToMessageQueue() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let current = fixture.session()
            fixture.machine.currentSession = current
            fixture.persistence.sessions = [current]
            fixture.isMessageQueue = false
            var completed = false
            fixture.coordinator.processOpenSessions(endingCurrent: true) { completed = true }
            XCTAssertNil(fixture.state.session)
            XCTAssertNil(fixture.machine.currentSession)
            XCTAssertEqual(
                fixture.persistence.calls,
                ["fetchSessions", "clearEvents", "broadcastEnd", "fetchEnd", "message", "upload"]
            )
            XCTAssertFalse(completed)
            fixture.enqueued.removeFirst()()
            XCTAssertTrue(completed)
        }
    }

    func testEmptyRecoveryCompletesInlineOnMessageQueueWithoutUpload() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            var completed = false
            fixture.coordinator.uploadOpenSessions([], completionHandler: { completed = true })
            XCTAssertTrue(completed)
            XCTAssertEqual(fixture.uploads, 0)
            XCTAssertTrue(fixture.enqueued.isEmpty)
        }
    }

}
