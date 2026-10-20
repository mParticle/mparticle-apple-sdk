import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendAssemblyTests: XCTestCase {
    private let host = MPBackendFakeHost()
    private func makeAssembly(owner: MPBackendFakeOwner) -> MPBackendAssembly {
        MPBackendAssembly(state: MPBackendSessionState(), host: host, owner: owner)
    }

    func testTheAssemblyHoldsItsOwnerWeakly() {
        var owner: MPBackendFakeOwner? = MPBackendFakeOwner(host: host)
        weak var released = owner
        let assembly = makeAssembly(owner: owner!)
        owner = nil

        XCTAssertNil(released)
        XCTAssertNil(assembly.sessionDependencies.persistence())
        let context = assembly.sessionDependencies.makeMessageContext()
        XCTAssertNil(context.dataPlanId)
        XCTAssertNil(context.dataPlanVersion)
    }

    func testSessionCallbacksReachTheOwnerAndTheHost() {
        let owner = MPBackendFakeOwner(host: host)
        let persistence = MPBackendRecordingPersistence()
        owner.persistenceValue = persistence
        let assembly = makeAssembly(owner: owner)
        let dependencies = assembly.sessionDependencies

        XCTAssertTrue(dependencies.persistence() === persistence)
        XCTAssertTrue(dependencies.stateMachine() === host.machine)
        XCTAssertTrue(dependencies.makeMessageContext() === owner.messageContext)
        XCTAssertTrue(dependencies.logger() === host.log)
        var uploaded = false
        dependencies.upload { uploaded = true }
        XCTAssertTrue(uploaded)
        XCTAssertEqual(owner.calls, ["upload"])
    }

    func testQueuedWorkRunsOnlyWhileTheOwnerLives() {
        var owner: MPBackendFakeOwner? = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner!)
        var runs: [String] = []

        assembly.sessionDependencies.enqueueOnMessage { runs.append("enqueued") }
        assembly.sessionLifecycleDependencies.executeOnMessage { runs.append("executed") }
        host.queue.sync {}
        owner = nil
        assembly.sessionDependencies.enqueueOnMessage { runs.append("enqueued after release") }
        assembly.sessionLifecycleDependencies.executeOnMessage { runs.append("executed after release") }
        host.queue.sync {}

        XCTAssertEqual(runs, ["enqueued", "executed"])
    }

    func testQueuedWorkKeepsTheOwnerUntilItRuns() {
        var owner: MPBackendFakeOwner? = MPBackendFakeOwner(host: host)
        weak var released = owner
        let assembly = makeAssembly(owner: owner!)
        var runs = 0

        host.queue.suspend()
        assembly.sessionDependencies.enqueueOnMessage { runs += 1 }
        owner = nil
        XCTAssertNotNil(released, "queued work holds the controller until it runs")
        host.queue.resume()
        host.queue.sync {}

        XCTAssertEqual(runs, 1)
    }

    func testScheduledWorkRunsOnlyWhileTheOwnerLives() {
        var owner: MPBackendFakeOwner? = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner!)
        let ran = expectation(description: "scheduled while the controller lives")
        let skipped = expectation(description: "scheduled after the controller is gone")
        skipped.isInverted = true

        assembly.sessionLifecycleDependencies.schedule(0) { ran.fulfill() }
        wait(for: [ran], timeout: 2)
        owner = nil
        assembly.sessionLifecycleDependencies.schedule(0) { skipped.fulfill() }
        wait(for: [skipped], timeout: 0.3)
    }

    func testSessionLifecycleCallbacksReachTheOwner() {
        let owner = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner)
        let lifecycle = assembly.sessionLifecycleDependencies

        lifecycle.createPendingSession("pending")
        lifecycle.setPendingSessionStartTime(5)
        lifecycle.clearPendingSession()
        lifecycle.clearEmptyTimedEvents()

        XCTAssertEqual(owner.calls, [
            "createPendingSession:pending", "setPendingSessionStartTime:5.0", "clearPendingSession",
            "clearEmptyTimedEvents"
        ])
    }

    func testSessionBroadcastsReachTheDelegateOnTheMainThread() {
        let owner = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner)
        let session = MPSessionPRIVATE(startTime: 100, userId: 1)
        let broadcast = expectation(description: "both broadcasts delivered")

        DispatchQueue.global().async {
            assembly.sessionLifecycleDependencies.broadcastBegin(session)
            assembly.sessionLifecycleDependencies.broadcastEnd(session)
            DispatchQueue.main.async { broadcast.fulfill() }
        }
        wait(for: [broadcast], timeout: 2)

        XCTAssertEqual(owner.delegate.calls, ["sessionDidBegin", "sessionDidEnd"])
        XCTAssertEqual(owner.delegate.callsOnMainThread, [true, true])
    }

    func testSessionStartsArePinnedToTheOwningController() {
        let owner = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner)

        let context = assembly.sessionLifecycleDependencies.sessionStartContext()

        XCTAssertTrue(host.sessionStartBackends.first.flatMap { $0 } === owner)
        XCTAssertTrue(context.stateMachine() === host.machine)
        XCTAssertTrue(assembly.sessionLifecycleDependencies.automaticSessionTracking())
        XCTAssertEqual(assembly.sessionLifecycleDependencies.currentUserID(), 1)
        XCTAssertEqual(assembly.sessionLifecycleDependencies.deviceInfo(1), host.deviceInfoValue)
        XCTAssertEqual(assembly.sessionLifecycleDependencies.applicationInfo(), host.applicationInfoValue)
    }

    func testLifecycleCallbacksReachTheOwnerAndTheHost() {
        let owner = MPBackendFakeOwner(host: host)
        host.maxAge = 30
        host.isDevelopment = true
        let assembly = makeAssembly(owner: owner)
        let lifecycle = assembly.lifecycleCoordinator

        lifecycle.lifecycle.requestConfig()
        lifecycle.lifecycle.clearIdentityCache()

        XCTAssertEqual(owner.calls, ["requestConfig"])
        XCTAssertEqual(lifecycle.lifecycle.persistenceMaxAge(), 30)
        XCTAssertTrue(host.calls.contains("clearExpiredIdentityCache"))
        XCTAssertTrue(lifecycle.scheduling.isDevelopment())
    }

    func testUserAttributesReadOptOutAndAttributeLimitsFromTheHost() {
        let owner = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner)

        host.isOptedOut = true
        let refused = assembly.userAttributeWriter.setUserAttribute("Height", value: "183cm", timestamp: nil)
        host.isOptedOut = false
        _ = assembly.userAttributeWriter.setUserAttribute("Height", value: "183cm", timestamp: nil)

        XCTAssertEqual(refused.status, .optOut)
        XCTAssertTrue(host.calls.contains("optOut"))
        XCTAssertTrue(host.calls.contains("attributeKeyLengthLimit"))
        XCTAssertTrue(host.calls.contains("attributeValueLengthLimit"))
    }

    func testCrashReportsReadTheTruncationLimitFromTheHost() {
        let owner = MPBackendFakeOwner(host: host)
        let assembly = makeAssembly(owner: owner)

        _ = assembly.errorReporter.logCrash(message: "crash", stackTrace: nil, plCrashReport: "report")

        XCTAssertTrue(host.calls.contains("crashMaxPLReportLength"))
    }
}
