import XCTest
import mParticle_Apple_SDK

class SettingsProviderTests: XCTestCase {
    func testDefaultConfiguration() {
        let settingsProvider = SettingsProvider()

        let config = settingsProvider.configSettings
        XCTAssertEqual(config, nil)
    }
}
