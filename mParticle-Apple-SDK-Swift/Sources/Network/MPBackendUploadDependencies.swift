import Foundation

/// The backend's view of networking: configuration, uploads and audiences. Identity and endpoint
/// implementation stay behind it.
@objc public protocol MPBackendUploadNetworking {
    @objc(requestConfig:withCompletionHandler:)
    func requestConfig(_ connector: (NSObject & MPConnectorProtocol)?, completionHandler: @escaping (Bool) -> Void)
    @objc(upload:completionHandler:)
    func upload(_ uploads: [MPUploadPRIVATE], completionHandler: @escaping () -> Void)
    @objc(requestAudiencesWithCompletionHandler:)
    func requestAudiences(completionHandler: @escaping (Bool, [Any]?, Error?) -> Void)
}

/// Live networking and readiness dependencies. Scheduling always uses the SDK's message queue.
@objc(MPBackendUploadDependencies)
public final class MPBackendUploadDependencies: NSObject {
    @objc public let network: () -> MPBackendUploadNetworking?
    @objc public let shouldDelayForKits: () -> Bool
    @objc public let shouldDelayForWebView: () -> Bool
    @objc public let schedule: (TimeInterval, @escaping () -> Void) -> Void
    @objc public let logger: () -> MPLog?

    @objc public init(
        network: @escaping () -> MPBackendUploadNetworking?,
        shouldDelayForKits: @escaping () -> Bool,
        shouldDelayForWebView: @escaping () -> Bool,
        schedule: @escaping (TimeInterval, @escaping () -> Void) -> Void,
        logger: @escaping () -> MPLog?
    ) {
        self.network = network
        self.shouldDelayForKits = shouldDelayForKits
        self.shouldDelayForWebView = shouldDelayForWebView
        self.schedule = schedule
        self.logger = logger
        super.init()
    }
}
