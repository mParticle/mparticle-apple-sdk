import XCTest
internal import mParticle_Apple_SDK_Swift

class SettingsProviderTests: XCTestCase {
    func testDefaultConfiguration() {
        let settingsProvider = MPSettingsProviderPRIVATE()

        let config = settingsProvider.configSettings
        XCTAssertEqual(config, nil)
    }
}
