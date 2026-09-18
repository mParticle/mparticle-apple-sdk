import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendSchedulingFixture {
    let persistence: MPBackendRecordingPersistence
    lazy var queue = MPBackendRecordingOperationQueue(persistence: persistence)
    var timers: [MPBackendRecordingTimer] = []
    var mainAccess = false
    var appState = 2
    var remaining: TimeInterval = 20
    var remainingReads = 0
    var extensionMode = false
    var development = true
    var expiration: (() -> Void)?
    var beforeMainSync: (() -> Void)?
    var onSleep: (() -> Void)?
    private weak var cachedDependencies: MPBackendLifecycleSchedulingDependencies?
    var dependencies: MPBackendLifecycleSchedulingDependencies {
        if let cachedDependencies { return cachedDependencies }
        let result = MPBackendLifecycleSchedulingDependencies(
            messageQueue: { .main },
            executeOnMain: { [self] action in mainAccess = true; action(); mainAccess = false },
            executeOnMainSync: { [self] action in
                mainAccess = true; beforeMainSync?(); action(); mainAccess = false
            },
            makeApplication: { [self] in
                MPBackendBackgroundApplication(
                    applicationState: { [self] in XCTAssertTrue(mainAccess); return appState },
                    timeRemaining: { [self] in
                        XCTAssertTrue(mainAccess); remainingReads += 1; return remaining
                    }
                )
            },
            beginBackgroundTask: { [self] handler in
                XCTAssertTrue(mainAccess); expiration = handler; persistence.calls.append("beginTask"); return 42
            },
            endBackgroundTask: { [self] identifier in
                XCTAssertTrue(mainAccess); XCTAssertEqual(identifier, 42); persistence.calls.append("endTask")
            },
            isAppExtension: { [self] in extensionMode },
            isDevelopment: { [self] in development },
            invalidBackgroundTask: UInt.max
        )
        result.makeTimer = { [self] interval, action in
            persistence.calls.append("beginTimer")
            let timer = MPBackendRecordingTimer(interval: interval, event: action, persistence: persistence)
            timers.append(timer)
            return timer
        }
        result.sleep = { [self] seconds in XCTAssertEqual(seconds, 1); onSleep?() }
        cachedDependencies = result
        return result
    }

    init(persistence: MPBackendRecordingPersistence) { self.persistence = persistence }

}

final class MPBackendRecordingOperationQueue: OperationQueue, @unchecked Sendable {
    let persistence: MPBackendRecordingPersistence
    var pending: [Operation] = []
    init(persistence: MPBackendRecordingPersistence) { self.persistence = persistence; super.init() }
    override func addOperation(_ operation: Operation) {
        persistence.calls.append("beginLoop"); pending.append(operation)
    }
    override func cancelAllOperations() {
        persistence.calls.append("cancelLoop"); pending.forEach { $0.cancel() }
    }
    func runNext() { pending.removeFirst().start() }
}

final class MPBackendRecordingTimer: MPBackendLifecycleTimer {
    let interval: TimeInterval
    let event: () -> Void
    let persistence: MPBackendRecordingPersistence
    var cancelled = false
    init(interval: TimeInterval, event: @escaping () -> Void, persistence: MPBackendRecordingPersistence) {
        self.interval = interval; self.event = event; self.persistence = persistence
    }
    func cancel() { cancelled = true; persistence.calls.append("cancelTimer") }
    func activateAndFire() { if !cancelled { event() } }
}

final class MPBackendLifecycleSchedulingTests: MPBackendWorkflowTestCase {
    func testNativeTimerWaitsForActivationAndCanCancelBeforeResume() throws {
        let queue = DispatchQueue(label: "com.mparticle.tests.timer")
        var activation: (() -> Void)?
        var calls = 0
        let fired = expectation(description: "resumed source fires")
        let timer = MPBackendDispatchTimer(interval: 60.9, queue: queue, event: {
            calls += 1
            fired.fulfill()
        }, scheduleActivation: { delay, action in
            XCTAssertEqual(delay, 60)
            activation = action
        })
        queue.sync { XCTAssertEqual(calls, 0) }
        try XCTUnwrap(activation)()
        wait(for: [fired], timeout: 2)
        timer.cancel()

        var cancelledActivation: (() -> Void)?
        var cancelled: MPBackendDispatchTimer? = MPBackendDispatchTimer(interval: 60, queue: queue, event: {
            XCTFail("A canceled suspended source must not fire after resume")
        }, scheduleActivation: { _, action in cancelledActivation = action })
        cancelled?.cancel()
        cancelled = nil
        try XCTUnwrap(cancelledActivation)()
        queue.sync {}
    }

    func testTimerReplacementBeforeActivationAndRepeatedCancellation() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.application.beginUploadTimer()
            let first = fixture.scheduling.timers[0]
            fixture.application.beginUploadTimer()
            first.activateAndFire()
            XCTAssertEqual(fixture.uploads, 0)
            fixture.scheduling.timers[1].activateAndFire()
            XCTAssertEqual(fixture.uploads, 1)
            fixture.application.endUploadTimer()
            fixture.application.endUploadTimer()
            fixture.scheduling.timers[1].activateAndFire()
            XCTAssertEqual(fixture.uploads, 1)
            XCTAssertTrue(fixture.scheduling.timers.allSatisfy(\.cancelled))
        }
    }

    func testUploadDefaultsClampingAndRestartOnlyForChangedActiveTimer() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            XCTAssertEqual(fixture.application.uploadInterval, 60)
            fixture.application.uploadInterval = 20
            XCTAssertTrue(fixture.scheduling.timers.isEmpty)
            fixture.application.beginUploadTimer()
            fixture.application.uploadInterval = 20
            XCTAssertEqual(fixture.scheduling.timers.count, 1)
            fixture.application.uploadInterval = 40
            XCTAssertEqual(fixture.scheduling.timers.count, 2)
            XCTAssertEqual(fixture.scheduling.timers.last?.interval, 40)
            fixture.application.uploadInterval = 1000
            #if os(tvOS)
                XCTAssertEqual(fixture.application.uploadInterval, 600)
            #else
                XCTAssertEqual(fixture.application.uploadInterval, 1000)
            #endif
            fixture.scheduling.extensionMode = true
            XCTAssertEqual(fixture.application.uploadInterval, 1)
            fixture.application.sessionTimeout = -1
            XCTAssertEqual(fixture.application.sessionTimeout, 1)
        }
    }

    func testProductionDefaultAndExtensionTaskGuards() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.scheduling.development = false
            XCTAssertEqual(fixture.application.uploadInterval, 600)
            fixture.scheduling.extensionMode = true
            fixture.application.beginBackgroundTask()
            fixture.application.endBackgroundTask()
            fixture.application.beginBackgroundTimeCheckLoop()
            XCTAssertTrue(fixture.persistence.calls.isEmpty)
        }
    }

    func testIntervalUpdateWaitsForTimerCreationAndReplacesOldInterval() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let owner = fixture.application
            let scheduling = fixture.scheduling.dependencies
            let makeTimer = scheduling.makeTimer
            let creating = DispatchSemaphore(value: 0)
            let finishCreation = DispatchSemaphore(value: 0)
            let updating = DispatchSemaphore(value: 0)
            let updated = DispatchSemaphore(value: 0)
            let group = DispatchGroup()
            scheduling.makeTimer = { interval, event in
                if interval == 60 {
                    creating.signal()
                    XCTAssertEqual(finishCreation.wait(timeout: .now() + 2), .success)
                }
                return makeTimer(interval, event)
            }
            DispatchQueue.global().async(group: group) { owner.beginUploadTimer() }
            XCTAssertEqual(creating.wait(timeout: .now() + 2), .success)
            DispatchQueue.global().async(group: group) {
                updating.signal()
                owner.uploadInterval = 40
                updated.signal()
            }
            XCTAssertEqual(updating.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(updated.wait(timeout: .now() + 0.1), .timedOut)
            finishCreation.signal()
            XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(fixture.scheduling.timers.map(\.interval), [60, 40])
            XCTAssertEqual(fixture.scheduling.timers.first?.cancelled, true)
            XCTAssertEqual(fixture.scheduling.timers.last?.cancelled, false)
            XCTAssertEqual(owner.uploadInterval, 40)
        }
    }

    func testStopWaitsForIntervalReplacementAndLaterUpdateDoesNotRestart() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let owner = fixture.application
            owner.beginUploadTimer()
            let scheduling = fixture.scheduling.dependencies
            let makeTimer = scheduling.makeTimer
            let replacing = DispatchSemaphore(value: 0)
            let finishReplacement = DispatchSemaphore(value: 0)
            let stopping = DispatchSemaphore(value: 0)
            let stopped = DispatchSemaphore(value: 0)
            let group = DispatchGroup()
            scheduling.makeTimer = { interval, event in
                replacing.signal()
                XCTAssertEqual(finishReplacement.wait(timeout: .now() + 2), .success)
                return makeTimer(interval, event)
            }
            DispatchQueue.global().async(group: group) { owner.uploadInterval = 40 }
            XCTAssertEqual(replacing.wait(timeout: .now() + 2), .success)
            DispatchQueue.global().async(group: group) {
                stopping.signal()
                owner.endUploadTimer()
                stopped.signal()
            }
            XCTAssertEqual(stopping.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(stopped.wait(timeout: .now() + 0.1), .timedOut)
            finishReplacement.signal()
            XCTAssertEqual(group.wait(timeout: .now() + 2), .success)
            XCTAssertNil(owner.uploadTimer)
            XCTAssertTrue(fixture.scheduling.timers.allSatisfy(\.cancelled))
            owner.uploadInterval = 20
            XCTAssertEqual(fixture.scheduling.timers.count, 2)
            XCTAssertNil(owner.uploadTimer)
        }
    }

    func testTimeoutUpdateWaitsForSessionTransitionAndClampsSynchronously() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let owner = fixture.application
            owner.sessionTimeout = 60
            let started = DispatchSemaphore(value: 0)
            let finished = DispatchSemaphore(value: 0)
            fixture.state.withSessionLock {
                DispatchQueue.global().async {
                    started.signal()
                    owner.sessionTimeout = -1
                    finished.signal()
                }
                XCTAssertEqual(started.wait(timeout: .now() + 2), .success)
                XCTAssertEqual(finished.wait(timeout: .now() + 0.1), .timedOut)
                XCTAssertEqual(fixture.state.sessionTimeout, 60)
            }
            XCTAssertEqual(finished.wait(timeout: .now() + 2), .success)
            XCTAssertEqual(owner.sessionTimeout, 1)
            XCTAssertEqual(fixture.state.sessionTimeout, 1)
        }
    }

    func testTimeoutReadSeesCompletedSessionTransition() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            let owner = fixture.application
            let started = DispatchSemaphore(value: 0)
            let finished = DispatchSemaphore(value: 0)
            fixture.state.withSessionLock {
                fixture.state.sessionTimeout = 20
                DispatchQueue.global().async {
                    started.signal()
                    XCTAssertEqual(owner.sessionTimeout, 40)
                    finished.signal()
                }
                XCTAssertEqual(started.wait(timeout: .now() + 2), .success)
                XCTAssertEqual(finished.wait(timeout: .now() + 0.1), .timedOut)
                fixture.state.sessionTimeout = 40
            }
            XCTAssertEqual(finished.wait(timeout: .now() + 2), .success)
        }
    }

    func testExpirationCancelsPollingBeforeEndingTaskAndEndIsIdempotent() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.application.beginBackgroundTask()
            fixture.application.beginBackgroundTask()
            fixture.application.beginBackgroundTimeCheckLoop()
            fixture.persistence.calls = []
            fixture.scheduling.expiration?()
            XCTAssertEqual(fixture.persistence.calls, ["cancelLoop", "endTask"])
            fixture.application.endBackgroundTask()
            XCTAssertEqual(fixture.persistence.calls, ["cancelLoop", "endTask"])
            XCTAssertEqual(fixture.application.backgroundTaskIdentifier, UInt.max)
            XCTAssertTrue(fixture.scheduling.queue.pending[0].isCancelled)
        }
    }

    func testCancellationInsideMainBoundarySkipsRemainingTimeRead() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.application.beginBackgroundTimeCheckLoop()
            let operation = fixture.scheduling.queue.pending[0]
            var accesses = 0
            fixture.scheduling.beforeMainSync = {
                accesses += 1
                if accesses == 2 { operation.cancel() }
            }
            fixture.scheduling.queue.runNext()
            XCTAssertEqual(accesses, 2)
            XCTAssertEqual(fixture.scheduling.remainingReads, 0)
            XCTAssertEqual(fixture.uploads, 0)
            fixture.scheduling.beforeMainSync = nil
        }
    }

    func testLowTimeUploadCompletesBeforeTimerAndTaskEnd() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.scheduling.remaining = 10
            fixture.application.beginBackgroundTask()
            fixture.application.beginUploadTimer()
            fixture.application.beginBackgroundTimeCheckLoop()
            fixture.isMessageQueue = false
            fixture.persistence.calls = []
            fixture.scheduling.queue.runNext()
            XCTAssertTrue(fixture.persistence.calls.isEmpty)
            fixture.drainMessageQueue()
            XCTAssertEqual(fixture.persistence.calls, ["upload", "cancelTimer", "endTask"])
        }
    }

    func testPollingUsesOneSecondDelayAndStopsAfterForeground() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            fixture.application.beginBackgroundTask()
            var sleeps = 0
            fixture.scheduling.onSleep = { [weak fixture] in sleeps += 1; fixture?.scheduling.appState = 0 }
            fixture.application.beginBackgroundTimeCheckLoop()
            fixture.scheduling.queue.runNext()
            XCTAssertEqual(sleeps, 1)
            XCTAssertEqual(fixture.scheduling.remainingReads, 1)
            XCTAssertEqual(fixture.persistence.calls.last, "endTask")
        }
    }

    func testTeardownCancelsTimerAndLoopAndOldCallbackCannotUpload() {
        onMessageQueue {
            let fixture = MPBackendSessionFixture()
            var owner: MPBackendLifecycleCoordinator? = MPBackendLifecycleCoordinator(
                state: fixture.state, dependencies: fixture.dependencies, sessionDependencies: fixture.lifecycle,
                lifecycle: fixture.lifecycleDependencies, sessions: fixture.coordinator, writer: fixture.writer,
                scheduling: fixture.scheduling.dependencies
            )
            owner?.backgroundTaskIdentifier = UInt.max
            owner?.backgroundCheckQueue = fixture.scheduling.queue
            owner?.beginBackgroundTask()
            owner?.beginUploadTimer()
            owner?.beginBackgroundTimeCheckLoop()
            weak var weakOwner = owner
            let oldTimer = fixture.scheduling.timers[0]
            owner = nil
            XCTAssertNil(weakOwner)
            XCTAssertTrue(oldTimer.cancelled)
            XCTAssertTrue(fixture.scheduling.queue.pending[0].isCancelled)
            XCTAssertEqual(fixture.persistence.calls.last, "endTask")
            oldTimer.event()
            XCTAssertEqual(fixture.uploads, 0)
        }
    }
}
