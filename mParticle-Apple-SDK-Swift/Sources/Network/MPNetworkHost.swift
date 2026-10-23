import Foundation

/// The SDK instance as the network layer sees it: what `MPBackendHost` already provides, plus the
/// values the network layer reads from `MParticle.sharedInstance`, `MPNetworkOptions`,
/// `MPUploadSettings`, the kit container and the SDK instance's persistence adapter, which this
/// module cannot reach on its own.
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
    /// The secret an event or alias upload is signed with, from the upload's own `MPUploadSettings`.
    @objc(secretOfUploadSettings:) func secret(ofUploadSettings uploadSettings: NSObject) -> String?
    /// The app version the config request reports.
    @objc(applicationVersion) func applicationVersion() -> String?
    /// The SDK's log level, for a logger to fall back on when the shared one is not set yet.
    @objc(logLevel) func logLevel() -> UInt
    /// The web view's user agent, which audience and event requests send. Read in Objective-C, so a
    /// test's mock web view answers.
    @objc(userAgent) func userAgent() -> String?
    /// The SDK's own user agent, which config requests send.
    @objc(originalDefaultUserAgent) func originalDefaultUserAgent() -> String?
    /// Read in Objective-C, so a test's class mock of the state machine answers.
    @objc(isAppExtension) func isAppExtension() -> Bool
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
    /// What a config response is applied to the SDK through.
    @objc(userDefaultsConnector) func userDefaultsConnector() -> MPUserDefaultsConnectorProtocol
    /// The error a failed identity request completes with: in the identity error domain, with the
    /// code of the `MPIdentityHTTPErrorResponse` it holds under `mParticleIdentityErrorKey`, made
    /// here from `code`, `message` and the transport error.
    @objc(identityErrorWithCode:message:underlyingError:)
    func identityError(code: Int, message: String, underlyingError: NSError?) -> NSError
    /// The same, with the `MPIdentityHTTPErrorResponse` made from a refused request's body and
    /// status code.
    @objc(identityErrorWithResponseObject:httpCode:)
    func identityError(responseObject: NSDictionary?, httpCode: Int) -> NSError
}
