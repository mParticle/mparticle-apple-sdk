import XCTest
@testable import mParticle_Apple_SDK_Swift;

class MPUserDefaultsConnectorMock: MPUserDefaultsConnectorProtocol {
    var logger = MPLog(logLevel: .warning)
    
    var deferredKitConfiguration: [[AnyHashable: Any]]?
    
    func configureKits(_ kitConfigurations: [[AnyHashable: Any]]?) {
    }
    
    func configureCustomModules(_ customModuleSettings: [[AnyHashable: Any]]?) {
    }
    
    func configureRampPercentage(_ rampPercentage: NSNumber?) {
    }
    
    func configureTriggers(_ triggerDictionary: [AnyHashable: Any]?) {
    }
    
    func configureAliasMaxWindow(_ aliasMaxWindow: NSNumber?) {
    }
    
    func configureDataBlocking(_ blockSettings: [AnyHashable: Any]?) {
    }
    
    func userId() -> NSNumber? {
        return 1
    }
    
    func setAllowASR(_ allowASR: Bool) {
    }
    
    func setEnableAudienceAPI(_ enableAudienceAPI: Bool) {
    }
    
    func setExceptionHandlingMode(_ exceptionHandlingMode: String?) {
    }
    
    func setSessionTimeout(_ sessionTimeout: TimeInterval) {
    }
    
    func setPushNotificationMode(_ pushNotificationMode: String) {
    }
    
    func setCrashMaxPLReportLength(_ crashMaxPLReportLength: NSNumber) {
    }
    
    func isAppExtension() -> Bool {
        return false
    }
    
    func registerForRemoteNotifications() {
        
    }
    
    func unregisterForRemoteNotifications() {
        
    }
    
    func canCreateConfiguration() -> Bool {
        return false
    }
    
    func mpId() -> NSNumber {
        1
    }
    
    func configMaxAgeSeconds() -> NSNumber? {
        1
    }
}

class MPUserDefaultsTests: XCTestCase {
    var connector: MPUserDefaultsConnectorMock!
    
    override func setUp() {
        super.setUp()
        connector = MPUserDefaultsConnectorMock()
    }
    
    func testUserIDsInUserDefaults() {
        let userDefaults = MPUserDefaults(connector: connector)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: 1)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.max))
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.min))
        userDefaults.synchronize()

        let array = userDefaults.userIDsInUserDefaults()

        XCTAssert(array.contains(NSNumber(value: 1)))
        XCTAssert(array.contains(NSNumber(value: Int64.max)))
        XCTAssert(array.contains(NSNumber(value: Int64.min)))
    }
    
    func testResetDefaults() {
        let userDefaults = MPUserDefaults(connector: connector)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: 1)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.max))
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.min))

        UserDefaults.standard.set("userSetting", forKey: "userKey")

        userDefaults.resetDefaults()

        let array: [NSNumber] = userDefaults.userIDsInUserDefaults()

        XCTAssertFalse(array.contains(NSNumber(value: 1)))
        XCTAssertFalse(array.contains(NSNumber(value: Int64.max)))
        XCTAssertFalse(array.contains(NSNumber(value: Int64.min)))

        XCTAssertNotNil(UserDefaults.standard.object(forKey: "userKey"))
    }
    
    func testMigrate() {
        let userDefaults = MPUserDefaults(connector: connector)
        
        userDefaults["mparticleKey"] = "test"
        userDefaults.synchronize()
        userDefaults.setSharedGroupIdentifier("groupID")

        let groupDefaults = UserDefaults(suiteName: "groupID")
        XCTAssertEqual(groupDefaults?.object(forKey: "mParticle::mparticleKey") as? String, "test")
    }
    
    func testMigrateGroupDoesNotMigrateClientDefaults() {
        let userDefaults = MPUserDefaults(connector: connector)
        UserDefaults.standard.set("clientSetting", forKey: "clientKey")

        userDefaults.setSharedGroupIdentifier("groupID")

        XCTAssertNotNil(UserDefaults.standard.object(forKey: "clientKey"))
        XCTAssertNil(UserDefaults(suiteName: "groupID")?.object(forKey: "clientKey"))
    }
    
    func testMigrateGroupWithMultipleUsers() {
        let userDefaults = MPUserDefaults(connector: connector)

        userDefaults.setMPObject(Date(), forKey: "lud", userId: 1)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.max))
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.min))

        userDefaults.setSharedGroupIdentifier("groupID")

        let array: [NSNumber] = userDefaults.userIDsInUserDefaults()

        XCTAssert(array.contains(NSNumber(value: 1)))
        XCTAssert(array.contains(NSNumber(value: Int64.max)))
        XCTAssert(array.contains(NSNumber(value: Int64.min)))
    }
}
