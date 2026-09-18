import Foundation

/// Application and scheduling capabilities used by lifecycle decisions.
@objc(MPBackendLifecycleDependencies)
public final class MPBackendLifecycleDependencies: NSObject {
    let sessionTimeout: () -> TimeInterval
    let persistenceMaxAge: () -> NSNumber?
    let setRunningInBackground: (Bool) -> Void
    let clearIdentityCache: () -> Void
    let requestConfig: () -> Void
    let beginBackgroundTask: () -> Void
    let endBackgroundTask: () -> Void
    let beginUploadTimer: () -> Void
    let beginBackgroundTimeCheckLoop: () -> Void
    let cancelBackgroundTimeCheckLoop: () -> Void

    @objc public init(
        sessionTimeout: @escaping () -> TimeInterval,
        persistenceMaxAge: @escaping () -> NSNumber?,
        setRunningInBackground: @escaping (Bool) -> Void,
        clearIdentityCache: @escaping () -> Void,
        requestConfig: @escaping () -> Void,
        beginBackgroundTask: @escaping () -> Void,
        endBackgroundTask: @escaping () -> Void,
        beginUploadTimer: @escaping () -> Void,
        beginBackgroundTimeCheckLoop: @escaping () -> Void,
        cancelBackgroundTimeCheckLoop: @escaping () -> Void
    ) {
        self.sessionTimeout = sessionTimeout
        self.persistenceMaxAge = persistenceMaxAge
        self.setRunningInBackground = setRunningInBackground
        self.clearIdentityCache = clearIdentityCache
        self.requestConfig = requestConfig
        self.beginBackgroundTask = beginBackgroundTask
        self.endBackgroundTask = endBackgroundTask
        self.beginUploadTimer = beginUploadTimer
        self.beginBackgroundTimeCheckLoop = beginBackgroundTimeCheckLoop
        self.cancelBackgroundTimeCheckLoop = cancelBackgroundTimeCheckLoop
        super.init()
    }
}

/// Session timing, application transitions, and persistence cleanup on the SDK message queue.
@objc(MPBackendLifecycleCoordinator)
public final class MPBackendLifecycleCoordinator: NSObject {
    let state: MPBackendSessionState
    let dependencies: MPBackendSessionDependencies
    let sessionDependencies: MPBackendSessionLifecycleDependencies
    let lifecycle: MPBackendLifecycleDependencies
    let sessions: MPBackendSessionCoordinator
    let writer: MPBackendMessageWriter

    @objc public init(
        state: MPBackendSessionState, dependencies: MPBackendSessionDependencies,
        sessionDependencies: MPBackendSessionLifecycleDependencies, lifecycle: MPBackendLifecycleDependencies,
        sessions: MPBackendSessionCoordinator, writer: MPBackendMessageWriter
    ) {
        self.state = state
        self.dependencies = dependencies
        self.sessionDependencies = sessionDependencies
        self.lifecycle = lifecycle
        self.sessions = sessions
        self.writer = writer
        super.init()
    }

    @objc public func updateSessionBackgroundTime() {
        guard state.session != nil, state.timeAppWentToBackgroundInCurrentSession != 0 else { return }
        let currentTime = dependencies.now()
        state.session?.backgroundTime += currentTime - state.timeAppWentToBackgroundInCurrentSession
    }

    @objc public func shouldEndSession() -> Bool {
        MPSessionTimingPolicy.shouldEndSession(
            now: dependencies.now(), lastEventInBackground: state.timeOfLastEventInBackground,
            sessionTimeout: lifecycle.sessionTimeout()
        )
    }

    @objc public func endSessionIfTimedOut() {
        guard sessionDependencies.automaticSessionTracking() else { return }
        sessionDependencies.executeOnMessage { [self] in
            guard state.session != nil, shouldEndSession() else { return }
            let currentTime = dependencies.now()
            state.session?.endTime = state.timeOfLastEventInBackground
            updateSessionBackgroundTime()
            // Background duration is measured to now, but this session ends at its last event.
            state.session?.backgroundTime -= currentTime - state.timeOfLastEventInBackground
            state.timeOfLastEventInBackground = currentTime
            state.timeAppWentToBackgroundInCurrentSession = currentTime
            if let session = state.session { dependencies.persistence()?.objectiveCUpdateSession(session) }
            sessions.processOpenSessions(endingCurrent: true) { [dependencies] in
                dependencies.logger()?.verbose(
                    "Session ended in the background. New session will begin if an mParticle event is logged "
                    + "or app enters foreground."
                )
            }
        }
    }

    @objc public func cleanUp() {
        cleanUp(currentTime: dependencies.now())
    }

    @objc(cleanUp:)
    public func cleanUp(currentTime: TimeInterval) {
        if let plan = MPSessionTimingPolicy.cleanUpPlan(
            now: currentTime, nextCleanUpTime: state.nextCleanUpTime,
            maxAgeSeconds: lifecycle.persistenceMaxAge(), defaultMaxAge: 60 * 60 * 24 * 90, interval: 86400
        ) {
            dependencies.persistence()?.objectiveCDeleteRecords(olderThan: plan.deleteRecordsOlderThan)
            state.nextCleanUpTime = plan.nextCleanUpTime
        }
        dependencies.persistence()?.objectiveCPurgeMemory()
        lifecycle.clearIdentityCache()
    }

    @objc public func applicationDidEnterBackground() {
        dependencies.logger()?.verbose("Application Did Enter Background")
        let currentTime = dependencies.now()
        lifecycle.setRunningInBackground(true)
        lifecycle.beginBackgroundTask()
        sessionDependencies.executeOnMessage { [self] in
            state.timeAppWentToBackground = currentTime
            state.timeAppWentToBackgroundInCurrentSession = currentTime
            state.timeOfLastEventInBackground = currentTime
            cleanUp()
            let builder = MPMessageBuilderPRIVATE(
                messageType: MPMessageTypeSwift.appStateTransition.rawValue, session: state.session,
                messageInfo: [MessageKeys.kMPAppStateTransitionType: "app_back"], context: dependencies.makeMessageContext()
            )
            let message = builder?.build()
            state.session?.suspendSession()
            writer.saveMessage(message, updateSession: true)
            lifecycle.beginBackgroundTimeCheckLoop()
        }
    }

    @objc public func applicationWillEnterForeground() {
        lifecycle.setRunningInBackground(false)
        lifecycle.cancelBackgroundTimeCheckLoop()
        lifecycle.endBackgroundTask()
        sessionDependencies.executeOnMessage { [self] in
            endSessionIfTimedOut()
            if state.timeAppWentToBackground == state.timeAppWentToBackgroundInCurrentSession {
                updateSessionBackgroundTime()
            }
            sessions.beginSession()
            lifecycle.requestConfig()
        }
    }

    @objc public func applicationDidBecomeActive() {
        guard !dependencies.stateMachine().optOut else { return }
        lifecycle.beginUploadTimer()
        sessionDependencies.executeOnMessage { [self] in
            state.timeAppWentToBackgroundInCurrentSession = 0
            state.timeOfLastEventInBackground = 0
            var isLaunch = true
            var info: [AnyHashable: Any] = [MessageKeys.kMPAppStateTransitionType: "app_fore"]
            if let previous = state.previousForegroundTime {
                info["pft"] = previous
                isLaunch = false
            }
            let builder = MPMessageBuilderPRIVATE(
                messageType: MPMessageTypeSwift.appStateTransition.rawValue, session: state.session,
                messageInfo: info, context: dependencies.makeMessageContext()
            )
            state.previousForegroundTime = NSNumber(value: MPMilliseconds(timestamp: dependencies.now()))
            builder?.stateTransition(isLaunch, previousSession: nil, launchInfo: dependencies.stateMachine().launchInfo)
            writer.saveMessage(builder?.build(), updateSession: true)
            dependencies.logger()?.verbose("Application Did Become Active")
        }
    }
}
