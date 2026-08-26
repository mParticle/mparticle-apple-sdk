import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUploadSettingsTests: XCTestCase {
    // MARK: - Host resolution

    func testResolvedHostPrefersCustomHost() {
        XCTAssertEqual(MPUploadSettingsPRIVATE.resolvedHost(customHost: "custom.example.com", host: "events.example.com"),
                       "custom.example.com")
    }

    func testResolvedHostFallsBackToHostWhenCustomNil() {
        XCTAssertEqual(MPUploadSettingsPRIVATE.resolvedHost(customHost: nil, host: "events.example.com"), "events.example.com")
    }

    func testResolvedHostReturnsNilWhenBothNil() {
        XCTAssertNil(MPUploadSettingsPRIVATE.resolvedHost(customHost: nil, host: nil))
    }

    func testResolvedHostCustomHostOverridesNilHost() {
        XCTAssertEqual(MPUploadSettingsPRIVATE.resolvedHost(customHost: "custom.example.com", host: nil), "custom.example.com")
    }

    // MARK: - Storage

    func testDefaultInitMatchesLegacyDefaults() {
        let settings = MPUploadSettingsPRIVATE()
        XCTAssertEqual(settings.apiKey, "")
        XCTAssertEqual(settings.secret, "")
        XCTAssertNil(settings.eventsHost)
        XCTAssertNil(settings.eventsTrackingHost)
        XCTAssertFalse(settings.overridesEventsSubdirectory)
        XCTAssertNil(settings.aliasHost)
        XCTAssertNil(settings.aliasTrackingHost)
        XCTAssertFalse(settings.overridesAliasSubdirectory)
        XCTAssertFalse(settings.eventsOnly)
    }

    // MARK: - Coding round-trip

    private func makePopulated() -> MPUploadSettingsPRIVATE {
        MPUploadSettingsPRIVATE(apiKey: "key",
                                secret: "sec",
                                eventsHost: "events.example.com",
                                eventsTrackingHost: "events-tracking.example.com",
                                overridesEventsSubdirectory: true,
                                aliasHost: "alias.example.com",
                                aliasTrackingHost: "alias-tracking.example.com",
                                overridesAliasSubdirectory: true,
                                eventsOnly: true)
    }

    private func roundTrip(_ settings: MPUploadSettingsPRIVATE) throws -> MPUploadSettingsPRIVATE {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        settings.encode(to: archiver)
        archiver.finishEncoding()
        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archiver.encodedData)
        unarchiver.requiresSecureCoding = true
        return MPUploadSettingsPRIVATE(fromCoder: unarchiver)
    }

    func testCodingRoundTripPreservesAllFields() throws {
        let restored = try roundTrip(makePopulated())
        XCTAssertEqual(restored.apiKey, "key")
        XCTAssertEqual(restored.secret, "sec")
        XCTAssertEqual(restored.eventsHost, "events.example.com")
        XCTAssertEqual(restored.eventsTrackingHost, "events-tracking.example.com")
        XCTAssertTrue(restored.overridesEventsSubdirectory)
        XCTAssertEqual(restored.aliasHost, "alias.example.com")
        XCTAssertEqual(restored.aliasTrackingHost, "alias-tracking.example.com")
        XCTAssertTrue(restored.overridesAliasSubdirectory)
        XCTAssertTrue(restored.eventsOnly)
    }

    func testCodingRoundTripPreservesNilHosts() throws {
        let restored = try roundTrip(MPUploadSettingsPRIVATE())
        XCTAssertEqual(restored.apiKey, "")
        XCTAssertEqual(restored.secret, "")
        XCTAssertNil(restored.eventsHost)
        XCTAssertNil(restored.eventsTrackingHost)
        XCTAssertFalse(restored.overridesEventsSubdirectory)
        XCTAssertNil(restored.aliasHost)
        XCTAssertNil(restored.aliasTrackingHost)
        XCTAssertFalse(restored.overridesAliasSubdirectory)
        XCTAssertFalse(restored.eventsOnly)
    }
}
