import XCTest
@testable import mParticle_Apple_SDK_Swift

/// The backend's fake host, plus the network layer's reads. It records which settings and
/// authorisation each upload URL was routed with.
private final class MPNetworkFakeHost: MPBackendFakeHost, MPNetworkHost {
    var appVersion: String? = "1.0"
    private(set) var uploadRoutings: [(settings: NSObject, attAuthorized: Bool)] = []

    func networkRouting(attAuthorized: Bool) -> MPEndpointRouting {
        Self.routing(apiKey: "network-key", attAuthorized: attAuthorized)
    }

    func routing(forUploadSettings uploadSettings: NSObject, attAuthorized: Bool) -> MPEndpointRouting {
        uploadRoutings.append((uploadSettings, attAuthorized))
        return Self.routing(apiKey: "upload-key", attAuthorized: attAuthorized)
    }

    func applicationVersion() -> String? { appVersion }
    func logLevel() -> UInt { 0 }
    func webView() -> MParticleWebViewPRIVATE? { nil }
    func supportedKits() -> [NSNumber]? { nil }
    func configuredKits() -> [NSNumber]? { nil }
    func customCertificates() -> [Data] { [] }
    func pinningDisabled() -> Bool { false }
    func pinningDisabledInDevelopment() -> Bool { false }
    func executeOnMainSync(_ block: @escaping () -> Void) { block() }
    func mergeConsumerInfo(fromResponse _: NSDictionary) {}
    func deleteUpload(_: MPUploadPRIVATE) {}
    func logKitBatch(_: String) {}

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
}
