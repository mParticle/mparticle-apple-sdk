import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPEndpointHostResolverTests: XCTestCase {
    // MARK: - Pod routing

    func testDefaultHostUsesThePodPrefixFromTheAPIKey() {
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "nativesdks", apiKey: "eu1-0123456789abcdef"),
            "nativesdks.eu1.mparticle.com"
        )
    }

    func testDefaultHostFallsBackToUS1ForAKeyWithoutAPrefix() {
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "identity", apiKey: "0123456789abcdef"),
            "identity.us1.mparticle.com"
        )
    }

    func testDefaultHostFallsBackToUS1ForNilAndEmptyKeys() {
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "nativesdks", apiKey: nil),
            "nativesdks.us1.mparticle.com"
        )
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "nativesdks", apiKey: ""),
            "nativesdks.us1.mparticle.com"
        )
    }

    func testDefaultHostTakesOnlyTheFirstSegmentOfAMultiHyphenKey() {
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "tracking-identity", apiKey: "us2-abc-def"),
            "tracking-identity.us2.mparticle.com"
        )
    }

    func testDefaultHostKeepsAnEmptyLeadingSegment() {
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "nativesdks", apiKey: "-abc"),
            "nativesdks..mparticle.com"
        )
    }

    func testDefaultHostAppliesTheTrackingSubdomainVerbatim() {
        XCTAssertEqual(
            MPEndpointHostResolver.defaultHost(subdomain: "tracking-nativesdks", apiKey: "us1-key"),
            "tracking-nativesdks.us1.mparticle.com"
        )
    }

    // MARK: - Precedence ladder

    func testCustomBaseURLHostWinsOverEveryOtherOption() {
        XCTAssertEqual(
            MPEndpointHostResolver.resolvedHost(
                customBaseURLHost: "cdn.example.com",
                trackingHost: "tracking.example.com",
                host: "host.example.com",
                defaultHost: "default.mparticle.com",
                attAuthorized: true
            ),
            "cdn.example.com"
        )
    }

    func testTrackingHostIsUsedOnlyWhenATTIsAuthorized() {
        XCTAssertEqual(resolved(trackingHost: "tracking.example.com", attAuthorized: true), "tracking.example.com")
        XCTAssertEqual(resolved(trackingHost: "tracking.example.com", attAuthorized: false), "default.mparticle.com")
    }

    func testHostIsUsedWhenThereIsNoApplicableTrackingHost() {
        XCTAssertEqual(resolved(host: "host.example.com", attAuthorized: false), "host.example.com")
        XCTAssertEqual(
            resolved(trackingHost: "tracking.example.com", host: "host.example.com", attAuthorized: false),
            "host.example.com"
        )
    }

    func testDefaultHostIsTheLastResort() {
        XCTAssertEqual(resolved(), "default.mparticle.com")
    }

    func testAnEmptyHostOverridesTheDefaultRatherThanFallingThrough() {
        XCTAssertEqual(resolved(host: ""), "")
        XCTAssertEqual(resolved(trackingHost: "", attAuthorized: true), "")
        XCTAssertEqual(resolved(customBaseURLHost: ""), "")
    }

    // MARK: - Helpers

    private func resolved(
        customBaseURLHost: String? = nil,
        trackingHost: String? = nil,
        host: String? = nil,
        attAuthorized: Bool = false
    ) -> String {
        MPEndpointHostResolver.resolvedHost(
            customBaseURLHost: customBaseURLHost,
            trackingHost: trackingHost,
            host: host,
            defaultHost: "default.mparticle.com",
            attAuthorized: attAuthorized
        )
    }
}
