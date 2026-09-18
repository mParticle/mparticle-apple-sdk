import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendMessageWriterTests: MPBackendWorkflowTestCase {
    func testSessionlessWriteDoesNotCreateSession() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let message = fixture.message()
            fixture.writer.saveMessage(message, updateSession: true)
            XCTAssertEqual(fixture.persistence.calls, ["message"])
            XCTAssertTrue(fixture.persistence.savedMessages.first === message)
            XCTAssertNil(fixture.state.session)
        }
    }

    func testBreadcrumbAndSessionAreSavedBeforeUploadIsEnqueued() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.machine.triggerMessageTypes = ["bc"]
            fixture.writer.saveMessage(fixture.message(type: "bc", timestamp: 140), updateSession: true)
            XCTAssertEqual(fixture.persistence.calls, ["message", "breadcrumb", "saveSession", "enqueue"])
            XCTAssertEqual(session.endTime, 140)
            XCTAssertTrue(fixture.persistence.savedSessions.first === session)
            XCTAssertEqual(session.sessionId, 42)
            XCTAssertEqual(fixture.uploads, 0)
            fixture.enqueued.removeFirst()()
            XCTAssertEqual(fixture.uploads, 1)
        }
    }

    func testPersistedSessionIsUpdatedAndZeroTimestampUsesClock() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            session.sessionId = 7
            fixture.background = true
            fixture.writer.saveMessage(fixture.message(timestamp: 0), updateSession: true)
            XCTAssertEqual(fixture.persistence.calls, ["message", "updateSession"])
            XCTAssertEqual(session.endTime, 200)
            XCTAssertEqual(fixture.state.timeOfLastEventInBackground, 200)
        }
    }

    func testOptOutRejectsMessageAfterRecordingBackgroundTimestamp() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.background = true
            fixture.machine.optOut = true
            fixture.writer.saveMessage(fixture.message(timestamp: 123), updateSession: true)
            XCTAssertEqual(fixture.state.timeOfLastEventInBackground, 123)
            XCTAssertTrue(fixture.persistence.calls.isEmpty)
            XCTAssertEqual(session.endTime, 100)
            XCTAssertTrue(fixture.enqueued.isEmpty)
        }
    }

    func testOptOutMessageRemainsAllowed() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.machine.optOut = true
            fixture.writer.saveMessage(fixture.message(type: "o"), updateSession: true)
            XCTAssertEqual(fixture.persistence.savedMessages.count, 1)
        }
    }

    func testUpdateSessionFalseLeavesSessionUntouched() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.writer.saveMessage(fixture.message(timestamp: 150), updateSession: false)
            XCTAssertEqual(fixture.persistence.calls, ["message"])
            XCTAssertEqual(session.endTime, 100)
        }
    }

    func testNextWriteUsesReplacementStore() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let first = fixture.persistence
            fixture.writer.saveMessage(fixture.message(), updateSession: false)
            fixture.persistence = MPBackendRecordingPersistence()
            fixture.writer.saveMessage(fixture.message(), updateSession: false)
            XCTAssertEqual(first.savedMessages.count, 1)
            XCTAssertEqual(fixture.persistence.savedMessages.count, 1)
        }
    }

    func testExistingEndMessagePreventsDuplicateConstruction() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.persistence.existingEndMessage = fixture.message(type: "se")
            fixture.writer.confirmEndSessionMessage(session)
            XCTAssertEqual(fixture.persistence.calls, ["fetchEnd"])
            XCTAssertEqual(fixture.contextReads, 0)
        }
    }

    func testEndMessageUsesEndingSessionAndEncodesAttributes() throws {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let current = fixture.session()
            let ending = MPSessionPRIVATE(startTime: 10, userId: 2, uuid: "ending")
            ending.endTime = 30
            ending.backgroundTime = 5
            ending.incrementCounter()
            ending.attributesDictionary = ["number": 3, "flag": true]
            fixture.writer.confirmEndSessionMessage(ending)
            let message = try XCTUnwrap(fixture.persistence.savedMessages.first)
            let payload = try XCTUnwrap(message.dictionaryRepresentation())
            XCTAssertEqual(fixture.persistence.calls, ["fetchEnd", "message"])
            XCTAssertEqual(message.timestamp, 30)
            XCTAssertEqual(payload["sl"] as? Double, 15000)
            XCTAssertEqual(payload["slx"] as? Double, 20000)
            XCTAssertEqual(payload["en"] as? Int, 1)
            XCTAssertEqual(payload["sid"] as? String, "ending")
            XCTAssertEqual(payload["attrs"] as? NSDictionary, ["number": "3", "flag": "true"])
            XCTAssertEqual(current.endTime, 100)
        }
    }

    func testEventTriggerQueuesUploadOnlyAfterSessionUpdate() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            _ = fixture.session()
            fixture.machine.triggerMessageTypes = nil
            let hasher = MPIHasher(logger: MPLog(logLevel: .none))
            fixture.machine.triggerEventTypes = [hasher.hashTriggerEventName("purchase", eventType: "transaction")]
            let message = fixture.message()
            message.messageData = Data(#"{"n":"purchase","et":"transaction"}"#.utf8)
            fixture.writer.saveMessage(message, updateSession: true)
            XCTAssertEqual(fixture.persistence.calls, ["message", "saveSession", "enqueue"])
            XCTAssertEqual(fixture.uploads, 0)
        }
    }

}
