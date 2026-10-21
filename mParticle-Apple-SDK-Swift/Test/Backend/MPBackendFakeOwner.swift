import Foundation
@testable import mParticle_Apple_SDK_Swift

/// A backend controller stand-in that records each call the assembly's collaborators make on it.
final class MPBackendFakeOwner: NSObject, MPBackendAssemblyOwner {
    var persistenceValue: MPBackendPersistence?
    let messageContext = MPMessageBuilderContext(dataPlanId: "owner-plan", dataPlanVersion: 1, logger: nil)
    let uploadContext: MPUploadBuilderContext
    var network: MPBackendUploadNetworking?
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

    func broadcastSessionDidBegin(_ session: MPSessionPRIVATE) {
        calls.append("broadcastSessionDidBegin")
    }

    func broadcastSessionDidEnd(_ session: MPSessionPRIVATE) {
        calls.append("broadcastSessionDidEnd")
    }

    func clearEmptyTimedEvents() {
        calls.append("clearEmptyTimedEvents")
    }
}
