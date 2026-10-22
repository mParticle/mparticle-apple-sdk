import Foundation

/// The SDK instance as the network layer sees it: what `MPBackendHost` already provides, plus the
/// values the network layer reads from `MParticle.sharedInstance`, `MPNetworkOptions`,
/// `MPUploadSettings`, the kit container and the persistence adapter, none of which this module
/// can import.
///
/// The Objective-C module supplies the conformance and reads the SDK instance on every call, so a
/// request sees the SDK as it is when the request is built, and a test's stubs on those reads apply.
@objc(MPNetworkHost)
public protocol MPNetworkHost: MPBackendHost, MPUploadPersisting, MPKitBatchLogging {
    /// Routing for the config, audience, identity and modify endpoints, from the current
    /// `MPNetworkOptions`.
    @objc(networkRoutingWithAttAuthorized:) func networkRouting(attAuthorized: Bool) -> MPEndpointRouting
    /// Routing for the event and alias endpoints, from an upload's own `MPUploadSettings`. Only the
    /// custom base URL still comes from the current `MPNetworkOptions`.
    @objc(routingForUploadSettings:attAuthorized:)
    func routing(forUploadSettings uploadSettings: NSObject, attAuthorized: Bool) -> MPEndpointRouting
    /// The app version the config request reports.
    @objc(applicationVersion) func applicationVersion() -> String?
    /// The SDK's log level, for a logger to fall back on when the shared one is not set yet.
    @objc(logLevel) func logLevel() -> UInt
    @objc(webView) func webView() -> MParticleWebViewPRIVATE?
    @objc(supportedKits) func supportedKits() -> [NSNumber]?
    @objc(configuredKits) func configuredKits() -> [NSNumber]?
    /// The pinning inputs from the current `MPNetworkOptions`.
    @objc(customCertificates) func customCertificates() -> [Data]
    @objc(pinningDisabled) func pinningDisabled() -> Bool
    @objc(pinningDisabledInDevelopment) func pinningDisabledInDevelopment() -> Bool
    @objc(executeOnMainSync:) func executeOnMainSync(_ block: @escaping () -> Void)
    /// Merges the consumer information in an upload response into the state machine and the
    /// persisted copy.
    @objc(mergeConsumerInfoFromResponse:) func mergeConsumerInfo(fromResponse response: NSDictionary)
}
