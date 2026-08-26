import XCTest
@testable import mParticle_Apple_SDK_Swift

private class MockAppUserDefaults: NSObject, MPApplicationMPUserDefaultsProtocol {
    var store: [String: Any] = [:]
    var sideloadedCount: UInt = 0

    subscript(key: String) -> Any? {
        get { store[key] }
        set { store[key] = newValue }
    }

    func removeMPObject(forKey key: String) { store.removeValue(forKey: key) }
    func sideloadedKitsCount() -> UInt { sideloadedCount }
    func synchronize() {}
}

private class MockAppStateMachine: NSObject, MPApplicationStateMachineProtocol {
    var firstSeenInstallation: NSNumber = false
    var searchAdsInfo: [AnyHashable: Any] = [:]
    var launchDate: Date?
    var allowASR: Bool = false
}

final class MPApplicationTests: XCTestCase {
    private let info: [String: Any] = [
        "CFBundleDisplayName": "My App",
        "CFBundleShortVersionString": "2.5.0",
        "CFBundleVersion": "77",
        "CFBundleIdentifier": "com.example.app"
    ]

    private func makeApp(userDefaults: MockAppUserDefaults = MockAppUserDefaults(),
                         stateMachine: MockAppStateMachine = MockAppStateMachine()) -> MPApplication_PRIVATE {
        MPApplication_PRIVATE(stateMachine: stateMachine,
                              userDefaults: userDefaults,
                              environment: 2,
                              deploymentTarget: 150_000,
                              buildSDK: 180_000,
                              infoProvider: MPApplicationInfoProvider(infoDictionary: info, appStoreReceiptURL: nil))
    }

    func testDictionaryRepresentationCoreKeys() {
        let sm = MockAppStateMachine()
        sm.firstSeenInstallation = true
        let ud = MockAppUserDefaults()
        ud.sideloadedCount = 3
        let dict = makeApp(userDefaults: ud, stateMachine: sm).dictionaryRepresentation()

        XCTAssertEqual(dict[MPApplicationKeys.kMPAppEnvironmentKey] as? Int, 2)
        XCTAssertEqual(dict[MPApplicationKeys.kMPAppDeploymentTargetKey] as? String, "150000")
        XCTAssertEqual(dict[MPApplicationKeys.kMPAppBuildSDKKey] as? String, "180000")
        XCTAssertEqual(dict[MPApplicationKeys.kMPApplicationVersionKey] as? String, "2.5.0")
        XCTAssertEqual(dict[MPApplicationKeys.kMPAppBuildNumberKey] as? String, "77")
        XCTAssertEqual(dict[MPApplicationKeys.kMPAppPackageNameKey] as? String, "com.example.app")
        XCTAssertEqual(dict[MPApplicationKeys.kMPApplicationNameKey] as? String, "My App")
        XCTAssertEqual(dict[MPApplicationKeys.kMPAppSideloadKitsCountKey] as? Int, 3)
        XCTAssertEqual((dict[MPApplicationKeys.kMPAppPiratedKey] as? NSNumber)?.boolValue, false)
        XCTAssertEqual(dict["fi"] as? Bool, true) // first-seen installation
    }

    func testSearchAdsIncludedOnlyWhenPresent() {
        let sm = MockAppStateMachine()
        XCTAssertNil(makeApp(stateMachine: sm).dictionaryRepresentation()["asaa"])

        sm.searchAdsInfo = ["a": 1]
        XCTAssertNotNil(makeApp(stateMachine: sm).dictionaryRepresentation()["asaa"])
    }

    func testUpdateLaunchCountsIncrementsAndDetectsUpgrade() {
        let ud = MockAppUserDefaults()
        // No stored version yet -> treated as upgrade: sinceUpgrade resets to 1, upgradeDate set.
        MPApplication_PRIVATE.updateLaunchCountsAndDates(userDefaults: ud)
        XCTAssertEqual((ud[MPApplicationKeys.kMPAppLaunchCountKey] as? NSNumber)?.intValue, 1)
        XCTAssertEqual((ud[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] as? NSNumber)?.intValue, 1)
        XCTAssertNotNil(ud[MPApplicationKeys.kMPAppUpgradeDateKey])

        // Same version/build (main bundle) -> sinceUpgrade increments.
        ud[MPApplicationKeys.kMPAppStoredVersionKey] = Bundle.main.infoDictionary?["CFBundleShortVersionString"]
        ud[MPApplicationKeys.kMPAppStoredBuildKey] = Bundle.main.infoDictionary?["CFBundleVersion"]
        MPApplication_PRIVATE.updateLaunchCountsAndDates(userDefaults: ud)
        XCTAssertEqual((ud[MPApplicationKeys.kMPAppLaunchCountKey] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((ud[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] as? NSNumber)?.intValue, 2)
    }

    func testMarkInitialLaunchTimeSetsOnceThenPreserves() {
        let ud = MockAppUserDefaults()
        MPApplication_PRIVATE.markInitialLaunchTime(userDefaults: ud)
        let first = ud[MPApplicationKeys.kMPAppInitialLaunchTimeKey] as? NSNumber
        XCTAssertNotNil(first)
        MPApplication_PRIVATE.markInitialLaunchTime(userDefaults: ud)
        XCTAssertEqual(ud[MPApplicationKeys.kMPAppInitialLaunchTimeKey] as? NSNumber, first)
    }

    func testUpdateLastUseDateNilIsZero() {
        let ud = MockAppUserDefaults()
        MPApplication_PRIVATE.updateLastUseDate(nil, userDefaults: ud)
        XCTAssertEqual((ud[MPApplicationKeys.kMPAppLastUseDateKey] as? NSNumber)?.doubleValue, 0)
    }

    func testStoredVersionSetAndRemove() {
        let app = makeApp()
        app.storedVersion = "1.0.0"
        XCTAssertEqual(app.storedVersion, "1.0.0")
        app.storedVersion = nil
        XCTAssertNil(app.storedVersion)
    }

    func testLastUseDateFallsBackToLaunchDate() {
        let sm = MockAppStateMachine()
        sm.launchDate = Date(timeIntervalSince1970: 1000)
        let value = makeApp(stateMachine: sm).lastUseDate
        XCTAssertEqual(value.doubleValue, 1_000_000) // 1000s -> ms
    }

    func testAppImageInfoHasBaseAndSize() {
        let dict = MPApplication_PRIVATE.appImageInfo()
        XCTAssertNotNil(dict[MPApplicationKeys.kMPAppImageBaseAddressKey])
        XCTAssertNotNil(dict[MPApplicationKeys.kMPAppImageSizeKey])
    }

    func testArchitectureNonEmpty() {
        XCTAssertFalse(makeApp().architecture.isEmpty)
    }
}
