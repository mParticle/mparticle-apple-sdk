import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPExecutorTests: XCTestCase {
    func testIsMessageQueueIsFalseOffQueue() {
        let executor = MPExecutorPRIVATE()
        XCTAssertFalse(executor.isMessageQueue)
    }

    func testIsMessageQueueIsTrueOnQueue() {
        let executor = MPExecutorPRIVATE()
        let expectation = expectation(description: "message queue")

        executor.executeOnMessageSync {
            XCTAssertTrue(executor.isMessageQueue)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertFalse(executor.isMessageQueue)
    }

    func testExecuteOnMessageRunsInlineWhenAlreadyOnQueue() {
        let executor = MPExecutorPRIVATE()
        let expectation = expectation(description: "nested inline")

        executor.executeOnMessageSync {
            var nestedRan = false
            executor.executeOnMessage {
                nestedRan = true
            }
            XCTAssertTrue(nestedRan)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testExecuteOnMessageSyncDoesNotDeadlockWhenAlreadyOnQueue() {
        let executor = MPExecutorPRIVATE()
        var ran = false

        executor.executeOnMessageSync {
            executor.executeOnMessageSync {
                ran = true
            }
        }

        XCTAssertTrue(ran)
    }

    func testExecuteOnMessageDispatchesWhenOffQueue() {
        let executor = MPExecutorPRIVATE()
        let expectation = expectation(description: "async message")
        var ran = false

        executor.executeOnMessage {
            XCTAssertTrue(executor.isMessageQueue)
            ran = true
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(ran)
    }

    func testExecuteOnMainRunsInlineOnMainThread() {
        let executor = MPExecutorPRIVATE()
        var ran = false

        executor.executeOnMain {
            XCTAssertTrue(Thread.isMainThread)
            ran = true
        }

        XCTAssertTrue(ran)
    }

    func testExecuteOnMainSyncRunsInlineOnMainThread() {
        let executor = MPExecutorPRIVATE()
        var ran = false

        executor.executeOnMainSync {
            XCTAssertTrue(Thread.isMainThread)
            ran = true
        }

        XCTAssertTrue(ran)
    }

    func testExecuteOnMainFromBackgroundRunsOnMain() {
        let executor = MPExecutorPRIVATE()
        let expectation = expectation(description: "async main")

        DispatchQueue.global(qos: .userInitiated).async {
            executor.executeOnMain {
                XCTAssertTrue(Thread.isMainThread)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1)
    }

    func testExecuteOnMainSyncFromBackgroundRunsOnMainBeforeReturning() {
        let executor = MPExecutorPRIVATE()
        let expectation = expectation(description: "sync main")

        DispatchQueue.global(qos: .userInitiated).async {
            var ran = false
            executor.executeOnMainSync {
                XCTAssertTrue(Thread.isMainThread)
                ran = true
            }
            XCTAssertTrue(ran)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
