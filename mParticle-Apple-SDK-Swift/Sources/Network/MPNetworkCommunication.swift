import Foundation
import UIKit

/// Makes the connectors the network layer sends requests with, in place of `MPConnector`. Tests set
/// one as `MPNetworkCommunicationPRIVATE.connectorFactory`.
@objc(MPConnectorFactoryProtocol)
protocol MPConnectorFactoryProtocol {
    @objc func createConnector() -> MPConnectorProtocol
}

/// The SDK's network layer. It holds the host it reads the SDK through, builds the endpoint URLs and
/// the connectors, holds the background tasks and upload throttling the requests use, and sends the
/// config and audience requests. The upload and identity requests are still sent by the
/// Objective-C boundary category in MPNetworkCommunication+ObjCBoundary.m, which also adopts
/// `MPBackendUploadNetworking` for it.
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
        static let configMessageType = "ac"
        static let cacheControlHeader = "Cache-Control"
        static let ageHeader = "Age"
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

    // MARK: - Config and audience requests

    /// Requests the server configuration unless the cached one is still fresh. A response with an
    /// ETag is applied and cached with its ETag and max-age; one without succeeds unapplied. A 304
    /// keeps the cached configuration and restarts its max-age. Uses `connector` when given,
    /// otherwise a new one. Synchronous: `completionHandler` runs on the calling thread before this
    /// returns.
    @objc(requestConfig:withCompletionHandler:)
    public func requestConfig(
        _ connector: (NSObject & MPConnectorProtocol)?,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let userDefaults = host.userDefaults()
        guard userDefaults.isConfigurationExpired() else {
            completionHandler(true)
            return
        }

        let logger = logger
        logger.verbose("Starting config request")
        let start = Date().timeIntervalSince1970

        let taskId = beginSafeBackgroundTask(expirationHandler: nil)
        let connector: MPConnectorProtocol = connector ?? makeConnector()
        let response = configURL.map { connector.responseFromGetRequest(to: $0) }
        let data = response?.data
        let httpResponse = response?.httpResponse

        // Header names are case-insensitive; a Swift dictionary bridged from allHeaderFields is not.
        let ageString = httpResponse?.value(forHTTPHeaderField: Constant.ageHeader)
        let currentAge = (ageString as NSString?)?.doubleValue ?? 0
        let maxAge = maxAge(forCache: httpResponse?.value(forHTTPHeaderField: Constant.cacheControlHeader))

        endSafeBackgroundTask(taskId)

        var responseCode = httpResponse?.statusCode ?? 0
        let elapsed = (Date().timeIntervalSince1970 - start) * 1000.0
        logger.verbose(String(format: "Config Response Code: %ld, Execution Time: %.2fms", responseCode, elapsed))

        if responseCode == HTTPStatusCode.notModified.rawValue {
            logger.debug("Config response 304 Not Modified - using cached config")
            if let configuration = userDefaults.getConfiguration() {
                userDefaults.setConfiguration(
                    configuration,
                    eTag: userDefaults[Miscellaneous.kMPHTTPETagHeaderKey] as? String ?? "",
                    requestTimestamp: Date().timeIntervalSince1970,
                    currentAge: currentAge,
                    maxAge: maxAge
                )
            }
            completionHandler(true)
            return
        }

        var success = responseCode == HTTPStatusCode.success.rawValue || responseCode == HTTPStatusCode.accepted.rawValue

        if data == nil, success {
            completionHandler(false)
            logger.error(String(
                format: "Config request failed - no data received (responseCode: %ld). Kits may not initialize.",
                responseCode
            ))
            return
        }

        var configuration: [AnyHashable: Any]?
        if success, let data, !data.isEmpty {
            let body = try? JSONSerialization.jsonObject(with: data)
            configuration = body as? [AnyHashable: Any]
            let messageType = configuration?[MessageKeys.kMPMessageTypeKey]
            success = messageType as? String == Constant.configMessageType
            // A body that parsed but is not an object, or whose message type is not a string, used to
            // raise inside an Objective-C @try, whose handler reported the failure as a 204.
            if body != nil, configuration == nil || !(messageType == nil || messageType is String) {
                responseCode = HTTPStatusCode.noContent.rawValue
            }
        } else {
            success = false
        }

        guard success, let configuration else {
            logger.error(String(
                format: "Config request failed - could not parse response or wrong message type (responseCode: %ld). "
                    + "Kits may not initialize.",
                responseCode
            ))
            completionHandler(false)
            return
        }

        if let eTag = httpResponse?.value(forHTTPHeaderField: Miscellaneous.kMPHTTPETagHeaderKey) {
            let responseConfig = MPResponseConfig(
                configuration: configuration,
                dataReceivedFromServer: true,
                connector: host.userDefaultsConnector()
            )
            logger.debug("MPResponseConfig init: \(responseConfig?.description ?? "(null)")")

            // An entry no kit can be configured from is dropped here rather than written to the
            // cache, where it would be re-read and re-rejected at every launch. The live
            // MPResponseConfig above still sees the response as it arrived.
            userDefaults.setConfiguration(
                MPKitConfigurationParser.configurationDroppingUnusableKits(from: configuration),
                eTag: eTag,
                requestTimestamp: Date().timeIntervalSince1970,
                currentAge: currentAge,
                maxAge: maxAge
            )
        }

        completionHandler(true)
    }

    /// Requests the current user's audience memberships. Hands `completionHandler` the audience
    /// IDs as `NSNumber`s, or nil when there are none; the Objective-C module makes the public
    /// audience objects from them. Synchronous: `completionHandler` runs on the calling thread
    /// before this returns.
    @objc(requestAudiencesWithCompletionHandler:)
    public func requestAudiences(completionHandler: @escaping (Bool, [Any]?, Error?) -> Void) {
        let taskId = beginSafeBackgroundTask(expirationHandler: nil)
        let connector = makeConnector()
        let response = audienceURL.map { connector.responseFromGetRequest(to: $0) }
        endSafeBackgroundTask(taskId)

        let audienceResponse = MPAudienceResponsePRIVATE.response(
            from: response?.data,
            statusCode: response?.httpResponse?.statusCode ?? 0,
            logger: logger
        )
        let audienceIDs = audienceResponse.audienceIDs
        completionHandler(audienceResponse.isSuccess, audienceIDs.isEmpty ? nil : audienceIDs, audienceResponse.error)
    }
}
