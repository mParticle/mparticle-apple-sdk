import Foundation
import UIKit

/// Makes the connectors the network layer sends requests with, in place of `MPConnector`. Tests set
/// one as `MPNetworkCommunicationPRIVATE.connectorFactory`.
@objc(MPConnectorFactoryProtocol)
protocol MPConnectorFactoryProtocol {
    @objc func createConnector() -> MPConnectorProtocol
}

/// The SDK's network layer. It holds the host it reads the SDK through, builds the endpoint URLs and
/// the connectors, and holds the background tasks and upload throttling the requests use; the
/// requests themselves are still sent by the Objective-C boundary category in
/// MPNetworkCommunication+ObjCBoundary.m, which also adopts `MPBackendUploadNetworking` for it.
///
/// Besides the initialiser, which the connector calls, every member Objective-C can see exists for
/// that category and its tests.
@objc(MPNetworkCommunication_PRIVATE)
public final class MPNetworkCommunicationPRIVATE: NSObject {
    /// The default-host subdomains. A tracking subdomain is used once the app has ATT authorisation.
    private enum Subdomain {
        static let event = "nativesdks"
        static let identity = "identity"
        static let eventTracking = "tracking-nativesdks"
        static let identityTracking = "tracking-identity"
    }

    private enum Constant {
        /// The scheme the connector requires of every request URL, the one MPEndpointURLFactory uses.
        static let secureScheme = "https"
        static let requestTimeout: TimeInterval = 10
        static let networkPerformanceMessageType = "npe"
    }

    /// Replaces `MPConnector` for every request while set.
    @objc static var connectorFactory: MPConnectorFactoryProtocol?

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

    // MARK: - Connector

    /// The SDK's log, or one at the SDK's log level while the shared one is not set yet.
    private var logger: MPLog {
        host.sdkLogger() ?? MPLog(logLevel: MPLog.from(rawValue: host.logLevel()))
    }

    /// The connector for one request: the test factory's while one is set, otherwise a new
    /// `MPConnector`. Dynamic, so a partial mock's stub also answers the calls made from Swift.
    @objc public dynamic func makeConnector() -> MPConnectorProtocol {
        if let factory = Self.connectorFactory {
            return factory.createConnector()
        }
        return MPConnector(configuration: connectorConfiguration)
    }

    @objc var connectorConfiguration: MPConnectorConfiguration {
        let logger = logger
        return MPConnectorConfiguration(
            customCertificates: host.customCertificates(),
            pinningDisabledInDevelopment: host.pinningDisabledInDevelopment(),
            pinningDisabled: host.pinningDisabled(),
            isDevelopmentEnvironment: host.isDevelopmentEnvironment(),
            secureScheme: Constant.secureScheme,
            requestTimeout: Constant.requestTimeout,
            logger: logger,
            requestContextProvider: { kind in self.requestContext(for: kind) }
        )
    }

    /// The SDK values a request of `kind` is built and signed with, read when the connector builds it.
    func requestContext(for kind: MPURLRequestKind) -> MPURLRequestContext {
        var apiKey: String?
        var fallbackSecret: String?
        var userAgent: String?
        var supportedKits: [NSNumber]?
        var configuredKits: [NSNumber]?
        var eTag: String?
        var hasStoredConfiguration = false
        var environment = 0

        if kind != .custom {
            // The state machine's secret is a non-optional string that starts empty, so "not set yet"
            // arrives as "" rather than nil. Signing needs it to stay nil in that case: an HMAC over
            // an empty key is not a meaningful signature, and MPURLRequestBuilder omits the
            // x-mp-signature header entirely when the secret is absent.
            let secret = host.stateMachine().secret
            fallbackSecret = secret.isEmpty ? nil : secret
        }

        switch kind {
        case .audience:
            apiKey = host.stateMachine().apiKey
            userAgent = host.userAgent()
        case .identity:
            apiKey = host.stateMachine().apiKey
        case .event:
            supportedKits = host.supportedKits()
            configuredKits = host.configuredKits()
            userAgent = host.userAgent()
        case .config:
            let userDefaults = host.userDefaults()
            eTag = userDefaults[Miscellaneous.kMPHTTPETagHeaderKey] as? String
            hasStoredConfiguration = userDefaults.getConfiguration() != nil
            supportedKits = host.supportedKits()
            userAgent = host.originalDefaultUserAgent()
            environment = Int(MPStateMachinePRIVATE.environment())
        case .custom:
            break
        }

        return MPURLRequestContext(
            apiKey: apiKey,
            fallbackSecret: fallbackSecret,
            userAgent: userAgent,
            supportedKits: supportedKits,
            configuredKits: configuredKits,
            eTag: eTag,
            hasStoredConfiguration: hasStoredConfiguration,
            environment: environment,
            requestTimeout: Constant.requestTimeout,
            networkPerformanceMessageType: Constant.networkPerformanceMessageType,
            logger: logger
        )
    }

    // MARK: - Background tasks

    /// Begins a background task, on the main thread, for a request to finish in. Answers `.invalid`
    /// in an app extension, which has no `UIApplication`. If the task expires, `handler` runs and the
    /// task ends.
    @objc(beginSafeBackgroundTaskWithExpirationHandler:)
    public func beginSafeBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        if host.isAppExtension() {
            return .invalid
        }
        var taskId = UIBackgroundTaskIdentifier.invalid
        host.executeOnMainSync {
            taskId = MPApplication_PRIVATE.sharedUIApplication()?.beginBackgroundTask {
                guard taskId != .invalid else { return }
                self.logger.debug("Background task expiration handler invoked")
                handler?()
                MPApplication_PRIVATE.sharedUIApplication()?.endBackgroundTask(taskId)
                taskId = .invalid
            } ?? .invalid
        }
        return taskId
    }

    /// Ends a task `beginSafeBackgroundTask(expirationHandler:)` began, on the main thread.
    @objc(endSafeBackgroundTask:)
    public func endSafeBackgroundTask(_ taskId: UIBackgroundTaskIdentifier) {
        guard taskId != .invalid else { return }
        host.executeOnMain {
            MPApplication_PRIVATE.sharedUIApplication()?.endBackgroundTask(taskId)
        }
    }

    // MARK: - Retries and caching

    @objc(isRetriableTransportError:)
    public func isRetriableTransportError(_ error: NSError?) -> Bool {
        MPTransportErrorDetector.isRetriableTransportError(error)
    }

    /// Holds back uploads of `uploadType` for `retryAfter` seconds, unless they are held back already.
    @objc(throttleWithRetryAfter:uploadType:)
    public func throttle(retryAfter: TimeInterval, uploadType: UInt) {
        let logger = host.sdkLogger()
        let now = Date()
        guard host.stateMachine().minUploadDate(forUploadType: uploadType).compare(now) == .orderedAscending else {
            return
        }
        host.stateMachine().setMinUploadDate(now.addingTimeInterval(retryAfter), uploadType: uploadType)
        switch uploadType {
        case 0: // MPUploadTypeMessage
            logger?.debug(String(format: "Throttling uploads for %.0f seconds", retryAfter))
        case 1: // MPUploadTypeAlias
            logger?.debug(String(format: "Throttling alias requests for %.0f seconds", retryAfter))
        default:
            break
        }
    }

    /// The `max-age` of a config response's Cache-Control header, capped at a day.
    @objc(maxAgeForCache:)
    public func maxAge(forCache cacheControl: String?) -> NSNumber? {
        MPConfigResponseParser.maxAge(
            fromCacheControl: cacheControl,
            maxExpirationAge: Miscellaneous.CONFIG_REQUESTS_MAX_EXPIRATION_AGE
        )
    }
}
