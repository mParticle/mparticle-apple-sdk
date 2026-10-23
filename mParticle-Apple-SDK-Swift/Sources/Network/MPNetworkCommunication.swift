import Foundation
import UIKit

/// Makes the connectors the network layer sends requests with, in place of `MPConnector`. Tests set
/// one as `MPNetworkCommunicationPRIVATE.connectorFactory`.
@objc(MPConnectorFactoryProtocol)
protocol MPConnectorFactoryProtocol {
    @objc func createConnector() -> MPConnectorProtocol
}

/// The SDK's network layer. It holds the host it reads the SDK through, builds the endpoint URLs and
/// the connectors, holds the background tasks and upload throttling the requests use, and builds and
/// sends the config, audience, upload and identity requests.
///
/// Besides the initialiser, which `MPUserDefaultsConnector` calls, the `MPBackendUploadNetworking`
/// requests, the identity entry points and the alias body, every member Objective-C can see exists
/// for the tests.
@objc(MPNetworkCommunication_PRIVATE)
public final class MPNetworkCommunicationPRIVATE: NSObject, MPBackendUploadNetworking {
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
        static let responseHeaderMessageType = "rh"
        // Response headers are read with `value(forHTTPHeaderField:)`, which ignores case as HTTP
        // requires; a Swift dictionary bridged from `allHeaderFields` does not.
        static let cacheControlHeader = "Cache-Control"
        static let ageHeader = "Age"
        static let retryAfterHeader = "Retry-After"
        static let identityMaxAgeHeader = "X-MP-Max-Age"
    }

    /// The identity error domain and userInfo key, the `MPIdentityErrorResponseCode` values an
    /// identity request fails with, and `MPConnectivityErrorCodeNoConnection`, mirrored from
    /// MPEnums.h and MPEnums.m, which this module cannot import.
    private enum IdentityError {
        static let domain = "mParticle Identity Error Domain"
        static let key = "mParticle Identity Error"
        static let unknown = 0
        static let requestInProgress = 1
        static let clientNoConnection = 3
        static let sslError = 4
        static let optOut = 5
        static let noConnectionTransportCode = 1
    }

    /// `MPEnvironmentProduction`, the one environment an identity request reports as production.
    private static let productionEnvironment: UInt = 2

    /// The `MPUploadType` values.
    private enum UploadType {
        static let message: UInt = 0
        static let alias: UInt = 1
    }

    /// Replaces `MPConnector` for every request while set.
    @objc static var connectorFactory: MPConnectorFactoryProtocol?

    let host: MPNetworkHost
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
    @objc var identifying: Bool {
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

    @objc var configURL: MPURL? {
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

    @objc var audienceURL: MPURL? {
        urlFactory.audienceURL(routing: networkRouting, defaultEventHost: defaultEventHost, mpId: host.mpId())
    }

    @objc var identifyURL: MPURL? {
        if memoizedIdentifyURL == nil {
            memoizedIdentifyURL = identityURL(pathComponent: "identify")
        }
        return memoizedIdentifyURL
    }

    var loginURL: MPURL? {
        if memoizedLoginURL == nil {
            memoizedLoginURL = identityURL(pathComponent: "login")
        }
        return memoizedLoginURL
    }

    var logoutURL: MPURL? {
        if memoizedLogoutURL == nil {
            memoizedLogoutURL = identityURL(pathComponent: "logout")
        }
        return memoizedLogoutURL
    }

    @objc var modifyURL: MPURL? {
        urlFactory.modifyURL(routing: networkRouting, defaultIdentityHost: defaultIdentityHost, mpId: host.mpId())
    }

    private func identityURL(pathComponent: String) -> MPURL? {
        urlFactory.identityURL(routing: networkRouting, defaultIdentityHost: defaultIdentityHost, pathComponent: pathComponent)
    }

    /// The event URL for an upload, routed by the upload's own settings.
    @objc(eventURLForUpload:)
    func eventURL(for upload: MPUploadPRIVATE) -> MPURL? {
        urlFactory.eventURL(routing: routing(for: upload), defaultEventHost: defaultEventHost)
    }

    /// The alias URL for an upload, routed by the upload's own settings.
    @objc(aliasURLForUpload:)
    func aliasURL(for upload: MPUploadPRIVATE) -> MPURL? {
        urlFactory.aliasURL(routing: routing(for: upload), defaultEventHost: defaultEventHost)
    }

    // MARK: - Connector

    /// The SDK's log, or one at the SDK's log level while the shared one is not set yet.
    private var logger: MPLog {
        host.sdkLogger() ?? MPLog(logLevel: MPLog.from(rawValue: host.logLevel()))
    }

    /// The connector for one request: the test factory's while one is set, otherwise a new
    /// `MPConnector`. Dynamic, so a partial mock's stub also answers the calls made from Swift.
    @objc dynamic func makeConnector() -> MPConnectorProtocol {
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
    func beginSafeBackgroundTask(expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
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
    func endSafeBackgroundTask(_ taskId: UIBackgroundTaskIdentifier) {
        guard taskId != .invalid else { return }
        host.executeOnMain {
            MPApplication_PRIVATE.sharedUIApplication()?.endBackgroundTask(taskId)
        }
    }

    // MARK: - Retries and caching

    /// Holds back uploads of `uploadType` for `retryAfter` seconds, unless they are held back already.
    func throttle(retryAfter: TimeInterval, uploadType: UInt) {
        let logger = host.sdkLogger()
        let now = Date()
        guard host.stateMachine().minUploadDate(forUploadType: uploadType).compare(now) == .orderedAscending else {
            return
        }
        host.stateMachine().setMinUploadDate(now.addingTimeInterval(retryAfter), uploadType: uploadType)
        switch uploadType {
        case UploadType.message:
            logger?.debug(String(format: "Throttling uploads for %.0f seconds", retryAfter))
        case UploadType.alias:
            logger?.debug(String(format: "Throttling alias requests for %.0f seconds", retryAfter))
        default:
            break
        }
    }

    /// The `max-age` of a config response's Cache-Control header, capped at a day.
    @objc(maxAgeForCache:)
    func maxAge(forCache cacheControl: String?) -> NSNumber? {
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
            // A body that parsed but is not an object, or has a non-string message type, fails as a 204.
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

    // MARK: - Uploads

    /// Sends `uploads` in order, stopping at the first one that is to be sent again later.
    /// Synchronous: `completionHandler` runs once, on the calling thread, before this returns.
    @objc(upload:completionHandler:)
    public func upload(_ uploads: [MPUploadPRIVATE], completionHandler: @escaping () -> Void) {
        let taskId = beginSafeBackgroundTask(expirationHandler: nil)
        for upload in uploads {
            let shouldStop = autoreleasepool { () -> Bool in
                switch upload.uploadType {
                case UploadType.message: return performMessageUpload(upload)
                case UploadType.alias: return performAliasUpload(upload)
                default: return false
                }
            }
            if shouldStop {
                break
            }
        }
        endSafeBackgroundTask(taskId)
        completionHandler()
    }

    /// Sends a batch, gzipped, with the current App Tracking Transparency state applied to its
    /// device information. Answers whether the upload loop is to stop.
    @objc(performMessageUpload:)
    func performMessageUpload(_ upload: MPUploadPRIVATE) -> Bool {
        let stateMachine = host.stateMachine()
        if stateMachine.minUploadDate(forUploadType: UploadType.message) > Date() {
            return true
        }

        let eventURL = eventURL(for: upload)
        var uploadString = upload.serializedString()
        let connector = makeConnector()
        let logger = logger
        logger.verbose("Beginning upload for upload ID: \(upload.uuid ?? "(null)")")

        let zipUploadData: Data?
        if let authStatus = stateMachine.attAuthorizationStatus, let authTimestamp = stateMachine.attAuthorizationTimestamp {
            let updatedData = MPUploadDeviceInfo.uploadDataApplyingATT(
                upload.uploadData, authStatus: authStatus.intValue, authTimestamp: authTimestamp
            )
            uploadString = String(data: updatedData, encoding: .utf8)
            zipUploadData = MPZipPRIVATE.compressedData(from: updatedData)
        } else {
            zipUploadData = MPZipPRIVATE.compressedData(from: upload.uploadData)
        }

        guard let zipUploadData, !zipUploadData.isEmpty else {
            host.deleteUpload(upload)
            return false
        }
        let start = Date().timeIntervalSince1970

        let response = eventURL.map {
            connector.responseFromPostRequest(
                to: $0, message: uploadString, serializedParams: zipUploadData,
                secret: host.secret(ofUploadSettings: upload.uploadSettings)
            )
        }
        let httpResponse = response?.httpResponse
        let responseCode = httpResponse?.statusCode ?? 0
        logger.verbose("Upload response code: \(responseCode)")

        let outcome = MPUploadResponseHandler.handleMessageResponse(
            statusCode: responseCode,
            transportError: response?.error,
            headers: retryHeaders(of: httpResponse),
            uploadString: uploadString,
            upload: upload,
            persistence: host,
            kitBatchLogger: host
        )

        if outcome.isSuccess, let data = response?.data, !data.isEmpty {
            let body = try? JSONSerialization.jsonObject(with: data)
            let responseObject = body as? NSDictionary
            let messageType = responseObject?[MessageKeys.kMPMessageTypeKey]
            // A body that parsed but is not an object, or has a non-string message type, is an upload error.
            if body != nil, responseObject == nil || !(messageType == nil || messageType is String) {
                let reason = responseObject == nil ? "response is not a JSON object" : "response message type is not a string"
                logger.error("Upload error: \(reason)")
            } else {
                if let responseObject, messageType as? String == Constant.responseHeaderMessageType {
                    host.mergeConsumerInfo(fromResponse: responseObject)
                }
                // MPLog takes a finished string, so one that holds a whole batch or body is only built
                // when verbose logging would print it.
                if logger.logLevel == .verbose {
                    logger.verbose("Upload complete: \(uploadString ?? "(null)")\n")
                }
            }
        }

        logger.verbose(String(format: "Upload execution time: %.2fms", (Date().timeIntervalSince1970 - start) * 1000.0))

        if outcome.shouldThrottle {
            throttle(retryAfter: outcome.throttleRetryAfter, uploadType: UploadType.message)
        }
        return outcome.willRetry
    }

    /// The response's `Retry-After` header, the only one the throttle reads.
    private func retryHeaders(of response: HTTPURLResponse?) -> NSDictionary {
        guard let retryAfter = response?.value(forHTTPHeaderField: Constant.retryAfterHeader) else {
            return [:]
        }
        return [Constant.retryAfterHeader: retryAfter]
    }

    /// Sends an alias request, uncompressed. Answers whether the upload loop is to stop.
    @objc(performAliasUpload:)
    func performAliasUpload(_ upload: MPUploadPRIVATE) -> Bool {
        if host.stateMachine().minUploadDate(forUploadType: UploadType.alias) > Date() {
            return true
        }

        let aliasURL = aliasURL(for: upload)
        let uploadString = upload.serializedString()
        let connector = makeConnector()
        let logger = logger
        logger.verbose("Beginning alias request with upload ID: \(upload.uuid ?? "(null)")")

        guard !upload.uploadData.isEmpty else {
            host.deleteUpload(upload)
            return false
        }
        let start = Date().timeIntervalSince1970

        if logger.logLevel == .verbose {
            logger.verbose("Alias request:\nURL: \(aliasURL.map { "\($0.url)" } ?? "(null)") \nBody:\(uploadString ?? "(null)")")
        }

        let response = aliasURL.map {
            connector.responseFromPostRequest(
                to: $0, message: uploadString, serializedParams: upload.uploadData,
                secret: host.secret(ofUploadSettings: upload.uploadSettings)
            )
        }
        let httpResponse = response?.httpResponse
        let responseCode = httpResponse?.statusCode ?? 0
        logger.verbose("Alias response code: \(responseCode)")

        let plan = MPAliasResponsePlanPRIVATE.plan(
            requestData: upload.uploadData, responseData: response?.data, statusCode: responseCode, logger: logger
        )
        if plan.isSuccessCode {
            MPTransportErrorDetector.resetTransportErrorCounter()
        }
        if plan.isSuccessCode || plan.isInvalidCode {
            host.deleteUpload(upload)
        }

        if logger.logLevel == .verbose, let data = response?.data,
           let responseString = String(data: data, encoding: .utf8), !responseString.isEmpty {
            logger.verbose("Alias response:\n\(responseString)")
        }

        logger.verbose(String(format: "Alias execution time: %.2fms", (Date().timeIntervalSince1970 - start) * 1000.0))

        // 429, 503
        if plan.shouldRetry {
            let retryAfter = MPNetworkCommunicationHelper.calculateRetryTime(for: retryHeaders(of: httpResponse)).doubleValue
            throttle(retryAfter: retryAfter, uploadType: upload.uploadType)
            return true
        }

        // 5xx, 0, 999, -1, etc
        if !plan.isSuccessCode, !plan.isInvalidCode {
            if MPTransportErrorDetector.isRetriableTransportError(response?.error) {
                logger.warning("Throttling alias requests after transport error.")
                let retryAfter = MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue
                throttle(retryAfter: retryAfter, uploadType: UploadType.alias)
            }
            return true
        }

        return false
    }

    // MARK: - Identity entry points

    // `identities` is an `MPIdentityApiRequest`'s: each value, keyed by `MPIdentity` number, is a
    // string or NSNull. Each entry point completes synchronously, as `identityRequest` does.

    /// Identifies the user by `identities`, blocking the other identity requests.
    @objc(identify:completion:)
    public func identify(_ identities: NSDictionary?, completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?) {
        sendIdentifyRequest(to: .identityIdentify, identities: identities, completion: completion)
    }

    /// Logs the user in by `identities`, blocking the other identity requests.
    @objc(login:completion:)
    public func login(_ identities: NSDictionary?, completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?) {
        sendIdentifyRequest(to: .identityLogin, identities: identities, completion: completion)
    }

    /// Logs the user out, blocking the other identity requests.
    @objc(logout:completion:)
    public func logout(_ identities: NSDictionary?, completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?) {
        sendIdentifyRequest(to: .identityLogout, identities: identities, completion: completion)
    }

    /// Sends the identities in `identities` that differ from the current user's, an NSNull one as
    /// removed, blocking the other identity requests. With none, `completion` succeeds unsent.
    @objc(modify:completion:)
    public func modify(_ identities: NSDictionary?, completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?) {
        logIfAdvertiserIdPrecedesATTStatus(identities)
        let currentIdentities = host.currentUserIdentities()
        var changes: [MPIdentityHTTPIdentityChangePRIVATE] = []
        identities?.enumerateKeysAndObjects { key, value, _ in
            // A value that is neither, which the public API cannot set, is skipped rather than sent as removed.
            guard let identityType = key as? NSNumber, value is String || value is NSNull else { return }
            let oldValue = currentIdentities?[identityType] as? String
            let newValue = value as? String
            if let oldValue, let newValue, (newValue as NSString).isEqual(to: oldValue) {
                return
            }
            changes.append(MPIdentityHTTPIdentityChangePRIVATE(
                oldValue: oldValue, value: newValue,
                identityType: MPIdentityHTTPIdentitiesPRIVATE.string(forIdentityType: identityType.intValue)
            ))
        }
        modify(identityChanges: changes, blockOtherRequests: true, completion: completion)
    }

    /// Sends one change of a device identifier, without blocking the other identity requests and
    /// with nothing waiting for the outcome.
    @objc(modifyDeviceID:value:oldValue:)
    public func modifyDeviceID(_ deviceIdType: String, value: String, oldValue: String) {
        let change = MPIdentityHTTPIdentityChangePRIVATE(oldValue: oldValue, value: value, identityType: deviceIdType)
        modify(identityChanges: [change], blockOtherRequests: false, completion: nil)
    }

    /// The body of an alias request, which is uploaded as an `MPUploadTypeAlias` upload.
    @objc(aliasRequestDictionaryWithSourceMPID:destinationMPID:startTime:endTime:)
    public func aliasRequestDictionary(
        sourceMPID: NSNumber?,
        destinationMPID: NSNumber?,
        startTime: Date?,
        endTime: Date?
    ) -> NSDictionary {
        let stateMachine = host.stateMachine()
        return MPIdentityHTTPRequestBuilderPRIVATE.aliasDictionary(
            sdkVersion: host.sdkVersion(),
            environment: identityEnvironment,
            apiKey: stateMachine.apiKey,
            sourceMPID: sourceMPID,
            destinationMPID: destinationMPID,
            startTime: startTime,
            endTime: endTime,
            deviceApplicationStamp: stateMachine.consumerInfo.deviceApplicationStamp
        )
    }

    private func sendIdentifyRequest(
        to endpoint: MPEndpoint,
        identities: NSDictionary?,
        completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?
    ) {
        logIfAdvertiserIdPrecedesATTStatus(identities)
        identityRequest(
            to: endpoint, requestDictionary: identifyRequestDictionary(identities: identities),
            blockOtherRequests: true, completion: completion
        )
    }

    /// The body of an identify, login or logout request: `identities`, with the device's own
    /// identifiers added, and the current mpid as the previous one.
    private func identifyRequestDictionary(identities: NSDictionary?) -> NSDictionary {
        let stateMachine = host.stateMachine()
        let knownIdentities = MPIdentityHTTPIdentitiesPRIVATE(
            identities: identities, attAuthorizationStatus: stateMachine.attAuthorizationStatus
        )
        let mpid = host.mpId()
        if let vendorId = host.vendorId() {
            knownIdentities.vendorId = vendorId
        }
        if let deviceApplicationStamp = stateMachine.consumerInfo.deviceApplicationStamp {
            knownIdentities.deviceApplicationStamp = deviceApplicationStamp
        }
        #if os(iOS)
        if !host.isAppExtension(), let deviceToken = host.deviceToken(),
           let pushToken = MPUserDefaults.stringFromDeviceToken(deviceToken), !pushToken.isEmpty {
            knownIdentities.pushToken = pushToken
        }
        #endif
        return MPIdentityHTTPRequestBuilderPRIVATE.identifyDictionary(
            sdkVersion: host.sdkVersion(),
            environment: identityEnvironment,
            previousMPID: mpid.int64Value != 0 ? mpid.stringValue : nil,
            identities: knownIdentities.dictionaryRepresentation()
        )
    }

    /// Sends `identityChanges` as one modify request. With none, `completion` succeeds at once,
    /// unsent, with an empty `MPIdentityHTTPModifySuccessResponse`.
    private func modify(
        identityChanges: [MPIdentityHTTPIdentityChangePRIVATE],
        blockOtherRequests: Bool,
        completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?
    ) {
        if identityChanges.isEmpty {
            completion?(MPIdentityHTTPModifySuccessResponse(), nil)
            return
        }
        let requestDictionary = MPIdentityHTTPRequestBuilderPRIVATE.modifyDictionary(
            sdkVersion: host.sdkVersion(),
            environment: identityEnvironment,
            identityChanges: identityChanges.map { $0.dictionaryRepresentation() } as NSArray
        )
        // Always with a completion, so a failure is logged even when nothing waits for it.
        identityRequest(
            to: .identityModify, requestDictionary: requestDictionary, blockOtherRequests: blockOtherRequests
        ) { completion?($0, $1) }
    }

    private var identityEnvironment: String {
        MPStateMachinePRIVATE.environment() == Self.productionEnvironment ? "production" : "development"
    }

    private func logIfAdvertiserIdPrecedesATTStatus(_ identities: NSDictionary?) {
        if host.userDefaults()[Miscellaneous.kMPATT] == nil,
           identities?[NSNumber(value: MPIdentitySwift.iosAdvertiserId.rawValue)] != nil {
            logger.debug(
                "The IDFA was supplied but the App Tracking Transparency Status not set with "
                    + "[[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]"
            )
        }
    }

    // MARK: - Identity requests

    /// Sends `requestDictionary` to the identity `endpoint`, or answers from the identity cache when
    /// caching is on and holds a usable response. Fails unsent while another blocking request is in
    /// flight or the SDK is opted out. A request that blocks the others holds `identifying` until it
    /// finishes. A modify request succeeds with an `MPIdentityHTTPModifySuccessResponse`, the others
    /// with an `MPIdentityHTTPSuccessResponse`; the host builds a failure's error. Synchronous:
    /// `completion` runs once, on the calling thread, before this returns. Dynamic, so a partial
    /// mock's stub also answers the entry points' calls.
    @objc(identityRequestToEndpoint:requestDictionary:blockOtherRequests:completion:)
    dynamic func identityRequest(
        to endpoint: MPEndpoint,
        requestDictionary: NSDictionary,
        blockOtherRequests: Bool,
        completion: ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?
    ) {
        let logger = logger
        if identifying {
            logger.warning("Identity API request blocked - another identity request is already in progress")
            completion?(nil, NSError(
                domain: IdentityError.domain, code: IdentityError.requestInProgress,
                userInfo: [IdentityError.key: "Identity API request in progress."]
            ))
            return
        }
        if host.optOut() {
            logger.warning("Identity API request blocked - SDK is opted out")
            completion?(nil, NSError(
                domain: IdentityError.domain, code: IdentityError.optOut, userInfo: [IdentityError.key: "Opt Out Enabled."]
            ))
            return
        }
        if blockOtherRequests {
            identifying = true
        }

        let url: MPURL?
        switch endpoint {
        case .identityIdentify: url = identifyURL
        case .identityLogin: url = loginURL
        case .identityLogout: url = logoutURL
        default: url = modifyURL
        }

        let start = Date().timeIntervalSince1970
        // Cannot fail: the DTOs build the dictionary from strings, numbers, NSNull and containers of them.
        let data = try? JSONSerialization.data(withJSONObject: requestDictionary)
        if logger.logLevel == .verbose {
            let jsonRequest = data.flatMap { String(data: $0, encoding: .utf8) }
            logger.verbose("Identity request:\nURL: \(url.map { "\($0.url)" } ?? "(null)") \nBody:\(jsonRequest ?? "(null)")")
        }

        var success = false
        var responseObject: NSDictionary?
        var responseBody: Data?
        var responseCode = 0
        var transportError: NSError?
        var bodyWasNotAnObject = false

        let identityCaching = host.stateMachine().enableIdentityCaching
            ? MPIdentityCaching(userDefaults: host.userDefaults(), logger: logger)
            : nil

        if let cached = identityCaching?.getCachedIdentityResponse(for: endpoint, requestDictionary: requestDictionary) {
            responseBody = cached.bodyData
            // An entry that will not parse, or is not an object, is a miss: the request is sent
            // rather than failing until the entry expires.
            do {
                if let object = try JSONSerialization.jsonObject(with: cached.bodyData) as? NSDictionary {
                    responseObject = object
                    responseCode = cached.statusCode
                    success = true
                } else {
                    logger.error("Cached identity response was unusable: body was not a JSON object")
                }
            } catch {
                logger.error("Cached identity response was unusable: \(error.localizedDescription)")
            }
        }

        let answeredFromCache = success
        if !answeredFromCache {
            let taskId = beginSafeBackgroundTask { [weak self] in self?.identifying = false }
            let connector = makeConnector()
            let response = url.map {
                connector.responseFromPostRequest(to: $0, message: nil, serializedParams: data, secret: nil)
            }
            let responseData = response?.data
            transportError = response?.error
            let httpResponse = response?.httpResponse
            endSafeBackgroundTask(taskId)

            responseCode = httpResponse?.statusCode ?? 0
            success = responseCode == HTTPStatusCode.success.rawValue || responseCode == HTTPStatusCode.accepted.rawValue
            success = success && !(responseData?.isEmpty ?? true)
            logger.verbose("Identity response code: \(responseCode)")

            if success, let responseData {
                responseBody = responseData
                do {
                    // Every reader subscripts the body by key, so only an object is accepted, and that
                    // is settled before caching: a cached bad body would fail each request until it expired.
                    if let object = try JSONSerialization.jsonObject(with: responseData) as? NSDictionary {
                        responseObject = object
                        if let identityCaching {
                            cacheIdentityResponse(
                                responseData, statusCode: responseCode, httpResponse: httpResponse,
                                endpoint: endpoint, requestDictionary: requestDictionary,
                                identityCaching: identityCaching, logger: logger
                            )
                        }
                    } else {
                        bodyWasNotAnObject = true
                        success = false
                    }
                } catch {
                    success = false
                    logger.error("Identity response serialization error: \(error.localizedDescription)")
                }
            }
        }

        logger.verbose(String(format: "Identity execution time: %.2fms", (Date().timeIntervalSince1970 - start) * 1000.0))

        identifying = false

        if success {
            if logger.logLevel == .verbose, let responseString = responseBody.flatMap({ String(data: $0, encoding: .utf8) }) {
                logger.verbose("Identity response:\n\(responseString)")
            }
            let successResponse: MPIdentityHTTPSuccessResponse = endpoint == .identityModify
                ? MPIdentityHTTPModifySuccessResponse(jsonObject: responseObject)
                : MPIdentityHTTPSuccessResponse(jsonObject: responseObject)
            completion?(successResponse, nil)
        } else if let completion {
            completion(nil, identityError(
                transportError: transportError, bodyWasNotAnObject: bodyWasNotAnObject,
                responseCode: responseCode, logger: logger
            ))
        }
    }

    /// Caches an identity response for as many seconds as its `X-MP-Max-Age` header asks, if any.
    private func cacheIdentityResponse(
        _ body: Data,
        statusCode: Int,
        httpResponse: HTTPURLResponse?,
        endpoint: MPEndpoint,
        requestDictionary: NSDictionary,
        identityCaching: MPIdentityCaching,
        logger: MPLog
    ) {
        let header = httpResponse?.value(forHTTPHeaderField: Constant.identityMaxAgeHeader)
        let maxAgeSeconds = (header as NSString?)?.integerValue ?? 0
        logger.verbose("Identity Caching - max age header value (in seconds): \(maxAgeSeconds)")
        guard maxAgeSeconds > 0 else { return }
        let cachedResponse = MPIdentityCachedResponse(
            bodyData: body, statusCode: statusCode, expires: Date().addingTimeInterval(TimeInterval(maxAgeSeconds))
        )
        identityCaching.cacheIdentityResponse(cachedResponse, endpoint: endpoint, requestDictionary: requestDictionary)
    }

    /// The error a failed identity request completes with, logged.
    private func identityError(
        transportError: NSError?,
        bodyWasNotAnObject: Bool,
        responseCode: Int,
        logger: MPLog
    ) -> NSError {
        if let transportError {
            if transportError.code == IdentityError.noConnectionTransportCode {
                logger.error("Identity request failed - no network connectivity")
                return host.identityError(
                    code: IdentityError.clientNoConnection, message: "Device has no network connectivity.",
                    underlyingError: transportError
                )
            }
            if transportError.domain == NSURLErrorDomain {
                logger.error(
                    "Identity request failed - SSL error: \(transportError.localizedDescription) (code: \(transportError.code))"
                )
                return host.identityError(
                    code: IdentityError.sslError, message: "Failed to establish SSL connection.", underlyingError: transportError
                )
            }
            logger.error(
                "Identity request failed - unknown error: \(transportError.localizedDescription) "
                    + "(domain: \(transportError.domain), code: \(transportError.code))"
            )
            return host.identityError(
                code: IdentityError.unknown, message: "An unknown client-side error has occured", underlyingError: transportError
            )
        }
        if bodyWasNotAnObject {
            logger.error("Identity request failed - response body was not a JSON object")
            return host.identityError(
                code: IdentityError.unknown, message: "Identity response body was not a JSON object.", underlyingError: nil
            )
        }
        logger.error("Identity request failed - HTTP error (code: \(responseCode))")
        return host.identityError(httpCode: responseCode)
    }
}
