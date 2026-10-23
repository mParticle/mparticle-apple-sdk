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
    private(set) var deletedUploads: [MPUploadPRIVATE] = []
    private(set) var kitBatches: [String] = []
    private(set) var mergedResponses: [NSDictionary] = []
    private(set) var uploadRoutings: [(settings: NSObject, attAuthorized: Bool)] = []
    private(set) var mainHops: [String] = []

    func networkRouting(attAuthorized: Bool) -> MPEndpointRouting {
        Self.routing(apiKey: "network-key", attAuthorized: attAuthorized)
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

/// One request a fake connector was asked to post.
private struct MPNetworkFakePost {
    let url: URL
    let message: String?
    let params: Data?
    let secret: String?
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
            // Bodies that raised inside the Objective-C version's @try.
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
}
