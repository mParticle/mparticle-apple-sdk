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

    private var timingProperties: [ReferenceWritableKeyPath<MPBackendSessionState, TimeInterval>] {
        [\.timeOfLastEventInBackground]
    }

    func testTimingReadsWaitForSessionTransition() {
        for property in timingProperties {
            assertReadWaitsForTransition(property, initial: 20, final: 40)
        }
    }

    func testTimingWritesWaitForSessionTransition() {
        for property in timingProperties {
            assertWriteWaitsForTransition(property, initial: 20, final: 40)
        }
    }

    func testConcurrentTimingAccess() {
        let state = MPBackendSessionState()
        let properties = timingProperties
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            for property in properties {
                state[keyPath: property] = TimeInterval(index)
                XCTAssertGreaterThanOrEqual(state[keyPath: property], 0)
                state.withSessionLock {
                    state[keyPath: property] = TimeInterval(index)
                    XCTAssertEqual(state[keyPath: property], TimeInterval(index))
                }
            }
        }
    }

    private func assertReadWaitsForTransition<Value: Equatable>(
        _ property: ReferenceWritableKeyPath<MPBackendSessionState, Value>, initial: Value, final: Value,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let state = MPBackendSessionState()
        let started = DispatchSemaphore(value: 0)
        let finished = DispatchSemaphore(value: 0)
        state.withSessionLock {
            state[keyPath: property] = initial
            DispatchQueue.global().async {
                started.signal()
                XCTAssertEqual(state[keyPath: property], final, file: file, line: line)
                finished.signal()
            }
            XCTAssertEqual(started.wait(timeout: .now() + 2), .success, file: file, line: line)
            XCTAssertEqual(finished.wait(timeout: .now() + 0.1), .timedOut, file: file, line: line)
            state[keyPath: property] = final
        }
        XCTAssertEqual(finished.wait(timeout: .now() + 2), .success, file: file, line: line)
    }

    private func assertWriteWaitsForTransition<Value: Equatable>(
        _ property: ReferenceWritableKeyPath<MPBackendSessionState, Value>, initial: Value, final: Value,
        file: StaticString = #filePath, line: UInt = #line
    ) {
        let state = MPBackendSessionState()
        state[keyPath: property] = initial
        let started = DispatchSemaphore(value: 0)
        let finished = DispatchSemaphore(value: 0)
        state.withSessionLock {
            DispatchQueue.global().async {
                started.signal()
                state[keyPath: property] = final
                finished.signal()
            }
            XCTAssertEqual(started.wait(timeout: .now() + 2), .success, file: file, line: line)
            XCTAssertEqual(finished.wait(timeout: .now() + 0.1), .timedOut, file: file, line: line)
            XCTAssertEqual(state[keyPath: property], initial, file: file, line: line)
        }
        XCTAssertEqual(finished.wait(timeout: .now() + 2), .success, file: file, line: line)
        XCTAssertEqual(state[keyPath: property], final, file: file, line: line)
    }
}
