import Foundation
import XCTest
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
        stateMachine: { [unowned self] in replacementStateMachine ?? machine },
        makeMessageContext: { [unowned self] in
            contextReads += 1
            return MPMessageBuilderContext(dataPlanId: nil, dataPlanVersion: nil, logger: nil)
        },
        runningInBackground: { [unowned self] in background },
        enqueueOnMessage: { [unowned self] action in persistence.calls.append("enqueue"); enqueued.append(action) },
        upload: { [unowned self] completion in uploads += 1; persistence.calls.append("upload"); completion?() },
        logger: { nil }
    )
    lazy var writer = MPBackendMessageWriter(state: state, dependencies: dependencies)
    var automaticTracking = true
    var replacementStateMachine: MPStateMachinePRIVATE?
    var onAutomaticSessionTrackingRead: (() -> Void)?
    var userID: NSNumber = 1
    var isMessageQueue = true
    var scheduled: [(TimeInterval, () -> Void)] = []
    var pendingUUID: String?
    var pendingStartTime: Double?
    var began: [MPSessionPRIVATE] = []
    var ended: [MPSessionPRIVATE] = []
    var applicationReads = 0
    var deviceReads = 0
    var clearPending: (() -> Void)?
    var onBegin: ((MPSessionPRIVATE) -> Void)?
    var onEnd: ((MPSessionPRIVATE) -> Void)?
    lazy var lifecycle = MPBackendSessionLifecycleDependencies(
        automaticSessionTracking: { [unowned self] in automaticSessionTrackingValue() },
        sessionStartContext: { [unowned self] in
            let selectedMachine = replacementStateMachine ?? machine
            return MPBackendSessionStartContext(
                automaticSessionTracking: { [unowned self] in automaticSessionTrackingValue() },
                stateMachine: { selectedMachine }
            )
        },
        currentUserID: { [unowned self] in userID },
        applicationInfo: { [unowned self] in applicationReads += 1; return ["app": "info"] },
        deviceInfo: { [unowned self] _ in deviceReads += 1; return ["device": "info"] },
        executeOnMessage: { [unowned self] action in
            if isMessageQueue { action() } else { enqueued.append(action) }
        },
        schedule: { [unowned self] delay, action in scheduled.append((delay, action)) },
        createPendingSession: { [unowned self] uuid in pendingUUID = uuid },
        setPendingSessionStartTime: { [unowned self] time in pendingStartTime = time },
        clearPendingSession: { [unowned self] in clearPending?(); pendingUUID = nil; pendingStartTime = nil },
        broadcastBegin: { [unowned self] session in began.append(session); onBegin?(session) },
        broadcastEnd: { [unowned self] session in
            persistence.calls.append("broadcastEnd"); ended.append(session); onEnd?(session)
        },
        clearEmptyTimedEvents: { [unowned self] in persistence.calls.append("clearEvents") }
    )
    lazy var coordinator = MPBackendSessionCoordinator(
        state: state, dependencies: dependencies, lifecycle: lifecycle, writer: writer
    )

    func automaticSessionTrackingValue() -> Bool {
        let value = automaticTracking
        onAutomaticSessionTrackingRead?()
        return value
    }

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
    var sessions: [MPSessionPRIVATE] = []
    var previousSession: MPSessionPRIVATE?
    var archived: [MPSessionPRIVATE] = []
    var onSaveMessage: (() -> Void)?

    func objectiveCSaveMessage(_ message: MPMessagePRIVATE) {
        calls.append("message")
        savedMessages.append(message)
        onSaveMessage?()
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
    func objectiveCFetchSessions() -> NSMutableArray? { calls.append("fetchSessions"); return NSMutableArray(array: sessions) }
    func objectiveCFetchPossibleSessionsFromCrash() -> NSArray? { nil }
    func objectiveCArchiveSession(_ session: MPSessionPRIVATE) -> MPSessionPRIVATE? {
        calls.append("archive")
        archived.append(session)
        return session
    }
    func objectiveCFetchPreviousSession() -> MPSessionPRIVATE? { calls.append("previous"); return previousSession }
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

// Exercise workflows on a message queue, including the builder's off-main presentation context.
class MPBackendWorkflowTestCase: XCTestCase {
    func onMessageQueue(_ action: @escaping () throws -> Void) {
        let completed = expectation(description: "message queue workflow")
        DispatchQueue(label: "com.mparticle.tests.backend-workflow").async {
            do { try action() } catch { XCTFail("Workflow failed: \(error)") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 10)
    }
}
