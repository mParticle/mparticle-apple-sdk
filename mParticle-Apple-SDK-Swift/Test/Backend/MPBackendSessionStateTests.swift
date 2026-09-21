import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendSessionStateTests: XCTestCase {
    func testOwnerRetainsSessionUntilCleared() {
        let state = MPBackendSessionState()
        weak var observed: MPSessionPRIVATE?
        autoreleasepool {
            let session = MPSessionPRIVATE(startTime: 100, userId: 1)
            observed = session
            state.session = session
            XCTAssertTrue(state.session === session)
        }
        XCTAssertNotNil(observed)
        state.session = nil
        XCTAssertNil(observed)
    }

    func testReplacementReleasesPreviousSession() {
        let state = MPBackendSessionState()
        weak var previous: MPSessionPRIVATE?
        autoreleasepool {
            state.session = MPSessionPRIVATE(startTime: 100, userId: 1)
            previous = state.session
        }
        let replacement = MPSessionPRIVATE(startTime: 200, userId: 2)
        state.session = replacement
        XCTAssertNil(previous)
        XCTAssertTrue(state.session === replacement)
    }

    func testMutationsUseTheSameSessionInstance() {
        let state = MPBackendSessionState()
        let session = MPSessionPRIVATE(startTime: 100, userId: 1)
        state.session = session
        session.sessionId = 42
        session.userId = 2
        session.sessionUserIds = "1,2"
        session.incrementCounter()
        XCTAssertTrue(state.session === session)
        XCTAssertEqual(state.session?.sessionId, 42)
        XCTAssertEqual(state.session?.userId, 2)
        XCTAssertEqual(state.session?.sessionUserIds, "1,2")
        XCTAssertEqual(state.session?.eventCounter, 1)
    }

    func testTransitionSupportsNestedTransitionsAndAccessors() {
        let state = MPBackendSessionState()
        let completed = expectation(description: "recursive transition")
        DispatchQueue.global().async {
            state.withSessionLock {
                state.session = MPSessionPRIVATE(startTime: 100, userId: 1)
                state.withSessionLock {
                    XCTAssertEqual(state.session?.startTime, 100)
                    state.session = nil
                }
                XCTAssertNil(state.session)
            }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 2)
    }

    func testConcurrentTransitionsDoNotLoseUpdates() {
        let state = MPBackendSessionState()
        state.session = MPSessionPRIVATE(startTime: 100, userId: 1)
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            state.withSessionLock {
                state.session?.sessionId += 1
            }
        }
        XCTAssertEqual(state.session?.sessionId, 100)
    }
}
