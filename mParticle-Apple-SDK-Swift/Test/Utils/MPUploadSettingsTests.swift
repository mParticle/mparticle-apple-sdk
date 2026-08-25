import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUploadSettingsTests: XCTestCase {
    func testResolvedHostPrefersCustomHost() {
        XCTAssertEqual(
            MPUploadSettingsPRIVATE.resolvedHost(customHost: "custom.example.com", host: "events.example.com"),
            "custom.example.com"
        )
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
}
