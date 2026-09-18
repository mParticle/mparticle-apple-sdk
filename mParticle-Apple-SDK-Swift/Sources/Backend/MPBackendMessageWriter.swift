import Foundation

/// Persists messages in the same order as the backend and queues upload triggers afterward.
@objc(MPBackendMessageWriter)
public final class MPBackendMessageWriter: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies

    @objc public init(state: MPBackendSessionState, dependencies: MPBackendSessionDependencies) {
        self.state = state
        self.dependencies = dependencies
        super.init()
    }

    @objc(saveMessage:updateSession:)
    public func saveMessage(_ message: MPMessagePRIVATE?, updateSession: Bool) {
        let timestamp = message?.timestamp ?? 0
        let lastEventTimestamp = timestamp != 0 ? timestamp : dependencies.now()
        if dependencies.runningInBackground() {
            state.timeOfLastEventInBackground = lastEventTimestamp
        }
        let persistence = dependencies.persistence()
        guard let message else { return }
        let messageType = MPMessageBuilderPRIVATE.messageType(
            forString: message.messageType ?? "", logger: dependencies.logger()
        )
        if dependencies.stateMachine().optOut, messageType != MPMessageTypeSwift.optOut.rawValue { return }

        persistence?.objectiveCSaveMessage(message)
        if messageType == MPMessageTypeSwift.breadcrumb.rawValue {
            persistence?.objectiveCSaveBreadcrumb(message)
        }
        dependencies.logger()?.verbose("Source Event Id: \(message.uuid ?? "(null)")")
        if updateSession, let session = state.session {
            session.endTime = lastEventTimestamp
            if session.persisted {
                persistence?.objectiveCUpdateSession(session)
            } else {
                persistence?.objectiveCSaveSession(session)
            }
        }

        let stateMachine = dependencies.stateMachine()
        let hasher = MPIHasher(logger: dependencies.logger() ?? MPLog(logLevel: .none))
        if MPBackendMessageInfo.shouldUploadMessage(
            ofType: message.messageType,
            messageDictionary: message.dictionaryRepresentation() as? [AnyHashable: Any],
            triggerMessageTypes: stateMachine.triggerMessageTypes as? [AnyHashable],
            triggerEventTypes: stateMachine.triggerEventTypes as? [AnyHashable],
            hasher: hasher
        ) {
            dependencies.enqueueOnMessage { [dependencies] in dependencies.upload(nil) }
        }
    }

    @objc(confirmEndSessionMessage:)
    public func confirmEndSessionMessage(_ session: MPSessionPRIVATE?) {
        guard let session else { return }
        let persistence = dependencies.persistence()
        guard persistence?.objectiveCFetchSessionEndMessage(in: session) == nil else { return }
        var info: [AnyHashable: Any] = [
            kMPSessionLengthKey: MPMilliseconds(timestamp: session.foregroundTime),
            kMPSessionTotalLengthKey: MPMilliseconds(timestamp: session.length),
            kMPEventCounterKey: session.eventCounter
        ]
        info[MessageKeys.kMPAttributesKey] = AttributeValueTransformer.transformedAttributeValues(
            in: session.attributesDictionary, logger: dependencies.logger()
        )
        let builder = MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.sessionEnd.rawValue, session: session,
            messageInfo: info, context: dependencies.makeMessageContext()
        )
        builder?.updateTimestamp(session.endTime)
        saveMessage(builder?.build(), updateSession: false)
        dependencies.logger()?.verbose("Session Ended: \(session.uuid)")
    }
}

// Wire keys mirrored from MPIConstants.m across the internal module boundary.
private let kMPSessionLengthKey = "sl"
private let kMPSessionTotalLengthKey = "slx"
private let kMPEventCounterKey = "en"
