import UIKit
import XCTest
@testable import mParticle_Apple_SDK_Swift

/// The backend's fake host, plus the network layer's reads. It records which settings and
/// authorisation each upload URL was routed with, each hop to the main thread, and what the uploads
/// asked of the SDK.
private final class MPNetworkFakeHost: MPBackendFakeHost, MPNetworkHost {
    var appVersion: String? = "1.0"
    var level: UInt = 0
    var agent: String? = "web-view-agent"
    var originalAgent: String? = "sdk-agent"
    var inAppExtension = false
    var supported: [NSNumber]? = [1, 2]
    var configured: [NSNumber]? = [1]
    var certificates: [Data] = []
    var pinningOff = false
    let configConnector = MPUserDefaultsConnectorMock()
    var uploadSecret: String? = "upload-secret"
    var currentIdentities: NSDictionary?
    var vendorIdValue: String?
    var deviceTokenValue: Data?
    /// The config, events and identity host the network routing names, if any.
    var routedHost: String?
    private(set) var deletedUploads: [MPUploadPRIVATE] = []
    private(set) var kitBatches: [String] = []
    private(set) var mergedResponses: [NSDictionary] = []
    private(set) var uploadRoutings: [(settings: NSObject, attAuthorized: Bool)] = []
    private(set) var mainHops: [String] = []

    func networkRouting(attAuthorized: Bool) -> MPEndpointRouting {
        Self.routing(apiKey: "network-key", host: routedHost, attAuthorized: attAuthorized)
    }

    func routing(forUploadSettings uploadSettings: NSObject, attAuthorized: Bool) -> MPEndpointRouting {
        uploadRoutings.append((uploadSettings, attAuthorized))
        return Self.routing(apiKey: "upload-key", attAuthorized: attAuthorized)
    }

    func secret(ofUploadSettings uploadSettings: NSObject) -> String? {
        uploadSettings === self.uploadSettings ? uploadSecret : nil
    }

    func applicationVersion() -> String? { appVersion }
    func logLevel() -> UInt { level }
    func userAgent() -> String? { agent }
    func originalDefaultUserAgent() -> String? { originalAgent }
    func isAppExtension() -> Bool { inAppExtension }
    func supportedKits() -> [NSNumber]? { supported }
    func configuredKits() -> [NSNumber]? { configured }
    func customCertificates() -> [Data] { certificates }
    func pinningDisabled() -> Bool { pinningOff }
    func pinningDisabledInDevelopment() -> Bool { false }

    func executeOnMainSync(_ block: @escaping () -> Void) {
        mainHops.append("sync")
        block()
    }

    override func executeOnMain(_: @escaping () -> Void) {
        mainHops.append("async")
    }

    func mergeConsumerInfo(fromResponse response: NSDictionary) { mergedResponses.append(response) }
    func deleteUpload(_ upload: MPUploadPRIVATE) { deletedUploads.append(upload) }
    func logKitBatch(_ uploadString: String) { kitBatches.append(uploadString) }
    func userDefaultsConnector() -> MPUserDefaultsConnectorProtocol { configConnector }
    func currentUserIdentities() -> NSDictionary? { currentIdentities }
    func vendorId() -> String? { vendorIdValue }
    #if os(iOS)
    func deviceToken() -> Data? { deviceTokenValue }
    #endif

    /// Stands in for the Objective-C error response, keeping what it was made from.
    func identityError(code: Int, message: String, underlyingError: NSError?) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: message]
        userInfo[NSUnderlyingErrorKey] = underlyingError
        return NSError(domain: "client-side", code: code, userInfo: userInfo)
    }

    func identityError(httpCode: Int) -> NSError {
        NSError(domain: "server", code: httpCode)
    }

    private static func routing(apiKey: String, host: String? = nil, attAuthorized: Bool) -> MPEndpointRouting {
        MPEndpointRouting(
            apiKey: apiKey, customBaseURLHost: nil, hasCustomBaseURL: false, configHost: host,
            eventsHost: host, eventsTrackingHost: nil, identityHost: host, identityTrackingHost: nil,
            aliasHost: nil, aliasTrackingHost: nil, overridesConfigSubdirectory: false,
            overridesEventsSubdirectory: false, overridesIdentitySubdirectory: false,
            overridesAliasSubdirectory: false, eventsOnly: false, attAuthorized: attAuthorized
        )
    }
}

/// One request a fake connector was asked to post.
private struct MPNetworkFakePost {
    let url: URL
    let message: String?
    let params: Data?
    let secret: String?
}

/// Records every verbose message it is handed, whether or not its level prints it.
private final class MPVerboseRecordingLog: MPLog {
    private(set) var verboseMessages: [String] = []

    override func verbose(_ message: String) {
        verboseMessages.append(message)
        super.verbose(message)
    }
}

final class MPNetworkCommunicationTests: XCTestCase {
    private var host: MPNetworkFakeHost!
    private var network: MPNetworkCommunicationPRIVATE!

    override func setUp() {
        super.setUp()
        host = MPNetworkFakeHost(defaults: MPBackendMemoryUserDefaults())
        host.machine.apiKey = "us2-test"
        network = MPNetworkCommunicationPRIVATE(host: host)
    }

    override func tearDown() {
        MPNetworkCommunicationPRIVATE.connectorFactory = nil
        network = nil
        host = nil
        super.tearDown()
    }

    private func authorizeTracking() {
        host.machine.attAuthorizationStatus = NSNumber(value: MPATTAuthorizationStatusSwift.authorized.rawValue)
    }

    func testDefaultHostsUseTheApiKeyPodAndTrackingSubdomainsOnlyOnceAuthorized() {
        XCTAssertEqual(network.defaultEventHost, "nativesdks.us2.mparticle.com")
        XCTAssertEqual(network.defaultIdentityHost, "identity.us2.mparticle.com")

        host.machine.attAuthorizationStatus = NSNumber(value: MPATTAuthorizationStatusSwift.denied.rawValue)
        XCTAssertEqual(network.defaultEventHost, "nativesdks.us2.mparticle.com")

        authorizeTracking()
        XCTAssertEqual(network.defaultEventHost, "tracking-nativesdks.us2.mparticle.com")
        XCTAssertEqual(network.defaultIdentityHost, "tracking-identity.us2.mparticle.com")
    }

    func testConfigAndIdentityURLsAreKeptOnceBuilt() {
        let config = network.configURL
        let identify = network.identifyURL
        let login = network.loginURL
        let logout = network.logoutURL
        XCTAssertEqual(config?.url.query, "av=1.0&sv=0.0.0-test")
        XCTAssertEqual(identify?.url.absoluteString, "https://identity.us2.mparticle.com/v1/identify")

        host.appVersion = "2.0"
        host.machine.apiKey = "eu1-test"

        XCTAssertTrue(network.configURL === config)
        XCTAssertTrue(network.identifyURL === identify)
        XCTAssertTrue(network.loginURL === login)
        XCTAssertTrue(network.logoutURL === logout)

        // A network layer made now sees the change, so the URLs above were kept rather than rebuilt alike.
        let fresh = MPNetworkCommunicationPRIVATE(host: host)
        XCTAssertEqual(fresh.configURL?.url.query, "av=2.0&sv=0.0.0-test")
        XCTAssertEqual(fresh.identifyURL?.url.absoluteString, "https://identity.eu1.mparticle.com/v1/identify")
        XCTAssertEqual(fresh.loginURL?.url.absoluteString, "https://identity.eu1.mparticle.com/v1/login")
        XCTAssertEqual(fresh.logoutURL?.url.absoluteString, "https://identity.eu1.mparticle.com/v1/logout")
    }

    func testAudienceAndModifyURLsFollowTheCurrentUser() {
        host.currentUserId = 1
        XCTAssertEqual(
            network.audienceURL?.url.absoluteString,
            "https://nativesdks.us2.mparticle.com/v1/network-key/audience?mpid=1"
        )
        XCTAssertEqual(network.modifyURL?.url.absoluteString, "https://identity.us2.mparticle.com/v1/1/modify")

        host.currentUserId = 2
        XCTAssertEqual(
            network.audienceURL?.url.absoluteString,
            "https://nativesdks.us2.mparticle.com/v1/network-key/audience?mpid=2"
        )
        XCTAssertEqual(network.modifyURL?.url.absoluteString, "https://identity.us2.mparticle.com/v1/2/modify")
    }

    func testUploadURLsAreRoutedByTheUploadsOwnSettings() {
        let settings = NSObject()
        let upload = MPUploadPRIVATE(
            sessionId: nil, uploadId: 1, uuid: nil, uploadData: Data(), timestamp: 0, uploadType: 0,
            dataPlanId: nil, dataPlanVersion: nil, uploadSettings: settings
        )
        authorizeTracking()

        XCTAssertEqual(
            network.eventURL(for: upload)?.url.absoluteString,
            "https://tracking-nativesdks.us2.mparticle.com/v2/upload-key/events"
        )
        XCTAssertEqual(
            network.aliasURL(for: upload)?.url.absoluteString,
            "https://tracking-nativesdks.us2.mparticle.com/v1/identity/upload-key/alias"
        )
        XCTAssertEqual(host.uploadRoutings.count, 2)
        XCTAssertTrue(host.uploadRoutings.allSatisfy { $0.settings === settings && $0.attAuthorized })
    }

    // MARK: - Connector

    private final class FakeConnectorFactory: NSObject, MPConnectorFactoryProtocol {
        let connector: MPConnectorProtocol
        init(_ connector: MPConnectorProtocol = MPConnector()) { self.connector = connector }
        func createConnector() -> MPConnectorProtocol { connector }
    }

    func testRequestContextCarriesOnlyWhatEachKindSends() {
        host.machine.secret = "s3cret"
        host.defaults.setConfiguration(["dt": "ac"], eTag: "etag-1", requestTimestamp: 0, currentAge: 0, maxAge: nil)

        let audience = network.requestContext(for: .audience)
        XCTAssertEqual(audience.apiKey, "us2-test")
        XCTAssertEqual(audience.fallbackSecret, "s3cret")
        XCTAssertEqual(audience.userAgent, "web-view-agent")
        XCTAssertNil(audience.supportedKits)

        let identity = network.requestContext(for: .identity)
        XCTAssertEqual(identity.apiKey, "us2-test")
        XCTAssertEqual(identity.fallbackSecret, "s3cret")
        XCTAssertNil(identity.userAgent)

        let event = network.requestContext(for: .event)
        XCTAssertNil(event.apiKey)
        XCTAssertEqual(event.supportedKits, [1, 2])
        XCTAssertEqual(event.configuredKits, [1])
        XCTAssertEqual(event.userAgent, "web-view-agent")
        XCTAssertNil(event.eTag)
        XCTAssertFalse(event.hasStoredConfiguration)
        XCTAssertEqual(event.environment, 0)

        let config = network.requestContext(for: .config)
        XCTAssertNil(config.apiKey)
        XCTAssertEqual(config.eTag, "etag-1")
        XCTAssertTrue(config.hasStoredConfiguration)
        XCTAssertEqual(config.supportedKits, [1, 2])
        XCTAssertNil(config.configuredKits)
        XCTAssertEqual(config.userAgent, "sdk-agent")
        XCTAssertEqual(config.environment, Int(MPStateMachinePRIVATE.environment()))

        let custom = network.requestContext(for: .custom)
        XCTAssertNil(custom.fallbackSecret)
        XCTAssertNil(custom.apiKey)
        XCTAssertNil(custom.userAgent)

        for context in [audience, identity, event, config, custom] {
            XCTAssertEqual(context.requestTimeout, 10)
            XCTAssertEqual(context.networkPerformanceMessageType, "npe")
            XCTAssertTrue(context.logger === host.log)
        }
    }

    func testAnUnsetSecretSignsNothing() {
        host.machine.secret = ""
        XCTAssertNil(network.requestContext(for: .identity).fallbackSecret)
    }

    func testWithoutTheSharedLogARequestLogsAtTheSDKLogLevel() {
        host.log = nil
        host.level = MPILogLevelSwift.debug.rawValue

        XCTAssertEqual(network.requestContext(for: .custom).logger.logLevel, .debug)
        XCTAssertEqual(network.connectorConfiguration.logger.logLevel, .debug)
    }

    func testConnectorConfigurationReadsPinningAndEachRequestsContextWhenTheRequestIsBuilt() {
        host.certificates = [Data("certificate".utf8)]
        host.pinningOff = true
        host.isDevelopment = true

        let configuration = network.connectorConfiguration
        XCTAssertEqual(configuration.customCertificates, host.certificates)
        XCTAssertTrue(configuration.pinningDisabled)
        XCTAssertFalse(configuration.pinningDisabledInDevelopment)
        XCTAssertTrue(configuration.isDevelopmentEnvironment)
        XCTAssertEqual(configuration.secureScheme, "https")
        XCTAssertEqual(configuration.requestTimeout, 10)
        XCTAssertTrue(configuration.logger === host.log)

        host.machine.apiKey = "eu1-later"
        XCTAssertEqual(configuration.requestContext(for: .identity).apiKey, "eu1-later")
    }

    func testMakeConnectorUsesTheFactoryWhileOneIsSet() {
        let factory = FakeConnectorFactory()
        MPNetworkCommunicationPRIVATE.connectorFactory = factory
        defer { MPNetworkCommunicationPRIVATE.connectorFactory = nil }
        XCTAssertTrue(network.makeConnector() === factory.connector)

        MPNetworkCommunicationPRIVATE.connectorFactory = nil
        let connector = network.makeConnector()
        XCTAssertTrue(connector is MPConnector)
        XCTAssertFalse(connector === factory.connector)
    }

    // MARK: - Background tasks

    func testABackgroundTaskIsBegunOnTheMainThreadButNeverInAnAppExtension() {
        host.inAppExtension = true
        XCTAssertEqual(network.beginSafeBackgroundTask(expirationHandler: nil), .invalid)
        XCTAssertEqual(host.mainHops, [])

        host.inAppExtension = false
        _ = network.beginSafeBackgroundTask(expirationHandler: nil)
        XCTAssertEqual(host.mainHops, ["sync"])
    }

    func testOnlyAValidBackgroundTaskIsEndedOnTheMainThread() {
        network.endSafeBackgroundTask(.invalid)
        XCTAssertEqual(host.mainHops, [])

        network.endSafeBackgroundTask(UIBackgroundTaskIdentifier(rawValue: 42))
        XCTAssertEqual(host.mainHops, ["async"])
    }

    // MARK: - Retries and caching

    func testThrottlingHoldsUploadsBackOnceAndLogsWhichKind() {
        var messages: [String] = []
        host.log = MPLog(logLevel: .debug)
        host.log?.customLogger = { messages.append($0) }

        network.throttle(retryAfter: 60, uploadType: 0)
        let held = host.machine.minUploadDate(forUploadType: 0)
        XCTAssertEqual(held.timeIntervalSinceNow, 60, accuracy: 5)

        network.throttle(retryAfter: 600, uploadType: 0)
        XCTAssertEqual(host.machine.minUploadDate(forUploadType: 0), held)

        network.throttle(retryAfter: 30, uploadType: 1)
        XCTAssertEqual(host.machine.minUploadDate(forUploadType: 1).timeIntervalSinceNow, 30, accuracy: 5)

        XCTAssertEqual(messages, [
            "mParticle -> Throttling uploads for 60 seconds",
            "mParticle -> Throttling alias requests for 30 seconds"
        ])
    }

    func testConfigMaxAgeIsCappedAtADay() {
        XCTAssertEqual(network.maxAge(forCache: "max-age=90000"), 86400)
        XCTAssertEqual(network.maxAge(forCache: "max-age=12"), 12)
        XCTAssertNil(network.maxAge(forCache: nil))
    }

    // MARK: - Config and audience requests

    /// Answers every request with one settable response, and records the URLs asked for and what
    /// was posted.
    private final class FakeConnector: NSObject, MPConnectorProtocol {
        let response = MPConnectorResponse()
        private(set) var requestedURLs: [URL] = []
        private(set) var posts: [MPNetworkFakePost] = []
        var onPost: () -> Void = {}

        func respond(_ statusCode: Int, body: Data? = nil, headers: [String: String] = [:], error: NSError? = nil) {
            response.httpResponse = HTTPURLResponse(
                url: URL(string: "https://example.com")!, statusCode: statusCode, httpVersion: nil, headerFields: headers
            )
            response.data = body
            response.error = error
        }

        func responseFromGetRequest(to url: MPURL) -> MPConnectorResponseProtocol {
            requestedURLs.append(url.url)
            return response
        }

        func responseFromPostRequest(
            to url: MPURL, message: String?, serializedParams: Data?, secret: String?
        ) -> MPConnectorResponseProtocol {
            posts.append(MPNetworkFakePost(url: url.url, message: message, params: serializedParams, secret: secret))
            onPost()
            return response
        }
    }

    private func json(_ object: Any) -> Data {
        (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }

    /// The result of a config request, nil if the completion did not run before the call returned.
    private func requestConfig(_ connector: FakeConnector) -> Bool? {
        var result: Bool?
        network.requestConfig(connector) { result = $0 }
        return result
    }

    private var provisionedAge: TimeInterval? {
        (host.defaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber)
            .map { Date().timeIntervalSince1970 - $0.doubleValue }
    }

    func testAFreshCachedConfigurationIsNotRequestedAgain() {
        host.defaults.setConfiguration(
            ["dt": "ac"], eTag: "etag-1", requestTimestamp: Date().timeIntervalSince1970, currentAge: 0, maxAge: nil
        )
        let connector = FakeConnector()

        XCTAssertEqual(requestConfig(connector), true)
        XCTAssertEqual(connector.requestedURLs, [])
    }

    func testAConfigResponseIsAppliedThroughTheHostAndCachedWithItsHeadersInAnyCase() {
        let connector = FakeConnector()
        connector.respond(
            200,
            body: json(["dt": "ac", "id": 42, "cms": [["id": 1]]]),
            headers: ["etag": "etag-2", "cache-control": "max-age=600", "age": "100"]
        )

        XCTAssertEqual(requestConfig(connector), true)
        XCTAssertEqual(connector.requestedURLs, [network.configURL?.url])
        XCTAssertNotNil(host.configConnector.configureCustomModulesCustomModuleSettingsParams)
        XCTAssertEqual(host.defaults.getConfiguration()?["id"] as? Int, 42)
        XCTAssertEqual(host.defaults[Miscellaneous.kMPHTTPETagHeaderKey] as? String, "etag-2")
        XCTAssertEqual(host.defaults[Miscellaneous.kMPConfigMaxAgeHeaderKey] as? NSNumber, 600)
        XCTAssertEqual(provisionedAge ?? 0, 100, accuracy: 5)
    }

    func testANotModifiedResponseKeepsTheCachedConfigurationAndRestartsItsAge() {
        host.defaults.setConfiguration(["dt": "ac", "id": 7], eTag: "etag-1", requestTimestamp: 0, currentAge: 0, maxAge: nil)
        let connector = FakeConnector()
        connector.respond(304, headers: ["Cache-Control": "max-age=30", "Age": "5"])

        XCTAssertEqual(requestConfig(connector), true)
        XCTAssertEqual(host.defaults.getConfiguration()?["id"] as? Int, 7)
        XCTAssertEqual(host.defaults[Miscellaneous.kMPHTTPETagHeaderKey] as? String, "etag-1")
        XCTAssertEqual(host.defaults[Miscellaneous.kMPConfigMaxAgeHeaderKey] as? NSNumber, 30)
        XCTAssertEqual(provisionedAge ?? 0, 5, accuracy: 5)
    }

    func testAConfigResponseThatIsNotAConfigObjectFailsWithTheResponseCodeItLogs() {
        var messages: [String] = []
        host.log = MPLog(logLevel: .error)
        host.log?.customLogger = { messages.append($0) }
        let unparsed = "could not parse response or wrong message type (responseCode: "
        let cases: [(response: (status: Int, body: Data?), logged: String)] = [
            ((200, nil), "no data received (responseCode: 200)"),
            ((200, Data()), unparsed + "200)"),
            ((200, Data("{".utf8)), unparsed + "200)"),
            ((200, json(["id": 1])), unparsed + "200)"),
            ((200, json(["dt": "xx"])), unparsed + "200)"),
            ((500, json(["dt": "ac"])), unparsed + "500)"),
            // Bodies that parsed but are not an object, or have a non-string message type, fail as a 204.
            ((200, json([["dt": "ac"]])), unparsed + "204)"),
            ((200, json(["dt": 1])), unparsed + "204)"),
            ((200, json(["dt": NSNull()])), unparsed + "204)")
        ]

        for (response, logged) in cases {
            messages = []
            let connector = FakeConnector()
            connector.respond(response.status, body: response.body, headers: ["ETag": "etag-3"])

            XCTAssertEqual(requestConfig(connector), false, logged)
            XCTAssertEqual(messages.count, 1, logged)
            XCTAssertTrue(messages.first?.contains(logged) == true, "\(messages) lacks \(logged)")
        }
        XCTAssertNil(host.defaults.getConfiguration())
    }

    func testAConfigRequestWhoseURLCannotBeBuiltSendsNothingAndFails() {
        host.routedHost = "not a host"
        let connector = FakeConnector()
        connector.respond(200, body: json(["dt": "ac", "id": 42]), headers: ["ETag": "etag-4"])

        XCTAssertNil(network.configURL)
        XCTAssertEqual(requestConfig(connector), false)
        XCTAssertEqual(connector.requestedURLs, [])
        XCTAssertNil(host.defaults.getConfiguration())
    }

    func testAConfigResponseWithoutAnETagSucceedsButIsNeitherAppliedNorCached() {
        let connector = FakeConnector()
        connector.respond(200, body: json(["dt": "ac", "id": 42, "cms": [["id": 1]]]), headers: ["Cache-Control": "max-age=600"])

        XCTAssertEqual(requestConfig(connector), true)
        XCTAssertEqual(connector.requestedURLs, [network.configURL?.url])
        XCTAssertNil(host.configConnector.configureCustomModulesCustomModuleSettingsParams)
        XCTAssertNil(host.defaults.getConfiguration())
        XCTAssertNil(host.defaults[Miscellaneous.kMPHTTPETagHeaderKey])
        XCTAssertNil(host.defaults[Miscellaneous.kMPConfigMaxAgeHeaderKey])
    }

    func testAudienceIDsArePassedOnAndNoneIsNil() {
        let connector = FakeConnector()
        MPNetworkCommunicationPRIVATE.connectorFactory = FakeConnectorFactory(connector)
        defer { MPNetworkCommunicationPRIVATE.connectorFactory = nil }
        var success: Bool?
        var audiences: [Any]?
        var error: Error?
        func request() {
            success = nil
            network.requestAudiences { success = $0; audiences = $1; error = $2 }
        }

        connector.respond(200, body: json(["audience_memberships": [["audience_id": 1], ["audience_id": 2]]]))
        request()
        XCTAssertEqual(success, true)
        XCTAssertEqual(audiences as? [NSNumber], [1, 2])
        XCTAssertNil(error)
        XCTAssertEqual(connector.requestedURLs, [network.audienceURL?.url])

        connector.respond(200, body: json(["audience_memberships": []]))
        request()
        XCTAssertEqual(success, true)
        XCTAssertNil(audiences)

        connector.respond(403)
        request()
        XCTAssertEqual(success, false)
        XCTAssertNil(audiences)
        XCTAssertEqual((error as NSError?)?.code, 403)
    }

    // MARK: - Uploads

    private var logged: [String] = []

    private func captureLogs() {
        host.log = MPLog(logLevel: .verbose)
        host.log?.customLogger = { [unowned self] in logged.append($0) }
    }

    private func respondToEveryRequest(
        _ statusCode: Int,
        body: Data? = nil,
        headers: [String: String] = [:],
        error: NSError? = nil
    ) -> FakeConnector {
        let connector = FakeConnector()
        connector.respond(statusCode, body: body, headers: headers, error: error)
        MPNetworkCommunicationPRIVATE.connectorFactory = FakeConnectorFactory(connector)
        return connector
    }

    private func makeUpload(type: UInt = 0, data: Data? = nil) -> MPUploadPRIVATE {
        MPUploadPRIVATE(
            sessionId: nil, uploadId: 1, uuid: "upload-id", uploadData: data ?? json(["di": ["aid": "ad-id"]]),
            timestamp: 0, uploadType: type, dataPlanId: nil, dataPlanVersion: nil, uploadSettings: host.uploadSettings
        )
    }

    private func deviceInfo(_ data: Data?) -> [String: Any]? {
        data.flatMap { (try? JSONSerialization.jsonObject(with: $0)) as? [String: Any] }?["di"] as? [String: Any]
    }

    func testABatchIsSentGzippedWithItsOwnSecretAndTheATTStateAppliedThenDeletedAndLoggedToKits() throws {
        let connector = respondToEveryRequest(202)
        let upload = makeUpload()

        XCTAssertFalse(network.performMessageUpload(upload))
        let plain = try XCTUnwrap(connector.posts.first)
        XCTAssertEqual(plain.url, network.eventURL(for: upload)?.url)
        XCTAssertEqual(plain.secret, "upload-secret")
        XCTAssertEqual(MPZipPRIVATE.decompressedData(from: plain.params), upload.uploadData)
        XCTAssertEqual(plain.message, upload.serializedString())

        host.machine.attAuthorizationStatus = NSNumber(value: MPATTAuthorizationStatusSwift.denied.rawValue)
        host.machine.attAuthorizationTimestamp = 1234
        XCTAssertFalse(network.performMessageUpload(upload))
        let withATT = try XCTUnwrap(connector.posts.last)
        let sent = MPZipPRIVATE.decompressedData(from: withATT.params)
        XCTAssertEqual(deviceInfo(sent)?["atts"] as? String, "denied")
        XCTAssertEqual(deviceInfo(sent)?["attt"] as? NSNumber, 1234)
        XCTAssertNil(deviceInfo(sent)?["aid"])
        XCTAssertEqual(withATT.message, sent.flatMap { String(data: $0, encoding: .utf8) })

        XCTAssertEqual(connector.posts.count, 2)
        XCTAssertTrue(host.deletedUploads.count == 2 && host.deletedUploads.allSatisfy { $0 === upload })
        XCTAssertEqual(host.kitBatches, [plain.message, withATT.message].compactMap { $0 })
    }

    func testAHeldBackBatchIsNotSentAndOneThatCannotBeCompressedIsDeleted() {
        let connector = respondToEveryRequest(202)
        let empty = makeUpload(data: Data())
        XCTAssertFalse(network.performMessageUpload(empty))
        XCTAssertTrue(host.deletedUploads.count == 1 && host.deletedUploads[0] === empty)

        host.machine.setMinUploadDate(Date(timeIntervalSinceNow: 60), uploadType: 0)
        XCTAssertTrue(network.performMessageUpload(makeUpload()))
        XCTAssertEqual(connector.posts.count, 0)
        XCTAssertEqual(host.deletedUploads.count, 1)
    }

    func testOnlyAResponseHeaderBodyIsMergedAndABodyThatIsNotAnObjectWithAStringTypeIsLoggedAsAnError() {
        let cases: [(response: (status: Int, body: Data), outcome: (merged: Bool, logged: String?))] = [
            ((200, json(["dt": "rh", "ci": [:]])), (true, "Upload complete")),
            ((200, json(["dt": "xx"])), (false, "Upload complete")),
            ((200, json(["id": 1])), (false, "Upload complete")),
            ((200, Data("{".utf8)), (false, "Upload complete")),
            ((500, json(["dt": "rh"])), (false, nil)),
            // Bodies that parsed but are not an object, or have a non-string message type.
            ((200, json([["dt": "rh"]])), (false, "Upload error: response is not a JSON object")),
            ((200, json(["dt": 1])), (false, "Upload error: response message type is not a string")),
            ((200, json(["dt": NSNull()])), (false, "Upload error: response message type is not a string"))
        ]
        captureLogs()
        for ((status, body), (merged, expected)) in cases {
            logged = []
            let mergeCount = host.mergedResponses.count
            _ = respondToEveryRequest(status, body: body)
            _ = network.performMessageUpload(makeUpload())

            let outcome = logged.filter { $0.contains("Upload complete") || $0.contains("Upload error") }
            XCTAssertEqual(host.mergedResponses.count - mergeCount, merged ? 1 : 0, "\(status) \(body)")
            XCTAssertEqual(outcome.count, expected == nil ? 0 : 1, "\(outcome)")
            XCTAssertTrue(expected.map { outcome.first?.contains($0) == true } ?? true, "\(outcome)")
        }
    }

    func testAnUnavailableServerHoldsBatchesBackForItsRetryAfter() {
        // Lower case, as HTTP/2 sends header names: the lookup must ignore case.
        _ = respondToEveryRequest(503, headers: ["retry-after": "120"])

        XCTAssertTrue(network.performMessageUpload(makeUpload()))
        XCTAssertEqual(host.machine.minUploadDate(forUploadType: 0).timeIntervalSinceNow, 120, accuracy: 5)
        XCTAssertLessThan(host.machine.minUploadDate(forUploadType: 1).timeIntervalSinceNow, 0)
        XCTAssertTrue(host.deletedUploads.isEmpty)
    }

    func testAnAliasRequestIsSentUncompressedAndDeletedUnlessItIsToBeSentAgain() throws {
        captureLogs()
        let alias = makeUpload(type: 1)
        let connector = respondToEveryRequest(202)
        XCTAssertFalse(network.performAliasUpload(alias))
        let post = try XCTUnwrap(connector.posts.first)
        XCTAssertEqual(post.url, network.aliasURL(for: alias)?.url)
        XCTAssertEqual(post.params, alias.uploadData)
        XCTAssertEqual(post.message, alias.serializedString())
        XCTAssertEqual(post.secret, "upload-secret")

        connector.respond(400)
        XCTAssertFalse(network.performAliasUpload(alias))
        XCTAssertEqual(host.deletedUploads.count, 2)

        connector.respond(500)
        XCTAssertTrue(network.performAliasUpload(alias))
        XCTAssertLessThan(host.machine.minUploadDate(forUploadType: 1).timeIntervalSinceNow, 0)

        connector.respond(429, headers: ["retry-after": "60"])
        XCTAssertTrue(network.performAliasUpload(alias))
        XCTAssertEqual(host.machine.minUploadDate(forUploadType: 1).timeIntervalSinceNow, 60, accuracy: 5)

        XCTAssertTrue(network.performAliasUpload(alias), "A held-back alias request is not sent")
        XCTAssertEqual(connector.posts.count, 4)

        host.machine.setMinUploadDate(.distantPast, uploadType: 1)
        MPTransportErrorDetector.resetTransportErrorCounter()
        connector.respond(0, error: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut))
        XCTAssertTrue(network.performAliasUpload(alias))
        XCTAssertEqual(host.machine.minUploadDate(forUploadType: 1).timeIntervalSinceNow, 5, accuracy: 2)
        XCTAssertTrue(logged.contains("mParticle -> Throttling alias requests after transport error."))
        XCTAssertEqual(host.deletedUploads.count, 2)
        XCTAssertLessThan(host.machine.minUploadDate(forUploadType: 0).timeIntervalSinceNow, 0)
    }

    func testUploadsAreSentInOrderUntilOneIsToBeSentAgainAndTheCompletionRunsOnceBeforeReturning() {
        let connector = respondToEveryRequest(202)
        let message = makeUpload()
        let alias = makeUpload(type: 1)
        var completions = 0

        network.upload([message, makeUpload(type: 7), alias]) { completions += 1 }
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(
            connector.posts.map(\.url),
            [network.eventURL(for: message)?.url, network.aliasURL(for: alias)?.url].compactMap { $0 }
        )
        XCTAssertEqual(host.mainHops.first, "sync")

        connector.respond(503)
        network.upload([message, alias]) { completions += 1 }
        XCTAssertEqual(completions, 2)
        XCTAssertEqual(connector.posts.count, 3)
    }

    // MARK: - Identity requests

    private static let knownIdentities: NSDictionary = ["known_identities": ["email": "user@example.com"]]
    private let mpidBody = Data(#"{"mpid":"42"}"#.utf8)

    /// What one identity request completed with.
    private struct IdentityOutcome {
        let response: MPIdentityHTTPBaseSuccessResponse?
        let error: NSError?
    }

    /// Sends an identity request, checking its completion ran exactly once before the call returned.
    private func identityRequest(
        _ endpoint: MPEndpoint = .identityIdentify,
        blocking: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> IdentityOutcome? {
        var outcomes: [IdentityOutcome] = []
        network.identityRequest(to: endpoint, requestDictionary: Self.knownIdentities, blockOtherRequests: blocking) {
            outcomes.append(IdentityOutcome(response: $0, error: $1 as NSError?))
        }
        XCTAssertEqual(outcomes.count, 1, "The completion runs once, before the request returns", file: file, line: line)
        return outcomes.first
    }

    private func captureErrorLogs() {
        host.log = MPLog(logLevel: .error)
        host.log?.customLogger = { [unowned self] in logged.append($0) }
    }

    private func identityCache() -> MPIdentityCaching {
        MPIdentityCaching(userDefaults: host.defaults, logger: MPLog(logLevel: .none))
    }

    func testARequestInFlightAndThenAnOptOutFailUnsentWithoutTakingTheFlag() {
        captureLogs()
        let connector = respondToEveryRequest(200, body: mpidBody)
        network.identifying = true
        host.isOptedOut = true

        let inFlight = identityRequest()?.error
        XCTAssertEqual(inFlight?.domain, "mParticle Identity Error Domain")
        XCTAssertEqual(inFlight?.code, 1)
        XCTAssertEqual(inFlight?.userInfo["mParticle Identity Error"] as? String, "Identity API request in progress.")
        XCTAssertTrue(network.identifying, "The request in flight still holds the flag")
        XCTAssertFalse(host.calls.contains("optOut"), "The in-flight check comes first")

        network.identifying = false
        let optedOut = identityRequest()?.error
        XCTAssertEqual(optedOut?.domain, "mParticle Identity Error Domain")
        XCTAssertEqual(optedOut?.code, 5)
        XCTAssertEqual(optedOut?.userInfo["mParticle Identity Error"] as? String, "Opt Out Enabled.")
        XCTAssertFalse(network.identifying, "An opted-out request never takes the flag")

        XCTAssertEqual(connector.posts.count, 0)
        XCTAssertEqual(logged, [
            "mParticle -> Identity API request blocked - another identity request is already in progress",
            "mParticle -> Identity API request blocked - SDK is opted out"
        ])
    }

    func testOnlyABlockingRequestHoldsTheFlagWhileItIsSent() {
        let connector = respondToEveryRequest(200, body: mpidBody)
        var flagWhileSent: [Bool] = []
        connector.onPost = { [unowned self] in flagWhileSent.append(network.identifying) }

        XCTAssertNotNil(identityRequest(blocking: true)?.response)
        XCTAssertFalse(network.identifying)
        XCTAssertNotNil(identityRequest(blocking: false)?.response)
        XCTAssertFalse(network.identifying)
        XCTAssertEqual(flagWhileSent, [true, false])
    }

    func testAModifyRequestSucceedsWithAModifyResponseAndEachEndpointIsPostedToItsOwnURL() throws {
        let connector = respondToEveryRequest(202, body: Data(#"{"mpid":"42","change_results":[]}"#.utf8))
        let cases: [(endpoint: MPEndpoint, url: URL?)] = [
            (.identityIdentify, network.identifyURL?.url),
            (.identityLogin, network.loginURL?.url),
            (.identityLogout, network.logoutURL?.url),
            (.identityModify, network.modifyURL?.url)
        ]
        for (endpoint, url) in cases {
            let response = identityRequest(endpoint)?.response
            XCTAssertEqual(
                response.map { String(describing: type(of: $0)) },
                endpoint == .identityModify ? "MPIdentityHTTPModifySuccessResponse" : "MPIdentityHTTPSuccessResponse"
            )
            XCTAssertEqual((response as? MPIdentityHTTPSuccessResponse)?.mpid, 42)
            let post = try XCTUnwrap(connector.posts.last)
            XCTAssertEqual(post.url, url)
            XCTAssertNil(post.message)
            XCTAssertNil(post.secret)
            let body = post.params.flatMap { try? JSONSerialization.jsonObject(with: $0) }
            XCTAssertEqual(body as? NSDictionary, Self.knownIdentities)
        }
        XCTAssertEqual(connector.posts.count, 4)
    }

    func testAUsableCachedResponseAnswersUnsentAndAnUnusableOneIsAMissLoggedAsAnError() {
        host.machine.enableIdentityCaching = true
        captureErrorLogs()
        let connector = respondToEveryRequest(200, body: mpidBody)
        let unusable = "mParticle -> Cached identity response was unusable: "
        // Each cached body, with the error an unusable one is logged with before the request is sent.
        let cases: [(cached: Data, logged: String?)] = [
            (Data(#"{"mpid":"7"}"#.utf8), nil),
            (Data("[1,2]".utf8), unusable + "body was not a JSON object"),
            (Data("{".utf8), unusable)
        ]
        for (cached, expected) in cases {
            let sent = expected != nil
            logged = []
            identityCache().clearAllCache()
            identityCache().cacheIdentityResponse(
                MPIdentityCachedResponse(bodyData: cached, statusCode: 200, expires: Date(timeIntervalSinceNow: 3600)),
                endpoint: .identityIdentify, requestDictionary: Self.knownIdentities
            )
            let posts = connector.posts.count
            let mainHops = host.mainHops.count

            let response = identityRequest()?.response as? MPIdentityHTTPSuccessResponse
            XCTAssertEqual(response?.mpid, sent ? 42 : 7)
            XCTAssertEqual(connector.posts.count - posts, sent ? 1 : 0)
            XCTAssertEqual(host.mainHops.count > mainHops, sent, "A background task is begun only to send")
            XCTAssertEqual(logged.count, expected == nil ? 0 : 1, "\(logged)")
            XCTAssertTrue(expected.map { logged.first?.hasPrefix($0) == true } ?? true, "\(logged)")
        }
        XCTAssertFalse(network.identifying)
    }

    func testAResponseIsCachedOnlyWhileCachingIsOnAndItsMaxAgeHeaderIsPositive() {
        let cache = identityCache()
        cache.clearAllCache()
        host.machine.enableIdentityCaching = true
        // Lower case, as HTTP/2 sends header names: the lookup must ignore case.
        for maxAge in [nil, "0", "-60", "soon"] {
            _ = respondToEveryRequest(200, body: mpidBody, headers: maxAge.map { ["x-mp-max-age": $0] } ?? [:])
            XCTAssertNotNil(identityRequest()?.response)
            XCTAssertNil(cache.getCache(), maxAge ?? "no header")
        }

        _ = respondToEveryRequest(200, body: mpidBody, headers: ["x-mp-max-age": "3600"])
        host.machine.enableIdentityCaching = false
        XCTAssertNotNil(identityRequest()?.response)
        XCTAssertNil(cache.getCache(), "Nothing is cached while caching is off")

        host.machine.enableIdentityCaching = true
        XCTAssertNotNil(identityRequest()?.response)
        let cached = cache.getCachedIdentityResponse(for: .identityIdentify, requestDictionary: Self.knownIdentities)
        XCTAssertEqual(cached?.bodyData, mpidBody)
        XCTAssertEqual(cached?.statusCode, 200)
        XCTAssertEqual(cached?.expires.timeIntervalSinceNow ?? 0, 3600, accuracy: 60)
    }

    func testABodyThatIsNotAnObjectIsNotCachedAndFailsAsAnUnknownError() {
        let cache = identityCache()
        cache.clearAllCache()
        host.machine.enableIdentityCaching = true
        captureErrorLogs()
        _ = respondToEveryRequest(200, body: Data("[1,2]".utf8), headers: ["x-mp-max-age": "3600"])

        let error = identityRequest()?.error
        XCTAssertEqual(error?.domain, "client-side")
        XCTAssertEqual(error?.code, 0)
        XCTAssertEqual(error?.localizedDescription, "Identity response body was not a JSON object.")
        XCTAssertNil(error?.userInfo[NSUnderlyingErrorKey])
        XCTAssertNil(cache.getCache())
        XCTAssertEqual(logged, ["mParticle -> Identity request failed - response body was not a JSON object"])
        XCTAssertFalse(network.identifying)
    }

    func testEachFailureIsMappedToItsCodeAndLoggedOnlyWhenACompletionWaits() {
        captureErrorLogs()
        let noConnection = NSError(domain: "MPConnector", code: 1)
        let ssl = NSError(domain: NSURLErrorDomain, code: NSURLErrorSecureConnectionFailed)
        let other = NSError(domain: "other", code: 7)
        let failed = "mParticle -> Identity request failed - "
        struct Failure {
            let status: Int
            var body: Data?
            var transportError: NSError?
            let domain: String
            let code: Int
            var message: String?
            let logged: String
        }
        let cases = [
            Failure(status: 0, transportError: noConnection, domain: "client-side", code: 3,
                    message: "Device has no network connectivity.", logged: "no network connectivity"),
            Failure(status: 0, transportError: ssl, domain: "client-side", code: 4,
                    message: "Failed to establish SSL connection.",
                    logged: "SSL error: \(ssl.localizedDescription) (code: -1200)"),
            Failure(status: 0, transportError: other, domain: "client-side", code: 0,
                    message: "An unknown client-side error has occured",
                    logged: "unknown error: \(other.localizedDescription) (domain: other, code: 7)"),
            Failure(status: 500, body: mpidBody, domain: "server", code: 500, logged: "HTTP error (code: 500)"),
            Failure(status: 200, body: Data(), domain: "server", code: 200, logged: "HTTP error (code: 200)"),
            Failure(status: 200, body: Data("{".utf8), domain: "server", code: 200, logged: "HTTP error (code: 200)")
        ]
        for failure in cases {
            logged = []
            _ = respondToEveryRequest(failure.status, body: failure.body, error: failure.transportError)

            let error = identityRequest()?.error
            XCTAssertEqual(error?.domain, failure.domain, failure.logged)
            XCTAssertEqual(error?.code, failure.code, failure.logged)
            if let message = failure.message {
                XCTAssertEqual(error?.localizedDescription, message)
                XCTAssertTrue((error?.userInfo[NSUnderlyingErrorKey] as? NSError) === failure.transportError, failure.logged)
            }
            XCTAssertEqual(logged.last, failed + failure.logged)
            XCTAssertFalse(network.identifying)
        }

        logged = []
        _ = respondToEveryRequest(500)
        network.identityRequest(
            to: .identityIdentify, requestDictionary: Self.knownIdentities, blockOtherRequests: true, completion: nil
        )
        XCTAssertEqual(logged, [])
        XCTAssertFalse(network.identifying)
    }

    func testAnIdentityRequestWhoseURLCannotBeBuiltSendsNothingAndFailsAsAnHTTPError() {
        host.routedHost = "not a host"
        captureErrorLogs()
        let connector = respondToEveryRequest(200, body: mpidBody)

        XCTAssertNil(network.identifyURL)
        let error = identityRequest()?.error
        XCTAssertEqual(error?.domain, "server")
        XCTAssertEqual(error?.code, 0)
        XCTAssertEqual(connector.posts.count, 0)
        XCTAssertEqual(logged, ["mParticle -> Identity request failed - HTTP error (code: 0)"])
        XCTAssertFalse(network.identifying)
    }

    // MARK: - Logging

    func testMessagesHoldingABatchOrABodyAreBuiltOnlyWhenVerboseLoggingWouldPrintThem() {
        let log = MPVerboseRecordingLog(logLevel: .debug)
        host.log = log
        let batch = makeUpload()
        let alias = makeUpload(type: 1)
        let expected = [
            "Upload complete: \(batch.serializedString() ?? "(null)")\n",
            "Alias request:\nURL: \(network.aliasURL(for: alias).map { "\($0.url)" } ?? "(null)") "
                + "\nBody:\(alias.serializedString() ?? "(null)")",
            #"Alias response:\#n{"dt":"xx"}"#,
            "Identity request:\nURL: \(network.identifyURL.map { "\($0.url)" } ?? "(null)") "
                + #"\#nBody:{"known_identities":{"email":"user@example.com"}}"#,
            #"Identity response:\#n{"mpid":"42"}"#
        ]
        func send() {
            _ = respondToEveryRequest(202, body: json(["dt": "xx"]))
            _ = network.performMessageUpload(batch)
            _ = network.performAliasUpload(alias)
            _ = respondToEveryRequest(200, body: mpidBody)
            _ = identityRequest()
        }

        send()
        XCTAssertEqual(log.verboseMessages.filter(expected.contains), [], "Built while verbose logging is off")

        log.logLevel = .verbose
        send()
        for message in expected {
            XCTAssertTrue(log.verboseMessages.contains(message), "\(message) not in \(log.verboseMessages)")
        }
    }

    // MARK: - Identity entry points

    // The expected bodies are the wire format for the same input, with the fake host's SDK version
    // and API key, and without the request ID and timestamp, which are checked on their own.

    private static let capturedIdentifyBody = #"""
    {"client_sdk":{"platform":"ios","sdk_vendor":"mparticle","sdk_version":"0.0.0-test"},"environment":"development",\#
    "known_identities":{"customerid":"cust-1","device_application_stamp":"stamp-fixture","email":"user@example.com",\#
    "google":"google-id","ios_idfa":"idfa-fixture","ios_idfv":"vendor-id-fixture","other":null,"push_token":"0aff"},\#
    "previous_mpid":"42"}
    """#
    private static let capturedDeniedIdentifyBody = #"""
    {"client_sdk":{"platform":"ios","sdk_vendor":"mparticle","sdk_version":"0.0.0-test"},"environment":"development",\#
    "known_identities":{"customerid":"cust-1","device_application_stamp":"stamp-fixture","email":"user@example.com",\#
    "google":"google-id","ios_idfv":"vendor-id-fixture","other":null,"push_token":"0aff"},"previous_mpid":"42"}
    """#
    private static let capturedEmptyIdentifyBody = #"""
    {"client_sdk":{"platform":"ios","sdk_vendor":"mparticle","sdk_version":"0.0.0-test"},"environment":"development",\#
    "known_identities":{"device_application_stamp":"stamp-fixture","ios_idfv":"vendor-id-fixture","push_token":"0aff"},\#
    "previous_mpid":"42"}
    """#
    private static let capturedModifyBody = #"""
    {"client_sdk":{"platform":"ios","sdk_vendor":"mparticle","sdk_version":"0.0.0-test"},"environment":"development",\#
    "identity_changes":[{"identity_type":"email","new_value":"new@example.com","old_value":"old@example.com"},\#
    {"identity_type":"google","new_value":"google-new","old_value":null},\#
    {"identity_type":"yahoo","new_value":null,"old_value":null},\#
    {"identity_type":"other3","new_value":null,"old_value":"removed-value"}]}
    """#
    private static let capturedDeviceIDBody = #"""
    {"client_sdk":{"platform":"ios","sdk_vendor":"mparticle","sdk_version":"0.0.0-test"},"environment":"development",\#
    "identity_changes":[{"identity_type":"push_token","new_value":"0aff","old_value":"0102"}]}
    """#
    private static let capturedAliasBody = #"""
    {"api_key":"us2-test","data":{"destination_mpid":2,"device_application_stamp":"stamp-fixture",\#
    "end_unixtime_ms":200250,"source_mpid":1,"start_unixtime_ms":100500},"environment":"development",\#
    "request_type":"alias"}
    """#
    private static let attLog = "mParticle -> The IDFA was supplied but the App Tracking Transparency Status not set "
        + "with [[MParticle sharedInstance] setATTStatus:withATTStatusTimestampMillis:]"

    private static func identities(_ values: [MPIdentitySwift: Any]) -> NSDictionary {
        let dictionary = NSMutableDictionary()
        for (type, value) in values {
            dictionary[NSNumber(value: type.rawValue)] = value
        }
        return dictionary
    }

    /// The identities of the captured identify, login and logout requests.
    private static let requestIdentities = identities([
        .customerId: "cust-1", .email: "user@example.com", .iosAdvertiserId: "idfa-fixture",
        .other: NSNull(), .google: "google-id"
    ])

    /// The SDK state the bodies were captured in.
    private func useCapturedState() {
        host.currentUserId = 42
        host.vendorIdValue = "vendor-id-fixture"
        host.deviceTokenValue = Data([0x0A, 0xFF])
        authorizeTracking()
        // Consumer info reads the stamp from the shared user defaults.
        let shared = MPUserDefaults.standardUserDefaults(connector: MPUserDefaultsConnectorMock())
        let stamp = shared["dast"]
        shared["dast"] = "stamp-fixture"
        let environment = MPStateMachinePRIVATE.environment()
        MPStateMachinePRIVATE.setEnvironment(1)
        addTeardownBlock {
            shared["dast"] = stamp
            MPStateMachinePRIVATE.setEnvironment(environment)
        }
    }

    /// `json` as this platform sends it: tvOS reports its own platform and has no push token.
    private func expectedBody(_ json: String) -> NSMutableDictionary? {
        let body = (try? JSONSerialization.jsonObject(with: Data(json.utf8), options: .mutableContainers)) as? NSMutableDictionary
        #if os(tvOS)
        (body?["client_sdk"] as? NSMutableDictionary)?["platform"] = "tvos"
        (body?["known_identities"] as? NSMutableDictionary)?.removeObject(forKey: "push_token")
        #endif
        return body
    }

    /// A request body without its request ID and timestamp, once those are checked.
    private func stripped(_ body: NSDictionary?, file: StaticString = #filePath, line: UInt = #line) -> NSMutableDictionary? {
        guard let body = body?.mutableCopy() as? NSMutableDictionary else {
            XCTFail("No body", file: file, line: line)
            return nil
        }
        XCTAssertNotNil((body["request_id"] as? String).flatMap(UUID.init(uuidString:)), file: file, line: line)
        if body["request_type"] == nil {
            let timestamp = (body["request_timestamp_ms"] as? NSNumber)?.doubleValue ?? 0
            XCTAssertEqual(timestamp, Date().timeIntervalSince1970 * 1000, accuracy: 60000, file: file, line: line)
        }
        body.removeObjects(forKeys: ["request_id", "request_timestamp_ms"])
        return body
    }

    private func sentBody(
        _ post: MPNetworkFakePost?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> NSMutableDictionary? {
        let body = post?.params.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? NSDictionary
        return stripped(body, file: file, line: line)
    }

    func testIdentifyLoginAndLogoutSendTheCapturedBodyToTheirOwnURLWhileBlockingTheOthers() throws {
        useCapturedState()
        let connector = respondToEveryRequest(200, body: mpidBody)
        var flagWhileSent: [Bool] = []
        connector.onPost = { [unowned self] in flagWhileSent.append(network.identifying) }
        typealias EntryPoint = (NSDictionary?, ((MPIdentityHTTPBaseSuccessResponse?, Error?) -> Void)?) -> Void
        let cases: [(entryPoint: EntryPoint, url: URL?)] = [
            (network.identify, network.identifyURL?.url),
            (network.login, network.loginURL?.url),
            (network.logout, network.logoutURL?.url)
        ]
        for (entryPoint, url) in cases {
            var responses: [MPIdentityHTTPBaseSuccessResponse?] = []
            entryPoint(Self.requestIdentities) { response, _ in responses.append(response) }
            XCTAssertEqual(responses.count, 1, "The completion runs once, before the call returns")
            let response = try XCTUnwrap(responses.first ?? nil)
            XCTAssertTrue(type(of: response) == MPIdentityHTTPSuccessResponse.self)
            let post = try XCTUnwrap(connector.posts.last)
            XCTAssertEqual(post.url, url)
            XCTAssertEqual(sentBody(post), expectedBody(Self.capturedIdentifyBody))
        }
        XCTAssertEqual(flagWhileSent, [true, true, true])
        XCTAssertFalse(network.identifying)
    }

    func testAnIdentifyBodyLeavesOutWhatTheUserAndDeviceDoNotHave() throws {
        useCapturedState()
        let connector = respondToEveryRequest(200, body: mpidBody)

        network.identify(nil, completion: nil)
        XCTAssertEqual(sentBody(connector.posts.last), expectedBody(Self.capturedEmptyIdentifyBody))

        host.machine.attAuthorizationStatus = NSNumber(value: MPATTAuthorizationStatusSwift.denied.rawValue)
        network.identify(Self.requestIdentities, completion: nil)
        XCTAssertEqual(sentBody(connector.posts.last), expectedBody(Self.capturedDeniedIdentifyBody))

        // No mpid yet, no vendor ID, and an app extension, in production.
        host.currentUserId = 0
        host.vendorIdValue = nil
        host.inAppExtension = true
        MPStateMachinePRIVATE.setEnvironment(2)
        network.identify(nil, completion: nil)
        let body = try XCTUnwrap(sentBody(connector.posts.last))
        XCTAssertNil(body["previous_mpid"])
        XCTAssertEqual(body["environment"] as? String, "production")
        XCTAssertEqual(body["known_identities"] as? NSDictionary, ["device_application_stamp": "stamp-fixture"])

        host.inAppExtension = false
        host.deviceTokenValue = nil
        network.identify(nil, completion: nil)
        XCTAssertEqual(
            sentBody(connector.posts.last)?["known_identities"] as? NSDictionary,
            ["device_application_stamp": "stamp-fixture"]
        )
    }

    func testAnIDFAIsLoggedAtDebugLevelOnlyWhileTheATTStatusIsUnset() {
        _ = respondToEveryRequest(200, body: mpidBody)
        host.log = MPLog(logLevel: .debug)
        host.log?.customLogger = { [unowned self] in logged.append($0) }

        network.identify(Self.requestIdentities, completion: nil)
        network.login(Self.identities([.iosAdvertiserId: NSNull()]), completion: nil)
        network.logout(Self.identities([.email: "user@example.com"]), completion: nil)
        network.modify(Self.identities([.iosAdvertiserId: "idfa-fixture"]), completion: nil)
        XCTAssertEqual(logged, [Self.attLog, Self.attLog, Self.attLog], "An IDFA, even a removed one, and only an IDFA")

        logged = []
        host.machine.attAuthorizationStatus = NSNumber(value: MPATTAuthorizationStatusSwift.denied.rawValue)
        network.identify(Self.requestIdentities, completion: nil)
        network.modify(Self.identities([.iosAdvertiserId: "idfa-fixture"]), completion: nil)
        XCTAssertEqual(logged, [])
    }

    private static func sortedByType(_ changes: [NSDictionary]) -> [NSDictionary] {
        changes.sorted { ($0["identity_type"] as? String ?? "") < ($1["identity_type"] as? String ?? "") }
    }

    func testModifySendsOnlyTheChangedAndRemovedIdentitiesInTheirOrderWhileBlockingTheOthers() throws {
        useCapturedState()
        host.currentIdentities = Self.identities([
            .customerId: "cust-1", .email: "old@example.com", .other3: "removed-value", .mobileNumber: "555"
        ])
        let connector = respondToEveryRequest(200, body: Data(#"{"mpid":"42","change_results":[]}"#.utf8))
        var flagWhileSent: [Bool] = []
        connector.onPost = { [unowned self] in flagWhileSent.append(network.identifying) }
        let modified = Self.identities([
            .customerId: "cust-1", .email: "new@example.com", .other3: NSNull(), .google: "google-new", .yahoo: NSNull()
        ])

        var responses: [MPIdentityHTTPBaseSuccessResponse?] = []
        network.modify(modified) { response, _ in responses.append(response) }

        XCTAssertEqual(responses.count, 1)
        XCTAssertTrue(responses.first??.isKind(of: MPIdentityHTTPModifySuccessResponse.self) == true)
        let post = try XCTUnwrap(connector.posts.last)
        XCTAssertEqual(post.url, network.modifyURL?.url)
        XCTAssertEqual(flagWhileSent, [true])
        let body = try XCTUnwrap(sentBody(post))
        let expected = try XCTUnwrap(expectedBody(Self.capturedModifyBody))
        let changes = try XCTUnwrap(body["identity_changes"] as? [NSDictionary])
        // The changes follow the order the identities enumerate in, which a literal does not fix.
        var order: [String] = []
        modified.enumerateKeysAndObjects { key, _, _ in
            let type = MPIdentityHTTPIdentitiesPRIVATE.string(forIdentityType: (key as? NSNumber)?.intValue ?? -1)
            if let type, changes.contains(where: { $0["identity_type"] as? String == type }) {
                order.append(type)
            }
        }
        XCTAssertEqual(changes.map { $0["identity_type"] as? String }, order)
        body["identity_changes"] = Self.sortedByType(changes)
        expected["identity_changes"] = Self.sortedByType(expected["identity_changes"] as? [NSDictionary] ?? [])
        XCTAssertEqual(body, expected)
    }

    func testModifyWithNothingChangedSucceedsAtOnceUnsent() {
        host.currentIdentities = Self.identities([.customerId: "cust-1", .mobileNumber: "555"])
        let connector = respondToEveryRequest(200, body: mpidBody)
        for unchanged in [nil, Self.identities([:]), Self.identities([.customerId: "cust-1", .mobileNumber: "555"])] {
            var outcomes: [(MPIdentityHTTPBaseSuccessResponse?, Error?)] = []
            network.modify(unchanged) { outcomes.append(($0, $1)) }
            XCTAssertEqual(outcomes.count, 1, "\(String(describing: unchanged))")
            XCTAssertTrue(outcomes.first?.0?.isKind(of: MPIdentityHTTPModifySuccessResponse.self) == true)
            XCTAssertNil(outcomes.first?.1)
        }
        XCTAssertEqual(connector.posts.count, 0)
    }

    func testModifyDeviceIDSendsOneChangeWithoutBlockingAndStillLogsAFailure() throws {
        useCapturedState()
        captureErrorLogs()
        let connector = respondToEveryRequest(500)
        var flagWhileSent: [Bool] = []
        connector.onPost = { [unowned self] in flagWhileSent.append(network.identifying) }

        network.modifyDeviceID("push_token", value: "0aff", oldValue: "0102")

        let post = try XCTUnwrap(connector.posts.last)
        XCTAssertEqual(post.url, network.modifyURL?.url)
        XCTAssertEqual(sentBody(post), expectedBody(Self.capturedDeviceIDBody))
        XCTAssertEqual(flagWhileSent, [false])
        XCTAssertEqual(logged, ["mParticle -> Identity request failed - HTTP error (code: 500)"])
    }

    func testTheAliasBodyCarriesTheAPIKeyAndTheDeviceApplicationStamp() {
        useCapturedState()
        let body = network.aliasRequestDictionary(
            sourceMPID: 1, destinationMPID: 2,
            startTime: Date(timeIntervalSince1970: 100.5), endTime: Date(timeIntervalSince1970: 200.25)
        )
        XCTAssertEqual(stripped(body), expectedBody(Self.capturedAliasBody))

        let empty = network.aliasRequestDictionary(sourceMPID: nil, destinationMPID: nil, startTime: nil, endTime: nil)
        XCTAssertEqual(empty["data"] as? NSDictionary, ["device_application_stamp": "stamp-fixture"])
    }
}
