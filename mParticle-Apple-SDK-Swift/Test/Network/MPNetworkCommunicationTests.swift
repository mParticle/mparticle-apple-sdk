import UIKit
import XCTest
@testable import mParticle_Apple_SDK_Swift

/// The backend's fake host, plus the network layer's reads. It records which settings and
/// authorisation each upload URL was routed with, and each hop to the main thread.
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
    private(set) var uploadRoutings: [(settings: NSObject, attAuthorized: Bool)] = []
    private(set) var mainHops: [String] = []

    func networkRouting(attAuthorized: Bool) -> MPEndpointRouting {
        Self.routing(apiKey: "network-key", attAuthorized: attAuthorized)
    }

    func routing(forUploadSettings uploadSettings: NSObject, attAuthorized: Bool) -> MPEndpointRouting {
        uploadRoutings.append((uploadSettings, attAuthorized))
        return Self.routing(apiKey: "upload-key", attAuthorized: attAuthorized)
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

    func mergeConsumerInfo(fromResponse _: NSDictionary) {}
    func deleteUpload(_: MPUploadPRIVATE) {}
    func logKitBatch(_: String) {}
    func userDefaultsConnector() -> MPUserDefaultsConnectorProtocol { configConnector }

    private static func routing(apiKey: String, attAuthorized: Bool) -> MPEndpointRouting {
        MPEndpointRouting(
            apiKey: apiKey, customBaseURLHost: nil, hasCustomBaseURL: false, configHost: nil,
            eventsHost: nil, eventsTrackingHost: nil, identityHost: nil, identityTrackingHost: nil,
            aliasHost: nil, aliasTrackingHost: nil, overridesConfigSubdirectory: false,
            overridesEventsSubdirectory: false, overridesIdentitySubdirectory: false,
            overridesAliasSubdirectory: false, eventsOnly: false, attAuthorized: attAuthorized
        )
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

    /// Answers every GET with one settable response, and records the URLs asked for.
    private final class FakeConnector: NSObject, MPConnectorProtocol {
        let response = MPConnectorResponse()
        private(set) var requestedURLs: [URL] = []

        func respond(_ statusCode: Int, body: Data? = nil, headers: [String: String] = [:]) {
            response.httpResponse = HTTPURLResponse(
                url: URL(string: "https://example.com")!, statusCode: statusCode, httpVersion: nil, headerFields: headers
            )
            response.data = body
        }

        func responseFromGetRequest(to url: MPURL) -> MPConnectorResponseProtocol {
            requestedURLs.append(url.url)
            return response
        }

        func responseFromPostRequest(
            to _: MPURL, message _: String?, serializedParams _: Data?, secret _: String?
        ) -> MPConnectorResponseProtocol {
            response
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
            // Bodies that raised inside the Objective-C version's @try, which reported them as a 204.
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
}
