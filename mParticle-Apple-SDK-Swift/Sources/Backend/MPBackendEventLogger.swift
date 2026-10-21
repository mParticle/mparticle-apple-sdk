import Foundation

/// Saves the messages of logged events, screens and breadcrumbs from what the Objective-C caller
/// read off the event, and counts each against the current session.
@objc(MPBackendEventLogger)
public final class MPBackendEventLogger: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let host: MPBackendHost
    private let sessions: MPBackendSessionCoordinator
    private weak var owner: MPBackendAssemblyOwner?

    init(
        state: MPBackendSessionState,
        dependencies: MPBackendSessionDependencies,
        host: MPBackendHost,
        sessions: MPBackendSessionCoordinator,
        owner: MPBackendAssemblyOwner
    ) {
        self.state = state
        self.dependencies = dependencies
        self.host = host
        self.sessions = sessions
        self.owner = owner
        super.init()
    }

    /// Begins a session for an event that asks for one, at `date` or now. The session is manual when
    /// the app does not track sessions automatically.
    @objc(beginSessionForEventAtDate:)
    public func beginSession(forEventAt date: Date?) {
        sessions.beginSession(isManual: !host.automaticSessionTracking(), date: date ?? Date())
    }

    /// Saves the message of `messageType` built from `messageInfo`, stamped with `timestamp` when
    /// there is one, and counts it against the current session.
    @objc(saveEventMessageOfType:messageInfo:timestamp:shouldUploadEvent:)
    public func saveEventMessage(
        ofType messageType: UInt,
        messageInfo: [AnyHashable: Any]?,
        timestamp: Date?,
        shouldUploadEvent: Bool
    ) {
        let builder = MPMessageBuilderPRIVATE(
            messageType: messageType,
            session: state.session,
            messageInfo: messageInfo,
            context: dependencies.makeMessageContext()
        )
        if let timestamp {
            builder?.updateTimestamp(timestamp.timeIntervalSince1970)
        }
        if let message = builder?.build() {
            message.shouldUploadEvent = shouldUploadEvent
            owner?.saveMessage(message, updateSession: true)
        }
        state.session?.incrementCounter()
    }
}
