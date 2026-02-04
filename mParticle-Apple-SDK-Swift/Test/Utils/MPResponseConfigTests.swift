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
    
    func testUpdateCustomModuleSettingsOnRestore() {
        let connector = MPUserDefaultsConnectorMock()
        let cmsData =
            "[{\"id\":11,\"pr\":[{\"f\":\"NSUserDefaults\",\"m\":0,\"ps\":[{\"k\":\"APP_MEASUREMENT_VISITOR_ID\",\"d\":\"%gn%\",\"n\":\"vid\",\"t\":1},{\"k\":\"ADOBEMOBILE_STOREDDEFAULTS_AID\",\"d\":\"%oaid%\",\"n\":\"aid\",\"t\":1},{\"k\":\"ADB_LIFETIME_VALUE\",\"d\":\"0\",\"n\":\"ltv\",\"t\":1},{\"k\":\"OMCK1\",\"d\":\"%dt%\",\"n\":\"id\",\"t\":1},{\"k\":\"OMCK6\",\"d\":\"0\",\"n\":\"l\",\"t\":2},{\"k\":\"OMCK5\",\"d\":\"%dt%\",\"n\":\"lud\",\"t\":1}]}]}]"
            .data(using: .utf8)

        let cmsDict = try? JSONSerialization.jsonObject(
            with: cmsData!,
            options: [.mutableContainers]
        )

        let configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigKitsKey: NSNull(),
            RemoteConfig.kMPRemoteConfigCustomModuleSettingsKey: cmsDict!,
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigTriggerKey: NSNull(),
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]

        let responseConfig = MPResponseConfig(configuration: configuration, connector: connector)
        XCTAssertNotNil(responseConfig);
        XCTAssertNotNil(connector.configureCustomModulesCustomModuleSettingsPrarams)
        XCTAssertEqual(1, connector.configureCustomModulesCustomModuleSettingsPrarams?.count)
        let customModules = connector.configureCustomModulesCustomModuleSettingsPrarams
        let customModule = customModules?[0] as? NSDictionary
        let prArray = customModule?["pr"] as! NSArray
        let psArray = (prArray[0] as! NSDictionary)["ps"] as! NSArray
        XCTAssertEqual((psArray[0] as! NSDictionary)["n"] as? String, "vid")
        XCTAssertEqual((psArray[1] as! NSDictionary)["n"] as? String, "aid")
    }
    
    func testInvalidConfigurations() {
        let connector = MPUserDefaultsConnectorMock()
        let configuration = [String: Any]()
        let responseConfig = MPResponseConfig(configuration: configuration, connector: connector)
        XCTAssertNil(responseConfig, "Should have been nil.");
    }
    
    func testInstance() {
        let configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigKitsKey: NSNull(),
            RemoteConfig.kMPRemoteConfigCustomModuleSettingsKey: NSNull(),
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigTriggerKey: NSNull(),
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeIgnore,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]
        let connector = MPUserDefaultsConnectorMock()
        let responseConfig = MPResponseConfig(configuration: configuration, connector: connector)

        XCTAssertNotNil(responseConfig, "Should not have been nil.")
    }
}
