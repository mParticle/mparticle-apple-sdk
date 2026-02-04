import XCTest
@testable import mParticle_Apple_SDK_Swift

class MPResponseConfigTests: XCTestCase {
    func testIgnoresLegacyDirectRoutingConfig() {
        let configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigKitsKey: NSNull(),
            RemoteConfig.kMPRemoteConfigCustomModuleSettingsKey: NSNull(),
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigTriggerKey: NSNull(),
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeIgnore,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112,
            "dur": false
        ]
        let connector = MPUserDefaultsConnectorMock()
        let responseConfig = MPResponseConfig(configuration: configuration, connector: connector);
        
        XCTAssertNotNil(responseConfig, "Config should parse successfully even with legacy dur key");
    }
}
