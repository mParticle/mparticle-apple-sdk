import Foundation

/// Timer cancellation exposed to deterministic lifecycle tests.
protocol MPBackendLifecycleTimer: AnyObject {
    func cancel()
}

/// Captures the application used for remaining-time reads while keeping application state live.
@objc(MPBackendBackgroundApplication)
public final class MPBackendBackgroundApplication: NSObject {
    let applicationState: () -> Int
    let timeRemaining: () -> TimeInterval

    @objc public init(applicationState: @escaping () -> Int, timeRemaining: @escaping () -> TimeInterval) {
        self.applicationState = applicationState
        self.timeRemaining = timeRemaining
        super.init()
    }
}

/// Framework operations supplied by the Objective-C composition boundary.
@objc(MPBackendLifecycleSchedulingDependencies)
public final class MPBackendLifecycleSchedulingDependencies: NSObject {
    let executeOnMain: (@escaping () -> Void) -> Void
    let executeOnMainSync: (@escaping () -> Void) -> Void
    let makeApplication: () -> MPBackendBackgroundApplication
    let beginBackgroundTask: (@escaping () -> Void) -> UInt
    let endBackgroundTask: (UInt) -> Void
    let isAppExtension: () -> Bool
    let isDevelopment: () -> Bool
    let invalidBackgroundTask: UInt
    var makeTimer: (TimeInterval, @escaping () -> Void) -> MPBackendLifecycleTimer
    var sleep: (TimeInterval) -> Void = { Thread.sleep(forTimeInterval: $0) }

    @objc public init(
        messageQueue: @escaping () -> DispatchQueue,
        executeOnMain: @escaping (@escaping () -> Void) -> Void,
        executeOnMainSync: @escaping (@escaping () -> Void) -> Void,
        makeApplication: @escaping () -> MPBackendBackgroundApplication,
        beginBackgroundTask: @escaping (@escaping () -> Void) -> UInt,
        endBackgroundTask: @escaping (UInt) -> Void,
        isAppExtension: @escaping () -> Bool,
        isDevelopment: @escaping () -> Bool,
        invalidBackgroundTask: UInt
    ) {
        self.executeOnMain = executeOnMain
        self.executeOnMainSync = executeOnMainSync
        self.makeApplication = makeApplication
        self.beginBackgroundTask = beginBackgroundTask
        self.endBackgroundTask = endBackgroundTask
        self.isAppExtension = isAppExtension
        self.isDevelopment = isDevelopment
        self.invalidBackgroundTask = invalidBackgroundTask
        makeTimer = { MPBackendDispatchTimer(interval: $0, queue: messageQueue(), event: $1) }
        super.init()
    }
}

/// The source remains suspended until the original first-upload delay, including after cancellation.
final class MPBackendDispatchTimer: MPBackendLifecycleTimer {
    private let source: DispatchSourceTimer

    init(
        interval: TimeInterval,
        queue: DispatchQueue,
        event: @escaping () -> Void,
        scheduleActivation: ((TimeInterval, @escaping () -> Void) -> Void)? = nil
    ) {
        source = DispatchSource.makeTimerSource(queue: queue)
        // The old timer accepted whole seconds. Bound invalid/oversized input before integer conversion.
        let maximum = Double(Int.max/1_000_000_000)
        let seconds = interval.isFinite ? min(max(interval.rounded(.towardZero), 1), maximum) : maximum
        let nanoseconds = Int(seconds) * 1_000_000_000
        source.schedule(wallDeadline: .now(), repeating: .nanoseconds(nanoseconds), leeway: .milliseconds(100))
        source.setEventHandler(handler: event)
        source.setCancelHandler {}
        let activate = { [source] in source.resume() }
        if let scheduleActivation {
            scheduleActivation(seconds, activate)
        } else {
            queue.asyncAfter(deadline: .now() + .nanoseconds(nanoseconds), execute: activate)
        }
    }

    func cancel() { source.cancel() }

    deinit { source.cancel() }
}

extension MPBackendLifecycleCoordinator {
    @objc public var sessionTimeout: TimeInterval {
        get { state.sessionTimeout }
        set {
            guard newValue != state.sessionTimeout else { return }
            state.sessionTimeout = MPSessionTimingPolicy.clampedSessionTimeout(newValue, minimum: 1)
            dependencies.logger()?.debug(String(format: "Set Session Timeout: %.0f", state.sessionTimeout))
        }
    }

    @objc public var uploadInterval: TimeInterval {
        get {
            if storedUploadInterval == 0 {
                storedUploadInterval = MPSessionTimingPolicy.defaultUploadInterval(
                    isDevelopment: scheduling.isDevelopment(), debugInterval: 60, productionInterval: 600
                )
            }
            if scheduling.isAppExtension() { storedUploadInterval = 1 }
            return storedUploadInterval
        }
        set {
            guard newValue != storedUploadInterval else { return }
            storedUploadInterval = MPSessionTimingPolicy.clampedUploadInterval(newValue, tvOSCeiling: 600)
            if uploadTimer != nil { beginUploadTimer() }
        }
    }

    @objc public func beginUploadTimer() {
        timerLock.lock()
        defer { timerLock.unlock() }
        uploadTimer?.cancel()
        uploadTimer = nil
        uploadTimer = scheduling.makeTimer(uploadInterval) { [weak self] in self?.dependencies.upload(nil) }
    }

    @objc public func endUploadTimer() {
        timerLock.lock()
        defer { timerLock.unlock() }
        uploadTimer?.cancel()
        uploadTimer = nil
    }

    @objc public func beginBackgroundTask() {
        guard !scheduling.isAppExtension() else { return }
        scheduling.executeOnMain { [weak self] in
            guard let self, backgroundTaskIdentifier == scheduling.invalidBackgroundTask else { return }
            backgroundTaskIdentifier = scheduling.beginBackgroundTask { [weak self] in
                guard let self else { return }
                dependencies.logger()?.debug("SDK has ended background activity together with the app.")
                cancelBackgroundTimeCheckLoop()
                endBackgroundTask()
            }
        }
    }

    @objc public func endBackgroundTask() {
        guard !scheduling.isAppExtension() else { return }
        scheduling.executeOnMain { [weak self] in
            guard let self, backgroundTaskIdentifier != scheduling.invalidBackgroundTask else { return }
            scheduling.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = scheduling.invalidBackgroundTask
        }
    }

    @objc public func cancelBackgroundTimeCheckLoop() {
        backgroundCheckQueue?.cancelAllOperations()
    }

    @objc public func beginBackgroundTimeCheckLoop() {
        guard !scheduling.isAppExtension() else { return }
        cancelBackgroundTimeCheckLoop()
        let operation = BlockOperation()
        let scheduling = scheduling
        operation.addExecutionBlock { [weak self, weak operation] in
            let application = scheduling.makeApplication()
            let readState = {
                var result = 0
                scheduling.executeOnMainSync { result = application.applicationState() }
                return result
            }
            var applicationState = readState()
            while applicationState == 2 { // UIApplicationStateBackground
                self?.endSessionIfTimedOut()
                var cancelled = false
                var timeRemaining: TimeInterval = 0
                // Serialize cancellation and remaining-time access with foreground/expiration on main.
                scheduling.executeOnMainSync {
                    guard let operation, !operation.isCancelled else { cancelled = true; return }
                    timeRemaining = application.timeRemaining()
                }
                if cancelled { return }
                if timeRemaining <= 10 {
                    self?.dependencies.logger()?.verbose(
                        "Less than 10.000000 time remaining in background, uploading batch and ending background task"
                    )
                    self?.sessionDependencies.executeOnMessage { [weak self] in
                        self?.dependencies.upload { [weak self] in
                            self?.endUploadTimer()
                            self?.endBackgroundTask()
                        }
                    }
                    return
                }
                self?.dependencies.logger()?.verbose(String(format: "Background time remaining %f", timeRemaining))
                scheduling.sleep(1)
                applicationState = readState()
            }
            self?.endBackgroundTask()
        }
        backgroundCheckQueue?.addOperation(operation)
    }
}
