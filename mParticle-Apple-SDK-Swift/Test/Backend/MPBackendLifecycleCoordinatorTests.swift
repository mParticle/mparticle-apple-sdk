import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendLifecycleCoordinatorTests: MPBackendWorkflowTestCase {
    func testTimeoutThresholdAndAutomaticTrackingGate() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.state.timeOfLastEventInBackground = 140
            fixture.dependencies.now = { 199 }
            XCTAssertFalse(fixture.application.shouldEndSession())
            fixture.dependencies.now = { 200 }
            XCTAssertTrue(fixture.application.shouldEndSession())
            fixture.automaticTracking = false
            fixture.application.endSessionIfTimedOut()
            XCTAssertTrue(fixture.state.session === session)
            XCTAssertTrue(fixture.persistence.calls.isEmpty)
        }
    }

    func testTimeoutPreservesDistinctClockReadsAndCorrectsBackgroundDuration() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.machine.currentSession = session
            fixture.persistence.sessions = [session]
            fixture.state.timeOfLastEventInBackground = 120
            fixture.state.timeAppWentToBackgroundInCurrentSession = 100
            var times: [TimeInterval] = [210, 211, 213]
            fixture.dependencies.now = { times.removeFirst() }
            fixture.application.endSessionIfTimedOut()
            XCTAssertTrue(times.isEmpty)
            XCTAssertEqual(session.endTime, 120)
            XCTAssertEqual(session.backgroundTime, 22)
            XCTAssertEqual(fixture.state.timeOfLastEventInBackground, 211)
            XCTAssertEqual(fixture.state.timeAppWentToBackgroundInCurrentSession, 211)
            XCTAssertNil(fixture.state.session)
            XCTAssertNil(fixture.machine.currentSession)
            XCTAssertEqual(fixture.persistence.calls.first, "updateSession")
            XCTAssertEqual(fixture.uploads, 1)
        }
    }

    func testTimeoutQueuesSessionChangesFromOtherQueues() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.state.timeOfLastEventInBackground = 120
            fixture.isMessageQueue = false
            fixture.application.endSessionIfTimedOut()
            XCTAssertTrue(fixture.state.session === session)
            XCTAssertEqual(session.endTime, 100)
            fixture.drainMessageQueue()
            XCTAssertNil(fixture.state.session)
        }
    }

    func testBackgroundEntryCapturesTimeBeforeQueuingAndPersistsTransitionBeforeLoop() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.isMessageQueue = false
            fixture.application.applicationDidEnterBackground()
            XCTAssertTrue(fixture.background)
            XCTAssertEqual(fixture.persistence.calls, ["background:true", "beginTask"])
            fixture.dependencies.now = { 300 }
            fixture.drainMessageQueue()
            XCTAssertEqual(fixture.state.timeAppWentToBackground, 200)
            XCTAssertEqual(fixture.state.timeAppWentToBackgroundInCurrentSession, 200)
            XCTAssertEqual(fixture.state.nextCleanUpTime, 86700)
            XCTAssertEqual(session.numberOfInterruptions, 1)
            XCTAssertEqual(fixture.persistence.calls.suffix(3), ["message", "saveSession", "beginLoop"])
            XCTAssertEqual(fixture.persistence.savedMessages.first?.dictionaryRepresentation()?["t"] as? String, "app_back")
            XCTAssertEqual(fixture.state.timeOfLastEventInBackground, fixture.persistence.savedMessages.first?.timestamp)
        }
    }

    func testForegroundCancelsBeforeQueuedSessionWorkAndUpdatesContinuingSession() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.state.timeAppWentToBackground = 100
            fixture.state.timeAppWentToBackgroundInCurrentSession = 100
            fixture.isMessageQueue = false
            fixture.application.applicationWillEnterForeground()
            XCTAssertEqual(fixture.persistence.calls, ["background:false", "cancelLoop", "endTask"])
            XCTAssertEqual(session.backgroundTime, 0)
            fixture.drainMessageQueue()
            XCTAssertEqual(session.backgroundTime, 100)
            XCTAssertTrue(fixture.state.session === session)
            XCTAssertEqual(fixture.persistence.calls.last, "config")
        }
    }

    func testForegroundDoesNotAddPreviousSessionBackgroundDurationToNewSession() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let session = fixture.session()
            fixture.state.timeAppWentToBackground = 100
            fixture.state.timeAppWentToBackgroundInCurrentSession = 150
            fixture.application.applicationWillEnterForeground()
            XCTAssertEqual(session.backgroundTime, 0)
        }
    }

    func testBecomeActiveKeepsLaunchAndPreviousForegroundFields() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.state.timeAppWentToBackgroundInCurrentSession = 120
            fixture.state.timeOfLastEventInBackground = 130
            fixture.application.applicationDidBecomeActive()
            let first = try XCTUnwrap(fixture.persistence.savedMessages.first?.dictionaryRepresentation())
            XCTAssertEqual(first["t"] as? String, "app_fore")
            XCTAssertEqual(first["sf"] as? Bool, true)
            XCTAssertNil(first["pft"])
            XCTAssertEqual(fixture.state.timeAppWentToBackgroundInCurrentSession, 0)
            XCTAssertEqual(fixture.state.timeOfLastEventInBackground, 0)
            fixture.dependencies.now = { 300 }
            fixture.application.applicationDidBecomeActive()
            let second = try XCTUnwrap(fixture.persistence.savedMessages.last?.dictionaryRepresentation())
            XCTAssertEqual(second["pft"] as? Double, 200000)
            XCTAssertEqual(second["sf"] as? Bool, false)
            XCTAssertEqual(fixture.state.previousForegroundTime, 300000)
        }
    }

    func testBecomeActiveDoesNothingWhenOptedOut() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.machine.optOut = true
            fixture.state.timeOfLastEventInBackground = 100
            fixture.application.applicationDidBecomeActive()
            XCTAssertTrue(fixture.persistence.calls.isEmpty)
            XCTAssertEqual(fixture.state.timeOfLastEventInBackground, 100)
        }
    }

    func testCleanupPreservesDueBoundaryRetentionAndPurgeCacheOrder() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.state.nextCleanUpTime = 200
            fixture.application.cleanUp(currentTime: 200)
            XCTAssertEqual(fixture.persistence.calls, ["purge", "clearCache"])
            fixture.persistence.calls = []
            fixture.maxAge = 50
            fixture.application.cleanUp(currentTime: 201)
            XCTAssertEqual(fixture.persistence.calls, ["deleteRecords", "purge", "clearCache"])
            XCTAssertEqual(fixture.persistence.cutoffs, [151])
            XCTAssertEqual(fixture.state.nextCleanUpTime, 86601)
            fixture.maxAge = nil
            fixture.application.cleanUp(currentTime: 86602)
            XCTAssertEqual(fixture.persistence.cutoffs.last, 86602 - 90 * 86400)
        }
    }
}
