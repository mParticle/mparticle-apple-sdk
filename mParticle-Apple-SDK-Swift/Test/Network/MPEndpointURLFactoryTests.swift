import XCTest
@testable import mParticle_Apple_SDK_Swift

/// The expected strings here are the same ones `MPNetworkCommunicationTests`
/// characterizes against the Objective-C builders, so the two suites agree on every
/// `MPNetworkOptions` combination, malformed URLs included.
///
/// Two routings appear throughout because the SDK feeds the endpoints from two places:
/// config, audience, identity and modify read `MPNetworkOptions` directly, while event
/// and alias read an `MPUploadSettings` that has already folded `customBaseURL` into its
/// host fields. See `uploadRouting(...)`.
final class MPEndpointURLFactoryTests: XCTestCase {
    private var warnings: [String] = []
    private var factory: MPEndpointURLFactory!

    override func setUp() {
        super.setUp()
        warnings = []
        let log = MPLog(logLevel: .warning)
        log.customLogger = { [weak self] message in self?.warnings.append(message) }
        factory = MPEndpointURLFactory(logger: { log })
    }

    override func tearDown() {
        factory = nil
        warnings = []
        super.tearDown()
    }

    // MARK: - No network options

    func testNoNetworkOptions() {
        let net = routing()
        let upload = uploadRouting()

        assertURL(
            configURL(net),
            requested: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
        assertURL(
            factory.identityURL(routing: net, defaultIdentityHost: identityHost(), pathComponent: "identify"),
            requested: "https://identity.us1.mparticle.com/v1/identify",
            canonical: "https://identity.us1.mparticle.com/v1/identify"
        )
        assertURL(
            factory.modifyURL(routing: net, defaultIdentityHost: identityHost(), mpId: 0),
            requested: "https://identity.us1.mparticle.com/v1/0/modify",
            canonical: "https://identity.us1.mparticle.com/v1/0/modify"
        )
        assertURL(
            factory.audienceURL(routing: net, defaultEventHost: eventHost(), mpId: 0),
            requested: "https://nativesdks.us1.mparticle.com/v1/unit_test_app_key/audience?mpid=0",
            canonical: "https://nativesdks.us1.mparticle.com/v1/unit_test_app_key?mpid=/audience"
        )
        assertURL(
            factory.eventURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://nativesdks.us1.mparticle.com/v2/unit_test_app_key/events",
            canonical: "https://nativesdks.us1.mparticle.com/v2/unit_test_app_key/events"
        )
        assertURL(
            factory.aliasURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias",
            canonical: "https://nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
        XCTAssertTrue(warnings.isEmpty)
    }

    // MARK: - Host overrides

    func testHostOverrides() {
        let net = routing(hosts: true)
        let upload = uploadRouting(hosts: true)

        assertURL(
            configURL(net),
            requested: "https://cfg.example.com/v4/unit_test_app_key/config\(query)",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
        assertURL(
            factory.identityURL(routing: net, defaultIdentityHost: identityHost(), pathComponent: "identify"),
            requested: "https://id.example.com/v1/identify",
            canonical: "https://identity.us1.mparticle.com/v1/identify"
        )
        assertURL(
            factory.modifyURL(routing: net, defaultIdentityHost: identityHost(), mpId: 0),
            requested: "https://id.example.com/v1/0/modify",
            canonical: "https://identity.us1.mparticle.com/v1/0/modify"
        )
        assertURL(
            factory.audienceURL(routing: net, defaultEventHost: eventHost(), mpId: 0),
            requested: "https://ev.example.com/v1/unit_test_app_key/audience?mpid=0",
            canonical: "https://nativesdks.us1.mparticle.com/v1/unit_test_app_key?mpid=/audience"
        )
        assertURL(
            factory.eventURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://ev.example.com/v2/unit_test_app_key/events",
            canonical: "https://nativesdks.us1.mparticle.com/v2/unit_test_app_key/events"
        )
        assertURL(
            factory.aliasURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://al.example.com/v1/identity/unit_test_app_key/alias",
            canonical: "https://nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
    }

    // MARK: - Host plus subdirectory overrides

    func testHostAndSubdirectoryOverridesDropTheVersionSegment() {
        let net = routing(hosts: true, overrides: true)
        let upload = uploadRouting(hosts: true, overrides: true)

        assertURL(
            configURL(net),
            requested: "https://cfg.example.com/unit_test_app_key/config\(query)",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
        assertURL(
            factory.identityURL(routing: net, defaultIdentityHost: identityHost(), pathComponent: "identify"),
            requested: "https://id.example.com/identify",
            canonical: "https://identity.us1.mparticle.com/v1/identify"
        )
        assertURL(
            factory.modifyURL(routing: net, defaultIdentityHost: identityHost(), mpId: 0),
            requested: "https://id.example.com/0/modify",
            canonical: "https://identity.us1.mparticle.com/v1/0/modify"
        )
        assertURL(
            factory.eventURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://ev.example.com/unit_test_app_key/events",
            canonical: "https://nativesdks.us1.mparticle.com/v2/unit_test_app_key/events"
        )
        assertURL(
            factory.aliasURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://al.example.com/unit_test_app_key/alias",
            canonical: "https://nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
    }

    /// The version is jammed against the API key, `/audience` lands in the mpid slot and
    /// the real mpid is dropped. Carried over from the Objective-C original, not fixed.
    func testSubdirectoryOverrideProducesTheMalformedAudienceURL() {
        assertURL(
            factory.audienceURL(
                routing: routing(hosts: true, overrides: true),
                defaultEventHost: eventHost(),
                mpId: 0
            ),
            requested: "https://ev.example.com/v1unit_test_app_key?mpid=/audience",
            canonical: "https://nativesdks.us1.mparticle.com/v1/unit_test_app_key?mpid=/audience"
        )
    }

    // MARK: - Custom base URL

    func testCustomBaseURLUsesTheCDNVersionSegments() {
        let net = routing(customBaseURL: true)
        let upload = uploadRouting(customBaseURL: true)

        assertURL(
            configURL(net),
            requested: "https://cdn.example.com/config/v4/unit_test_app_key/config\(query)",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
        assertURL(
            factory.identityURL(routing: net, defaultIdentityHost: identityHost(), pathComponent: "identify"),
            requested: "https://cdn.example.com/identity/v1/identify",
            canonical: "https://identity.us1.mparticle.com/v1/identify"
        )
        assertURL(
            factory.modifyURL(routing: net, defaultIdentityHost: identityHost(), mpId: 0),
            requested: "https://cdn.example.com/identity/v1/0/modify",
            canonical: "https://identity.us1.mparticle.com/v1/0/modify"
        )
        assertURL(
            factory.audienceURL(routing: net, defaultEventHost: eventHost(), mpId: 0),
            requested: "https://cdn.example.com/nativeevents/v1/unit_test_app_key/audience?mpid=0",
            canonical: "https://nativesdks.us1.mparticle.com/v1/unit_test_app_key?mpid=/audience"
        )
        assertURL(
            factory.eventURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://cdn.example.com/nativeevents/v2/unit_test_app_key/events",
            canonical: "https://nativesdks.us1.mparticle.com/v2/unit_test_app_key/events"
        )
        assertURL(
            factory.aliasURL(routing: upload, defaultEventHost: eventHost()),
            requested: "https://cdn.example.com/nativeevents/v1/identity/unit_test_app_key/alias",
            canonical: "https://nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
    }

    // MARK: - Tracking hosts under ATT

    func testTrackingHostsWithATTAuthorized() {
        let net = routing(trackingHosts: true, attAuthorized: true)
        let upload = uploadRouting(trackingHosts: true, attAuthorized: true)

        // Config never consults a tracking host, so it stays on the default host.
        assertURL(
            configURL(net),
            requested: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
        assertURL(
            factory.identityURL(
                routing: net,
                defaultIdentityHost: identityHost(att: true),
                pathComponent: "identify"
            ),
            requested: "https://tid.example.com/v1/identify",
            canonical: "https://tracking-identity.us1.mparticle.com/v1/identify"
        )
        assertURL(
            factory.modifyURL(routing: net, defaultIdentityHost: identityHost(att: true), mpId: 0),
            requested: "https://tid.example.com/v1/0/modify",
            canonical: "https://tracking-identity.us1.mparticle.com/v1/0/modify"
        )
        assertURL(
            factory.eventURL(routing: upload, defaultEventHost: eventHost(att: true)),
            requested: "https://tev.example.com/v2/unit_test_app_key/events",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v2/unit_test_app_key/events"
        )
    }

    /// Audience ignores `eventsTrackingHost` entirely; it only picks up the tracking
    /// subdomain through the default event host it is handed.
    func testAudienceIgnoresTheEventsTrackingHost() {
        assertURL(
            factory.audienceURL(
                routing: routing(trackingHosts: true, attAuthorized: true),
                defaultEventHost: eventHost(att: true),
                mpId: 0
            ),
            requested: "https://tracking-nativesdks.us1.mparticle.com/v1/unit_test_app_key/audience?mpid=0",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v1/unit_test_app_key?mpid=/audience"
        )
    }

    /// With no alias host and `eventsOnly` off, alias re-resolves through the events
    /// host, discarding the alias tracking host that was just resolved.
    func testAliasTrackingHostIsClobberedWithoutAnAliasHost() {
        assertURL(
            factory.aliasURL(
                routing: uploadRouting(trackingHosts: true, attAuthorized: true),
                defaultEventHost: eventHost(att: true)
            ),
            requested: "https://tracking-nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
    }

    func testAliasKeepsItsTrackingHostWhenEventsOnlyIsSet() {
        assertURL(
            factory.aliasURL(
                routing: uploadRouting(trackingHosts: true, attAuthorized: true, eventsOnly: true),
                defaultEventHost: eventHost(att: true)
            ),
            requested: "https://tal.example.com/v1/identity/unit_test_app_key/alias",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
    }

    func testTrackingHostsWithSubdirectoryOverrides() {
        let net = routing(trackingHosts: true, overrides: true, attAuthorized: true)
        let upload = uploadRouting(trackingHosts: true, overrides: true, attAuthorized: true)

        assertURL(
            configURL(net),
            requested: "https://config2.mparticle.com/unit_test_app_key/config\(query)",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
        assertURL(
            factory.identityURL(
                routing: net,
                defaultIdentityHost: identityHost(att: true),
                pathComponent: "identify"
            ),
            requested: "https://tid.example.com/identify",
            canonical: "https://tracking-identity.us1.mparticle.com/v1/identify"
        )
        assertURL(
            factory.audienceURL(routing: net, defaultEventHost: eventHost(att: true), mpId: 0),
            requested: "https://tracking-nativesdks.us1.mparticle.com/v1unit_test_app_key?mpid=/audience",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v1/unit_test_app_key?mpid=/audience"
        )
        assertURL(
            factory.eventURL(routing: upload, defaultEventHost: eventHost(att: true)),
            requested: "https://tev.example.com/unit_test_app_key/events",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v2/unit_test_app_key/events"
        )
        assertURL(
            factory.aliasURL(routing: upload, defaultEventHost: eventHost(att: true)),
            requested: "https://tracking-nativesdks.us1.mparticle.com/unit_test_app_key/alias",
            canonical: "https://tracking-nativesdks.us1.mparticle.com/v1/identity/unit_test_app_key/alias"
        )
    }

    // MARK: - Data plan

    func testDataPlanQueryIsAppendedToTheRequestedURLOnly() {
        let url = factory.configURL(
            routing: routing(),
            appVersion: appVersion,
            sdkVersion: sdkVersion,
            dataPlanId: "my_plan",
            dataPlanVersion: 3
        )

        assertURL(
            url,
            requested: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
                + "&plan_id=my_plan&plan_version=3",
            canonical: "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)"
        )
    }

    func testOutOfRangeDataPlanVersionWarnsAndDropsTheVersion() {
        let url = factory.configURL(
            routing: routing(),
            appVersion: appVersion,
            sdkVersion: sdkVersion,
            dataPlanId: "my_plan",
            dataPlanVersion: 5000
        )

        XCTAssertEqual(
            url?.url.absoluteString,
            "https://config2.mparticle.com/v4/unit_test_app_key/config\(query)&plan_id=my_plan"
        )
        XCTAssertTrue(warnings.contains { $0.contains("Data plan version of 5000 is out of range") })
    }

    // MARK: - Warnings

    func testCustomBaseURLWithAConfigHostWarns() {
        _ = configURL(routing(hosts: true, customBaseURL: true))

        XCTAssertTrue(warnings.contains { $0.contains("customBaseURL is set; configHost is ignored.") })
    }

    func testCustomBaseURLWithAnEventsHostWarnsOnAudience() {
        _ = factory.audienceURL(
            routing: routing(hosts: true, customBaseURL: true),
            defaultEventHost: eventHost(),
            mpId: 0
        )

        XCTAssertTrue(warnings.contains { $0.contains("customBaseURL is set; eventsHost is ignored.") })
    }

    func testCustomBaseURLWithIdentityHostsWarns() {
        _ = factory.identityURL(
            routing: routing(hosts: true, customBaseURL: true),
            defaultIdentityHost: identityHost(),
            pathComponent: "identify"
        )

        XCTAssertTrue(
            warnings.contains { $0.contains("customBaseURL is set; identityHost/identityTrackingHost are ignored.") }
        )
    }

    func testCustomBaseURLBeatsASubdirectoryOverrideAndWarns() {
        _ = configURL(routing(overrides: true, customBaseURL: true))

        XCTAssertTrue(
            warnings.contains {
                $0.contains("customBaseURL with overridesConfigSubdirectory is unsupported for CDN routing")
            }
        )
    }

    func testAliasWarnsAboutBothSubdirectoryOverrides() {
        _ = factory.aliasURL(
            routing: uploadRouting(overrides: true, customBaseURL: true),
            defaultEventHost: eventHost()
        )

        XCTAssertTrue(warnings.contains { $0.contains("overridesAliasSubdirectory/overridesEventsSubdirectory") })
    }

    // MARK: - Routing hint

    func testIdentityEndpointsCarryTheIdentityHint() {
        let identity = factory.identityURL(
            routing: routing(),
            defaultIdentityHost: identityHost(),
            pathComponent: "identify"
        )
        let modify = factory.modifyURL(routing: routing(), defaultIdentityHost: identityHost(), mpId: 0)
        let alias = factory.aliasURL(routing: uploadRouting(), defaultEventHost: eventHost())

        for url in [identity, modify, alias] {
            XCTAssertEqual((url?.url as NSURL?)?.accessibilityHint, "identity")
            XCTAssertEqual((url?.defaultURL as NSURL?)?.accessibilityHint, "identity")
        }
    }

    func testAudienceCarriesTheAudienceHint() {
        let url = factory.audienceURL(routing: routing(), defaultEventHost: eventHost(), mpId: 0)

        XCTAssertEqual((url?.url as NSURL?)?.accessibilityHint, "audience")
        XCTAssertEqual((url?.defaultURL as NSURL?)?.accessibilityHint, "audience")
    }

    func testConfigAndEventEndpointsCarryNoHint() {
        let config = configURL(routing())
        let event = factory.eventURL(routing: uploadRouting(), defaultEventHost: eventHost())

        XCTAssertNil((config?.url as NSURL?)?.accessibilityHint)
        XCTAssertNil((event?.url as NSURL?)?.accessibilityHint)
    }

    // MARK: - Degenerate inputs

    func testMissingAPIKeyRendersAsTheObjectiveCNullDescription() {
        let url = factory.eventURL(routing: uploadRouting(apiKey: nil), defaultEventHost: eventHost())

        XCTAssertEqual(url?.url.absoluteString, "https://nativesdks.us1.mparticle.com/v2/(null)/events")
    }

    func testAnUnparseableHostYieldsNoURL() {
        let url = factory.eventURL(
            routing: uploadRouting(eventsHost: "bad host"),
            defaultEventHost: eventHost()
        )

        XCTAssertNil(url)
    }

    func testMissingAppVersionRendersAsTheObjectiveCNullDescription() {
        let url = factory.configURL(
            routing: routing(),
            appVersion: nil,
            sdkVersion: sdkVersion,
            dataPlanId: nil,
            dataPlanVersion: nil
        )

        XCTAssertEqual(
            url?.url.absoluteString,
            "https://config2.mparticle.com/v4/unit_test_app_key/config?av=(null)&sv=\(sdkVersion)"
        )
    }

    // MARK: - Helpers

    private let appVersion = "1.2.3.4.5678 (bd12345ff)"
    private let sdkVersion = "8.0.0"

    private var query: String {
        "?av=1.2.3.4.5678%20(bd12345ff)&sv=\(sdkVersion)"
    }

    private func configURL(_ routing: MPEndpointRouting) -> MPURL? {
        factory.configURL(
            routing: routing,
            appVersion: appVersion,
            sdkVersion: sdkVersion,
            dataPlanId: nil,
            dataPlanVersion: nil
        )
    }

    private func eventHost(att: Bool = false) -> String {
        att ? "tracking-nativesdks.us1.mparticle.com" : "nativesdks.us1.mparticle.com"
    }

    private func identityHost(att: Bool = false) -> String {
        att ? "tracking-identity.us1.mparticle.com" : "identity.us1.mparticle.com"
    }

    /// What `MPNetworkOptions` hands the config, audience, identity and modify endpoints:
    /// the custom base URL host stays separate from the per-endpoint hosts.
    private func routing(
        hosts: Bool = false,
        trackingHosts: Bool = false,
        overrides: Bool = false,
        customBaseURL: Bool = false,
        attAuthorized: Bool = false
    ) -> MPEndpointRouting {
        MPEndpointRouting(
            apiKey: "unit_test_app_key",
            customBaseURLHost: customBaseURL ? "cdn.example.com" : nil,
            hasCustomBaseURL: customBaseURL,
            configHost: hosts ? "cfg.example.com" : nil,
            eventsHost: hosts ? "ev.example.com" : nil,
            eventsTrackingHost: trackingHosts ? "tev.example.com" : nil,
            identityHost: hosts ? "id.example.com" : nil,
            identityTrackingHost: trackingHosts ? "tid.example.com" : nil,
            aliasHost: hosts ? "al.example.com" : nil,
            aliasTrackingHost: trackingHosts ? "tal.example.com" : nil,
            overridesConfigSubdirectory: overrides,
            overridesEventsSubdirectory: overrides,
            overridesIdentitySubdirectory: overrides,
            overridesAliasSubdirectory: overrides,
            eventsOnly: false,
            attAuthorized: attAuthorized
        )
    }

    /// What `MPUploadSettings` hands the event and alias endpoints. It resolves each host
    /// through `resolvedHost(customHost:host:)`, which is `customHost ?? host`, so a
    /// custom base URL has already replaced every events and alias host by this point.
    private func uploadRouting(
        apiKey: String? = "unit_test_app_key",
        hosts: Bool = false,
        trackingHosts: Bool = false,
        overrides: Bool = false,
        customBaseURL: Bool = false,
        attAuthorized: Bool = false,
        eventsOnly: Bool = false,
        eventsHost: String? = nil
    ) -> MPEndpointRouting {
        let customHost = customBaseURL ? "cdn.example.com" : nil

        return MPEndpointRouting(
            apiKey: apiKey,
            customBaseURLHost: customHost,
            hasCustomBaseURL: customBaseURL,
            configHost: nil,
            eventsHost: customHost ?? eventsHost ?? (hosts ? "ev.example.com" : nil),
            eventsTrackingHost: customHost ?? (trackingHosts ? "tev.example.com" : nil),
            identityHost: nil,
            identityTrackingHost: nil,
            aliasHost: customHost ?? (hosts ? "al.example.com" : nil),
            aliasTrackingHost: customHost ?? (trackingHosts ? "tal.example.com" : nil),
            overridesConfigSubdirectory: false,
            overridesEventsSubdirectory: overrides,
            overridesIdentitySubdirectory: false,
            overridesAliasSubdirectory: overrides,
            eventsOnly: eventsOnly,
            attAuthorized: attAuthorized
        )
    }

    private func assertURL(
        _ url: MPURL?,
        requested: String,
        canonical: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertNotNil(url, file: file, line: line)
        XCTAssertEqual(url?.url.absoluteString, requested, file: file, line: line)
        XCTAssertEqual(url?.defaultURL.absoluteString, canonical, file: file, line: line)
    }
}
