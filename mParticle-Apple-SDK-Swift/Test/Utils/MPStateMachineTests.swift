import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPStateMachineTests: XCTestCase {
    private var connector: MPUserDefaultsConnectorMock!
    private var userDefaults: MPUserDefaults!
    private var state: MPStateMachinePRIVATE!

    override func setUp() {
        super.setUp()
        connector = MPUserDefaultsConnectorMock()
        userDefaults = MPUserDefaults(connector: connector)
        state = MPStateMachinePRIVATE(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.resetDefaults()
        super.tearDown()
    }

    func testDetectEnvironmentOnSimulatorIsDevelopment() {
        #if targetEnvironment(simulator)
        XCTAssertEqual(MPStateMachinePRIVATE.detectEnvironment(), 1)
        #endif
    }

    func testEnvironmentOverride() {
        let previous = MPStateMachinePRIVATE.environment()
        MPStateMachinePRIVATE.setEnvironment(2)
        XCTAssertEqual(MPStateMachinePRIVATE.environment(), 2)
        MPStateMachinePRIVATE.setEnvironment(previous)
    }

    func testRunningInBackground() {
        let previous = MPStateMachinePRIVATE.runningInBackground()
        MPStateMachinePRIVATE.setRunningInBackground(true)
        XCTAssertTrue(MPStateMachinePRIVATE.runningInBackground())
        MPStateMachinePRIVATE.setRunningInBackground(false)
        XCTAssertFalse(MPStateMachinePRIVATE.runningInBackground())
        MPStateMachinePRIVATE.setRunningInBackground(previous)
    }

    func testDeviceTokenTypeFromProvisioningProfile() {
        XCTAssertEqual(MPStateMachinePRIVATE.deviceTokenType(fromProvisioningProfile: nil), "")
        XCTAssertEqual(
            MPStateMachinePRIVATE.deviceTokenType(
                fromProvisioningProfile: "<key>aps-environment</key><string>production</string>"
            ),
            Miscellaneous.kMPDeviceTokenTypeProduction
        )
        XCTAssertEqual(
            MPStateMachinePRIVATE.deviceTokenType(
                fromProvisioningProfile: "<key>aps-environment</key><string>development</string>"
            ),
            Miscellaneous.kMPDeviceTokenTypeDevelopment
        )
        XCTAssertEqual(MPStateMachinePRIVATE.deviceTokenType(fromProvisioningProfile: "unrelated"), "")
    }

    func testRampPercentage() {
        XCTAssertFalse(MPStateMachinePRIVATE.dataRamped(applyingRampPercentage: nil, deviceIdentifier: "id"))
        XCTAssertFalse(MPStateMachinePRIVATE.dataRamped(applyingRampPercentage: NSNull(), deviceIdentifier: "id"))
        XCTAssertTrue(MPStateMachinePRIVATE.dataRamped(applyingRampPercentage: 0, deviceIdentifier: "id"))
        XCTAssertFalse(MPStateMachinePRIVATE.dataRamped(applyingRampPercentage: 100, deviceIdentifier: "id"))
        XCTAssertFalse(MPStateMachinePRIVATE.dataRamped(applyingRampPercentage: -1, deviceIdentifier: "id"))
        XCTAssertFalse(MPStateMachinePRIVATE.dataRamped(applyingRampPercentage: NSNumber(value: Int.min), deviceIdentifier: "id"))
    }

    func testAliasMaxWindowDefaultsTo90() {
        state.configureAliasMaxWindow(NSNull())
        XCTAssertEqual(state.aliasMaxWindow, 90)
        state.configureAliasMaxWindow(30)
        XCTAssertEqual(state.aliasMaxWindow, 30)
    }

    func testApplyTriggersAddsCommerceMessageType() {
        XCTAssertTrue(state.applyTriggers([
            RemoteConfig.kMPRemoteConfigTriggerEventsKey: ["event-hash"],
            RemoteConfig.kMPRemoteConfigTriggerMessageTypesKey: ["e", "pm"]
        ]))
        XCTAssertEqual(state.triggerEventTypes as? [String], ["event-hash"])
        XCTAssertEqual(state.triggerMessageTypes as? [String], ["cm", "e", "pm"])
    }

    func testApplyNullTriggersKeepsCommerceOnly() {
        XCTAssertTrue(state.applyTriggers(nil))
        XCTAssertNil(state.triggerEventTypes)
        XCTAssertEqual(state.triggerMessageTypes as? [String], ["cm"])
        XCTAssertFalse(state.applyTriggers(NSNull()))
        XCTAssertEqual(state.triggerMessageTypes as? [String], ["cm"])
    }

    func testOptOutPersistence() {
        XCTAssertFalse(state.optOut())
        state.setOptOut(true)
        XCTAssertTrue(state.optOut())

        let reloaded = MPStateMachinePRIVATE(userDefaults: userDefaults)
        XCTAssertTrue(reloaded.optOut())
    }

    func testSearchAdsInfoMapping() {
        let mapped = MPStateMachinePRIVATE.searchAdsInfo(fromAdAttribution: [
            "attribution": true,
            "orgId": 12,
            "campaignId": 34,
            "conversionType": "Download",
            "clickDate": "2020-01-01",
            "adGroupId": 56,
            "countryOrRegion": "US",
            "keywordId": 78,
            "adId": 90
        ])
        let version = mapped?["Version4.0"] as? NSDictionary
        XCTAssertEqual(version?["iad-org-id"] as? String, "12")
        XCTAssertEqual(version?["iad-campaign-id"] as? String, "34")
        XCTAssertEqual(version?["iad-conversion-type"] as? String, "Download")
        XCTAssertEqual(version?["iad-ad-id"] as? String, "90")
    }
}
