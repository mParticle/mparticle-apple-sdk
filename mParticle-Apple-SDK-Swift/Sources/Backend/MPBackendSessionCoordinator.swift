import Foundation

/// Keeps one SDK instance selected for a session start while its state machine stays live.
@objc(MPBackendSessionStartContext)
public final class MPBackendSessionStartContext: NSObject {
    let automaticSessionTracking: () -> Bool
    let stateMachine: () -> MPStateMachinePRIVATE

    @objc public init(automaticSessionTracking: @escaping () -> Bool, stateMachine: @escaping () -> MPStateMachinePRIVATE) {
        self.automaticSessionTracking = automaticSessionTracking
        self.stateMachine = stateMachine
        super.init()
    }
}

/// Public session facades and SDK-specific metadata stay at the Objective-C boundary.
@objc(MPBackendSessionLifecycleDependencies)
public final class MPBackendSessionLifecycleDependencies: NSObject {
    let automaticSessionTracking: () -> Bool
    let sessionStartContext: () -> MPBackendSessionStartContext
    let currentUserID: () -> NSNumber
    let applicationInfo: () -> NSDictionary?
    let deviceInfo: (NSNumber) -> NSDictionary?
    let executeOnMessage: (@escaping () -> Void) -> Void
    let schedule: (TimeInterval, @escaping () -> Void) -> Void
    let createPendingSession: (String) -> Void
    let setPendingSessionStartTime: (Double) -> Void
    let clearPendingSession: () -> Void
    let broadcastBegin: (MPSessionPRIVATE) -> Void
    let broadcastEnd: (MPSessionPRIVATE) -> Void
    let clearEmptyTimedEvents: () -> Void

    @objc public init(
        automaticSessionTracking: @escaping () -> Bool,
        sessionStartContext: @escaping () -> MPBackendSessionStartContext,
        currentUserID: @escaping () -> NSNumber,
        applicationInfo: @escaping () -> NSDictionary?,
        deviceInfo: @escaping (NSNumber) -> NSDictionary?,
        executeOnMessage: @escaping (@escaping () -> Void) -> Void,
        schedule: @escaping (TimeInterval, @escaping () -> Void) -> Void,
        createPendingSession: @escaping (String) -> Void,
        setPendingSessionStartTime: @escaping (Double) -> Void,
        clearPendingSession: @escaping () -> Void,
        broadcastBegin: @escaping (MPSessionPRIVATE) -> Void,
        broadcastEnd: @escaping (MPSessionPRIVATE) -> Void,
        clearEmptyTimedEvents: @escaping () -> Void
    ) {
        self.automaticSessionTracking = automaticSessionTracking
        self.sessionStartContext = sessionStartContext
        self.currentUserID = currentUserID
        self.applicationInfo = applicationInfo
        self.deviceInfo = deviceInfo
        self.executeOnMessage = executeOnMessage
        self.schedule = schedule
        self.createPendingSession = createPendingSession
        self.setPendingSessionStartTime = setPendingSessionStartTime
        self.clearPendingSession = clearPendingSession
        self.broadcastBegin = broadcastBegin
        self.broadcastEnd = broadcastEnd
        self.clearEmptyTimedEvents = clearEmptyTimedEvents
        super.init()
    }
}

/// Owns session creation, completion, temporary adoption, and recovery on the SDK message queue.
@objc(MPBackendSessionCoordinator)
public final class MPBackendSessionCoordinator: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let lifecycle: MPBackendSessionLifecycleDependencies
    private let writer: MPBackendMessageWriter

    @objc public init(
        state: MPBackendSessionState, dependencies: MPBackendSessionDependencies,
        lifecycle: MPBackendSessionLifecycleDependencies, writer: MPBackendMessageWriter
    ) {
        self.state = state
        self.dependencies = dependencies
        self.lifecycle = lifecycle
        self.writer = writer
        super.init()
    }

    @objc public func createTempSession() {
        state.withSessionLock {
            guard state.session == nil, state.pendingSessionUUID == nil else { return }
            let uuid = UUID().uuidString
            state.pendingSessionUUID = uuid
            lifecycle.createPendingSession(uuid)
            let session = MPSessionPRIVATE(startTime: dependencies.now(), userId: lifecycle.currentUserID())
            session.uuid = uuid
            state.pendingSessionStartTime = session.startTime
            lifecycle.setPendingSessionStartTime(MPMilliseconds(timestamp: session.startTime))
            lifecycle.broadcastBegin(session)
            dependencies.logger()?.verbose("New Session Has Begun: \(uuid)")
        }
    }

    @objc public func beginSession() {
        let date = Date(timeIntervalSince1970: dependencies.now())
        lifecycle.executeOnMessage { [self] in beginSession(isManual: false, date: date) }
    }

    @objc public func endSession() {
        lifecycle.executeOnMessage { [self] in endSession(isManual: false) }
    }

    @objc(beginSessionWithIsManual:date:)
    public func beginSession(isManual: Bool, date: Date?) {
        let context = lifecycle.sessionStartContext()
        guard isManual || context.automaticSessionTracking() else { return }
        state.withSessionLock {
            let machine = context.stateMachine()
            guard state.session == nil, !machine.optOut else { return }
            let persistence = dependencies.persistence()
            let userID = lifecycle.currentUserID()
            let timestamp = date?.timeIntervalSince1970 ?? dependencies.now()
            state.session = MPSessionPRIVATE(startTime: timestamp, userId: userID, uuid: state.pendingSessionUUID)
            if state.session?.appInfo == nil { state.session?.appInfo = lifecycle.applicationInfo() }
            if state.session?.deviceInfo == nil { state.session?.deviceInfo = lifecycle.deviceInfo(userID) }
            if let session = state.session { persistence?.objectiveCSaveSession(session) }

            let previous = persistence?.objectiveCFetchPreviousSession()
            // Preserve NSInteger boxing; malformed or unrepresentable lengths use the absent-session value.
            let previousLength = previous.flatMap { Int(exactly: trunc($0.length)) } ?? 0
            var info: [AnyHashable: Any] = ["psl": previousLength]
            if let previous {
                info["pid"] = previous.uuid
                info["pss"] = MPMilliseconds(timestamp: previous.startTime)
            }
            let builder = MPMessageBuilderPRIVATE(
                messageType: MPMessageTypeSwift.sessionStart.rawValue, session: state.session,
                messageInfo: info, context: dependencies.makeMessageContext()
            )
            builder?.updateTimestamp(state.session?.startTime ?? 0)
            writer.saveMessage(builder?.build(), updateSession: true)
            machine.currentSession = state.session
            if state.pendingSessionUUID != nil {
                state.pendingSessionUUID = nil
                state.pendingSessionStartTime = nil
                lifecycle.clearPendingSession()
            } else if let session = state.session {
                lifecycle.broadcastBegin(session)
                dependencies.logger()?.verbose("New Session Has Begun: \(session.uuid)")
            }
        }
    }

    @objc(endSessionWithIsManual:)
    public func endSession(isManual: Bool) {
        guard isManual || lifecycle.automaticSessionTracking() else { return }
        state.withSessionLock {
            guard state.session != nil || state.pendingSessionUUID != nil,
                  !dependencies.stateMachine().optOut else { return }
            guard let current = state.session else {
                lifecycle.schedule(0.1) { [self] in endSession(isManual: isManual) }
                return
            }
            guard let ending = current.copy() as? MPSessionPRIVATE else { return }
            writer.confirmEndSessionMessage(ending)
            _ = dependencies.persistence()?.objectiveCArchiveSession(ending)
            lifecycle.broadcastEnd(ending)
            state.session = nil
            dependencies.stateMachine().currentSession = nil
            dependencies.logger()?.verbose("Session Ended: \(ending.uuid)")
        }
    }

    @objc(processOpenSessionsEndingCurrent:completionHandler:)
    public func processOpenSessions(endingCurrent: Bool, completionHandler: (() -> Void)?) {
        let persistence = dependencies.persistence()
        var sessions = (persistence?.objectiveCFetchSessions() as? [Any] ?? []).compactMap { $0 as? MPSessionPRIVATE }
        if endingCurrent {
            dependencies.logger()?.verbose("Session Ending: \(state.session?.uuid ?? "(null)")")
            state.session = nil
            dependencies.stateMachine().currentSession = nil
            lifecycle.clearEmptyTimedEvents()
        } else if let current = sessions.last(where: { $0.sessionId == (state.session?.sessionId ?? 0) }) {
            sessions.removeAll { $0.isEqual(current) }
        }
        sessions.forEach(lifecycle.broadcastEnd)
        uploadOpenSessions(sessions, completionHandler: completionHandler)
    }

    @objc(uploadOpenSessions:completionHandler:)
    public func uploadOpenSessions(_ sessions: [MPSessionPRIVATE]?, completionHandler: (() -> Void)?) {
        let complete = { [lifecycle] in lifecycle.executeOnMessage { completionHandler?() } }
        guard let sessions, !sessions.isEmpty else { complete(); return }
        for original in sessions {
            if let ending = original.copy() as? MPSessionPRIVATE { writer.confirmEndSessionMessage(ending) }
        }
        dependencies.upload(complete)
    }
}
