import Foundation
@testable import mParticle_Apple_SDK_Swift

final class MPBackendSessionFixture {
    let state = MPBackendSessionState()
    let defaults: MPUserDefaults
    let machine: MPStateMachinePRIVATE
    var persistence = MPBackendRecordingPersistence()
    var background = false
    var enqueued: [() -> Void] = []
    var uploads = 0
    var contextReads = 0
    lazy var dependencies = MPBackendSessionDependencies(
        persistence: { [unowned self] in persistence },
        stateMachine: { [unowned self] in machine },
        makeMessageContext: { [unowned self] in
            contextReads += 1
            return MPMessageBuilderContext(dataPlanId: nil, dataPlanVersion: nil, logger: nil)
        },
        runningInBackground: { [unowned self] in background },
        enqueueOnMessage: { [unowned self] action in persistence.calls.append("enqueue"); enqueued.append(action) },
        upload: { [unowned self] completion in uploads += 1; completion?() },
        logger: { nil }
    )
    lazy var writer = MPBackendMessageWriter(state: state, dependencies: dependencies)

    init() {
        let connector = MPUserDefaultsConnectorMock()
        defaults = MPUserDefaults(connector: connector)
        machine = MPStateMachinePRIVATE(
            userDefaults: defaults, connector: connector, messageQueue: .main,
            sdkVersion: "0.0.0", deploymentTarget: 0, buildSDK: 0
        )
        machine.optOut = false
        machine.triggerMessageTypes = nil
        machine.triggerEventTypes = nil
        dependencies.now = { 200 }
    }

    deinit { defaults.resetDefaults() }

    func session() -> MPSessionPRIVATE {
        let session = MPSessionPRIVATE(startTime: 100, userId: 1)
        state.session = session
        return session
    }

    func message(type: String = "e", timestamp: TimeInterval = 120) -> MPMessagePRIVATE {
        MPMessagePRIVATE(
            sessionId: nil, messageId: 0, uuid: "message", messageType: type,
            messageData: Data("{}".utf8), timestamp: timestamp, uploadStatus: 1,
            userId: 1, dataPlanId: nil, dataPlanVersion: nil
        )
    }
}

final class MPBackendRecordingPersistence: NSObject, MPBackendPersistence {
    var calls: [String] = []
    var savedMessages: [MPMessagePRIVATE] = []
    var savedSessions: [MPSessionPRIVATE] = []
    var existingEndMessage: MPMessagePRIVATE?

    func objectiveCSaveMessage(_ message: MPMessagePRIVATE) {
        calls.append("message")
        savedMessages.append(message)
    }
    func objectiveCSaveBreadcrumb(_: MPMessagePRIVATE) { calls.append("breadcrumb") }
    func objectiveCSaveSession(_ session: MPSessionPRIVATE) {
        calls.append("saveSession")
        session.sessionId = 42
        savedSessions.append(session)
    }
    func objectiveCUpdateSession(_ session: MPSessionPRIVATE) {
        calls.append("updateSession")
        savedSessions.append(session)
    }
    func objectiveCFetchSessionEndMessage(in _: MPSessionPRIVATE) -> MPMessagePRIVATE? {
        calls.append("fetchEnd")
        return existingEndMessage
    }
    func objectiveCDatabaseOpen() -> Bool { true }
    func objectiveCOpenDatabase() -> Bool { true }
    func objectiveCCloseDatabase() -> Bool { true }
    func objectiveCPurgeMemory() {}
    func objectiveCDeleteRecords(olderThan _: TimeInterval) {}
    func objectiveCFetchSessions() -> NSMutableArray? { nil }
    func objectiveCFetchPossibleSessionsFromCrash() -> NSArray? { nil }
    func objectiveCArchiveSession(_: MPSessionPRIVATE) -> MPSessionPRIVATE? { nil }
    func objectiveCFetchPreviousSession() -> MPSessionPRIVATE? { nil }
    func objectiveCDeletePreviousSession() {}
    func objectiveCDeleteSession(_: MPSessionPRIVATE) {}
    func objectiveCDeleteAllSessions(except _: MPSessionPRIVATE?) {}
    func objectiveCAppAndDeviceInfo(forSessionId _: NSNumber) -> NSDictionary { [:] }
    func objectiveCDeleteMessages(_: [MPMessagePRIVATE]) {}
    func objectiveCDeleteNetworkPerformanceMessages() {}
    func objectiveCFetchMessagesForUploading() -> NSMutableDictionary? { nil }
    func objectiveCFetchUploadedMessages(in _: MPSessionPRIVATE) -> NSArray? { nil }
    func objectiveCFetchBreadcrumbs() -> NSArray? { nil }
    func objectiveCSaveUpload(_: MPUploadPRIVATE, optedOut _: Bool) {}
    func objectiveCFetchUploads() -> NSArray? { nil }
    func objectiveCDeleteUpload(_: MPUploadPRIVATE) {}
    func objectiveCDeleteUpload(id _: Int64) {}
    func objectiveCSaveUploads(_: [MPUploadPRIVATE], deleteMessages _: [MPMessagePRIVATE], optedOut _: Bool) -> Bool { true }
    func objectiveCFetchForwardRecords() -> NSArray? { nil }
    func objectiveCDeleteForwardRecords(ids _: [NSNumber]) {}
    func objectiveCFetchIntegrationAttributes() -> NSArray? { nil }
}
