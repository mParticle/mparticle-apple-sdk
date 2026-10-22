import Foundation

/// The SDK's network layer. It holds the host it reads the SDK through and builds the endpoint
/// URLs; the requests themselves are still sent by the Objective-C boundary category in
/// MPNetworkCommunication+ObjCBoundary.m, which also adopts `MPBackendUploadNetworking` for it.
///
/// Besides the initialiser, which the connector calls, every member Objective-C can see exists for
/// that category and its tests: the host, the identity-request flag and the URLs.
@objc(MPNetworkCommunication_PRIVATE)
public final class MPNetworkCommunicationPRIVATE: NSObject {
    /// The default-host subdomains. A tracking subdomain is used once the app has ATT authorisation.
    private enum Subdomain {
        static let event = "nativesdks"
        static let identity = "identity"
        static let eventTracking = "tracking-nativesdks"
        static let identityTracking = "tracking-identity"
    }

    @objc public let host: MPNetworkHost
    private let urlFactory: MPEndpointURLFactory
    private let identifyingLock = NSLock()
    private var identifyingValue = false
    private var memoizedConfigURL: MPURL?
    private var memoizedIdentifyURL: MPURL?
    private var memoizedLoginURL: MPURL?
    private var memoizedLogoutURL: MPURL?

    @objc(initWithHost:)
    public init(host: MPNetworkHost) {
        self.host = host
        urlFactory = MPEndpointURLFactory(logger: { host.sdkLogger() })
        super.init()
    }

    /// Whether an identity request that blocks the others is in flight. Read and written from any
    /// thread.
    @objc public var identifying: Bool {
        get {
            identifyingLock.lock()
            defer { identifyingLock.unlock() }
            return identifyingValue
        }
        set {
            identifyingLock.lock()
            identifyingValue = newValue
            identifyingLock.unlock()
        }
    }

    // MARK: - Hosts and routing

    private var attAuthorized: Bool {
        host.stateMachine().attAuthorizationStatus?.intValue == MPATTAuthorizationStatusSwift.authorized.rawValue
    }

    @objc var defaultEventHost: String {
        defaultHost(subdomain: attAuthorized ? Subdomain.eventTracking : Subdomain.event)
    }

    @objc var defaultIdentityHost: String {
        defaultHost(subdomain: attAuthorized ? Subdomain.identityTracking : Subdomain.identity)
    }

    private func defaultHost(subdomain: String) -> String {
        MPEndpointHostResolver.defaultHost(subdomain: subdomain, apiKey: host.stateMachine().apiKey)
    }

    private var networkRouting: MPEndpointRouting {
        host.networkRouting(attAuthorized: attAuthorized)
    }

    private func routing(for upload: MPUploadPRIVATE) -> MPEndpointRouting {
        host.routing(forUploadSettings: upload.uploadSettings, attAuthorized: attAuthorized)
    }

    // MARK: - Endpoint URLs

    // The config and identity URLs are kept once built. The audience and modify URLs are built on
    // every read, because they embed the current mpid: keeping them would pin them to whichever
    // user was current first.

    @objc public var configURL: MPURL? {
        if memoizedConfigURL == nil {
            let appVersion = host.applicationVersion()
            memoizedConfigURL = urlFactory.configURL(
                routing: networkRouting,
                appVersion: appVersion,
                sdkVersion: host.sdkVersion(),
                dataPlanId: host.dataPlanId(),
                dataPlanVersion: host.dataPlanVersion()
            )
        }
        return memoizedConfigURL
    }

    @objc public var audienceURL: MPURL? {
        urlFactory.audienceURL(routing: networkRouting, defaultEventHost: defaultEventHost, mpId: host.mpId())
    }

    @objc public var identifyURL: MPURL? {
        if memoizedIdentifyURL == nil {
            memoizedIdentifyURL = identityURL(pathComponent: "identify")
        }
        return memoizedIdentifyURL
    }

    @objc public var loginURL: MPURL? {
        if memoizedLoginURL == nil {
            memoizedLoginURL = identityURL(pathComponent: "login")
        }
        return memoizedLoginURL
    }

    @objc public var logoutURL: MPURL? {
        if memoizedLogoutURL == nil {
            memoizedLogoutURL = identityURL(pathComponent: "logout")
        }
        return memoizedLogoutURL
    }

    @objc public var modifyURL: MPURL? {
        urlFactory.modifyURL(routing: networkRouting, defaultIdentityHost: defaultIdentityHost, mpId: host.mpId())
    }

    private func identityURL(pathComponent: String) -> MPURL? {
        urlFactory.identityURL(routing: networkRouting, defaultIdentityHost: defaultIdentityHost, pathComponent: pathComponent)
    }

    /// The event URL for an upload, routed by the upload's own settings.
    @objc(eventURLForUpload:)
    public func eventURL(for upload: MPUploadPRIVATE) -> MPURL? {
        urlFactory.eventURL(routing: routing(for: upload), defaultEventHost: defaultEventHost)
    }

    /// The alias URL for an upload, routed by the upload's own settings.
    @objc(aliasURLForUpload:)
    public func aliasURL(for upload: MPUploadPRIVATE) -> MPURL? {
        urlFactory.aliasURL(routing: routing(for: upload), defaultEventHost: defaultEventHost)
    }
}
