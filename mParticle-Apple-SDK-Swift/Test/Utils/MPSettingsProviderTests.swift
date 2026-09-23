import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPSettingsProviderTests: XCTestCase {
    func testMissingPlistReturnsNil() {
        let provider = MPSettingsProviderPRIVATE()
        let settings = provider.loadConfigSettings(from: Bundle(for: MPSettingsProviderTests.self), resourceName: "MissingConfig")
        XCTAssertNil(settings)
        XCTAssertNil(provider.configSettings)
    }

    func testExplicitSettingsAreReturnedWithoutLoading() {
        let provider = MPSettingsProviderPRIVATE()
        let expected = NSMutableDictionary(dictionary: ["sessionTimeout": 60])
        provider.configSettings = expected

        let settings = provider.loadConfigSettings(from: Bundle(for: MPSettingsProviderTests.self), resourceName: "MissingConfig")
        XCTAssertEqual(settings, expected)
    }

    func testNilSettingsAllowsReload() {
        let provider = MPSettingsProviderPRIVATE()
        provider.configSettings = NSMutableDictionary(dictionary: ["sessionTimeout": 60])
        provider.configSettings = nil

        let settings = provider.loadConfigSettings(from: Bundle(for: MPSettingsProviderTests.self), resourceName: "MissingConfig")
        XCTAssertNil(settings)
    }
}
