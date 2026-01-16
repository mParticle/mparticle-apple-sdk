import XCTest
import mParticle_Apple_SDK_NoLocation

class SettingsProviderTests: XCTestCase {
    func testDefaultConfiguration() {
        let settingsProvider = SettingsProvider()

        let config = settingsProvider.configSettings
        XCTAssertEqual(config, nil)
    }
}
