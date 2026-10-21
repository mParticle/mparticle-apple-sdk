import Foundation
@testable import mParticle_Apple_SDK_Swift

/// A backend controller stand-in that records each call the assembly's collaborators make on it.
final class MPBackendFakeOwner: NSObject, MPBackendAssemblyOwner {
    var persistenceValue: MPBackendPersistence?
    let messageContext = MPMessageBuilderContext(dataPlanId: "owner-plan", dataPlanVersion: 1, logger: nil)
    let uploadContext: MPUploadBuilderContext
    var network: MPBackendUploadNetworking?
    var attributionSession = URLSession(configuration: .ephemeral)
    let delegate = MPBackendFakeDelegate()
    private(set) var preparedUploadSettings: [NSObject?] = []
    private(set) var savedMessages: [(message: MPMessagePRIVATE, updateSession: Bool)] = []
    var onSave: ((MPMessagePRIVATE) -> Void)?
    private(set) var calls: [String] = []

    init(host: MPBackendHost) {
        uploadContext = MPUploadBuilderContext(host: host, persistence: { MPUploadEnrichmentMock() })
        super.init()
    }

    func persistence() -> MPBackendPersistence? {
        persistenceValue
    }

    func messageBuilderContext() -> MPMessageBuilderContext {
        messageContext
    }

    func uploadBuilderContext() -> MPUploadBuilderContext {
        uploadContext
    }

    func upload(completionHandler: (() -> Void)?) {
        calls.append("upload")
        completionHandler?()
    }

    func requestConfig() {
        calls.append("requestConfig")
    }

    func uploadNetworking() -> MPBackendUploadNetworking? {
        network
    }

    func createPendingSession(uuid: String) {
        calls.append("createPendingSession:\(uuid)")
    }

    func setPendingSessionStartTime(_ timestamp: Double) {
        calls.append("setPendingSessionStartTime:\(timestamp)")
    }

    func clearPendingSession() {
        calls.append("clearPendingSession")
    }

    func backendDelegate() -> MPBackendControllerDelegate? {
        delegate
    }

    func setPersistence(_ persistence: MPBackendPersistence?) {
        calls.append("setPersistence")
        persistenceValue = persistence
    }

    func prepareBatches(forUploadSettings settings: NSObject?) {
        calls.append("prepareBatches")
        preparedUploadSettings.append(settings)
    }

    func clearEmptyTimedEvents() {
        calls.append("clearEmptyTimedEvents")
    }

    func attributionURLSession() -> URLSession {
        calls.append("attributionURLSession")
        return attributionSession
    }

    func saveMessage(_ message: MPMessagePRIVATE, updateSession: Bool) {
        savedMessages.append((message, updateSession))
        onSave?(message)
    }
}

/// A backend delegate that records what it is told, and whether on the main thread.
final class MPBackendFakeDelegate: NSObject, MPBackendControllerDelegate {
    private(set) var calls: [String] = []
    private(set) var callsOnMainThread: [Bool] = []

    func forwardLogInstall() { record("forwardLogInstall") }
    func forwardLogUpdate() { record("forwardLogUpdate") }
    func sessionDidBegin(_ session: MPSessionPRIVATE) { record("sessionDidBegin") }
    func sessionDidEnd(_ session: MPSessionPRIVATE) { record("sessionDidEnd") }

    private func record(_ call: String) {
        calls.append(call)
        callsOnMainThread.append(Thread.isMainThread)
    }
}
