import XCTest
@testable import mParticle_Apple_SDK_Swift

class MPUserDefaultsTests: XCTestCase {
    private let configuration1: [String: Any] = [
        "id": 42,
        "as": [
            "appId": "cool app key"
        ]
    ]

    private let configuration2: [String: Any] = [
        "id": 312,
        "as": [
            "appId": "cool app key 2"
        ]
    ]

    private let eTag = "1.618-2.718-3.141-42"

    private var kitConfigs: [[String: Any]] {
        return [configuration1, configuration2]
    }

    private let kMResponseConfigurationKey = "responseConfiguration"
    private let kMResponseConfigurationCompressedKey = "responseConfigurationCompressed"

    private func buildResponseConfiguration(for kitConfigs: [[String: Any]]) -> [String: Any] {
        return [
            RemoteConfig.kMPRemoteConfigKitsKey: kitConfigs,
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]
    }

    private var responseConfiguration: [String: Any] {
        return buildResponseConfiguration(for: kitConfigs)
    }

    private func buildLargeFilterConfiguration() -> [String: Any] {
        var filterHashes: [String: Int] = [:]
        for index in 0..<5000 {
            filterHashes["\(index)"] = 0
        }

        return buildResponseConfiguration(for: [[
            "id": 28,
            "as": ["apiKey": "test-key"],
            "hs": [
                "ec": filterHashes,
                "ea": filterHashes
            ]
        ]])
    }

    var connector: MPUserDefaultsConnectorMock!
    var userDefaults: MPUserDefaults!

    override func setUp() {
        super.setUp()
        connector = MPUserDefaultsConnectorMock()
        userDefaults = MPUserDefaults(connector: connector)
    }

    override func tearDown() {
        userDefaults.setSharedGroupIdentifier(nil)
        userDefaults.resetDefaults()
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)
        super.tearDown()
    }

    func testUserIDsInUserDefaults() {
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
        userDefaults.setMPObject(Date(), forKey: "lud", userId: 1)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.max))
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.min))

        UserDefaults.standard.set("userSetting", forKey: "userKey")
        UserDefaults.standard.set(true, forKey: kMResponseConfigurationCompressedKey)
        userDefaults.setSharedGroupIdentifier("groupID")
        XCTAssertEqual(
            UserDefaults(suiteName: "groupID")?.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )

        userDefaults.resetDefaults()

        let array: [NSNumber] = userDefaults.userIDsInUserDefaults()

        XCTAssertFalse(array.contains(NSNumber(value: 1)))
        XCTAssertFalse(array.contains(NSNumber(value: Int64.max)))
        XCTAssertFalse(array.contains(NSNumber(value: Int64.min)))

        XCTAssertNotNil(UserDefaults.standard.object(forKey: "userKey"))
        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
        XCTAssertNil(UserDefaults(suiteName: "groupID")?.object(forKey: kMResponseConfigurationCompressedKey))
    }

    func testMigrate() {
        userDefaults["mparticleKey"] = "test"
        userDefaults.synchronize()
        userDefaults.setSharedGroupIdentifier("groupID")

        let groupDefaults = UserDefaults(suiteName: "groupID")
        XCTAssertEqual(groupDefaults?.object(forKey: "mParticle::mparticleKey") as? String, "test")
    }

    func testMigrateGroupDoesNotMigrateClientDefaults() {
        UserDefaults.standard.set("clientSetting", forKey: "clientKey")

        userDefaults.setSharedGroupIdentifier("groupID")

        XCTAssertNotNil(UserDefaults.standard.object(forKey: "clientKey"))
        XCTAssertNil(UserDefaults(suiteName: "groupID")?.object(forKey: "clientKey"))
    }

    func testMigrateGroupWithMultipleUsers() {
        userDefaults.setMPObject(Date(), forKey: "lud", userId: 1)
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.max))
        userDefaults.setMPObject(Date(), forKey: "lud", userId: NSNumber(value: Int64.min))

        userDefaults.setSharedGroupIdentifier("groupID")

        let array = userDefaults.userIDsInUserDefaults()

        XCTAssert(array.contains(NSNumber(value: 1)))
        XCTAssert(array.contains(NSNumber(value: Int64.max)))
        XCTAssert(array.contains(NSNumber(value: Int64.min)))
    }

    func testValidConfiguration() {
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
    }

    func testCompressedConfigurationRoundTrip() {
        connector.compressConfigurationStorageReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let storedData = userDefaults.mpObject(forKey: "responseConfiguration", userId: connector.userId() ?? 0) as? Data
            else {
            XCTFail("Expected stored configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(storedData))
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
    }

    func testCompressionFlagMirroredToSharedGroup() {
        connector.compressConfigurationStorageReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970
        let largeConfiguration = buildLargeFilterConfiguration()

        userDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )
        userDefaults.setSharedGroupIdentifier("groupID")

        let groupDefaults = UserDefaults(suiteName: "groupID")
        XCTAssertEqual(
            groupDefaults?.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
    }

    func testConfigurationRestoreReadsCompressionFlagFromSharedGroup() {
        connector.compressConfigurationStorageReturnValue = true
        connector.canCreateConfigurationReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970
        let largeConfiguration = buildLargeFilterConfiguration()
        let standardDefaults = MPUserDefaults.standardUserDefaults(connector: connector)

        standardDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )
        standardDefaults.setSharedGroupIdentifier("groupID")
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        let restoredResponseConfig = MPUserDefaults.restore()
        XCTAssertNotNil(restoredResponseConfig)
        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            restoredResponseConfig?.configuration as NSDictionary?
        )
    }

    func testDeleteConfigurationRemovesCompressionFlagFromSharedGroup() {
        connector.compressConfigurationStorageReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )
        userDefaults.setSharedGroupIdentifier("groupID")

        userDefaults.deleteConfiguration()

        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
        XCTAssertNil(UserDefaults(suiteName: "groupID")?.object(forKey: kMResponseConfigurationCompressedKey))
    }

    func testMigrateUncompressedConfigurationToCompressed() {
        let requestTimestamp = Date().timeIntervalSince1970
        connector.compressConfigurationStorageReturnValue = false
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        let largeConfiguration = buildLargeFilterConfiguration()

        userDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let uncompressedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected stored configuration data")
            return
        }

        XCTAssertFalse(MPZipPRIVATE.isGzipCompressedData(uncompressedData))
        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))

        connector.compressConfigurationStorageReturnValue = true

        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )

        guard let migratedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected migrated configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(migratedData))
        XCTAssertLessThan(migratedData.count, uncompressedData.count)
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
    }

    func testMigrateCompressedConfigurationToUncompressed() {
        connector.compressConfigurationStorageReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970
        let largeConfiguration = buildLargeFilterConfiguration()

        userDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let compressedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected stored configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(compressedData))
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )

        connector.compressConfigurationStorageReturnValue = false

        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )

        guard let migratedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected migrated configuration data")
            return
        }

        XCTAssertFalse(MPZipPRIVATE.isGzipCompressedData(migratedData))
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            false
        )
    }

    func testMissingCompressionFlagTreatedAsUncompressed() throws {
        let largeConfiguration = buildLargeFilterConfiguration()
        let userID = connector.userId() ?? 0
        let archivedData = try NSKeyedArchiver.archivedData(
            withRootObject: largeConfiguration,
            requiringSecureCoding: true
        )

        userDefaults.setMPObject(archivedData, forKey: kMResponseConfigurationKey, userId: userID)
        userDefaults.setMPObject(eTag, forKey: Miscellaneous.kMPHTTPETagHeaderKey, userId: userID)
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        connector.compressConfigurationStorageReturnValue = false

        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
    }

    func testUncompressedConfigurationDoesNotPersistCompressionFlag() {
        connector.compressConfigurationStorageReturnValue = false
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: Date().timeIntervalSince1970,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
    }

    func testMissingCompressionFlagDoesNotTreatGzipDataAsCompressed() {
        connector.compressConfigurationStorageReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970
        let largeConfiguration = buildLargeFilterConfiguration()

        userDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let compressedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected stored configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(compressedData))
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        XCTAssertNil(userDefaults.getConfiguration())
    }

    func testMigrateUncompressedLegacyWithoutStoredFlag() throws {
        let largeConfiguration = buildLargeFilterConfiguration()
        let userID = connector.userId() ?? 0
        let archivedData = try NSKeyedArchiver.archivedData(
            withRootObject: largeConfiguration,
            requiringSecureCoding: true
        )

        userDefaults.setMPObject(archivedData, forKey: kMResponseConfigurationKey, userId: userID)
        userDefaults.setMPObject(eTag, forKey: Miscellaneous.kMPHTTPETagHeaderKey, userId: userID)
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        connector.compressConfigurationStorageReturnValue = true

        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )

        guard let migratedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: userID
        ) as? Data else {
            XCTFail("Expected migrated configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(migratedData))
        XCTAssertLessThan(migratedData.count, archivedData.count)
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
    }

    func testMigrateConfigurationCompressionDirectCall() {
        let requestTimestamp = Date().timeIntervalSince1970
        connector.compressConfigurationStorageReturnValue = false
        let largeConfiguration = buildLargeFilterConfiguration()

        userDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let uncompressedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected stored configuration data")
            return
        }

        connector.compressConfigurationStorageReturnValue = true
        userDefaults.migrateConfigurationCompression()

        guard let migratedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected migrated configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(migratedData))
        XCTAssertLessThan(migratedData.count, uncompressedData.count)
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
    }

    func testConfigurationCompressionMigrationIsIdempotent() {
        let requestTimestamp = Date().timeIntervalSince1970
        connector.compressConfigurationStorageReturnValue = false

        userDefaults.setConfiguration(
            buildLargeFilterConfiguration(),
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        connector.compressConfigurationStorageReturnValue = true
        _ = userDefaults.getConfiguration()

        guard let migratedData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected migrated configuration data")
            return
        }

        _ = userDefaults.getConfiguration()
        userDefaults.migrateConfigurationCompression()

        guard let secondReadData = userDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected stored configuration data after second read")
            return
        }

        XCTAssertEqual(migratedData, secondReadData)
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
    }

    func testRestoreMigratesUncompressedConfigurationToCompressed() {
        let standardDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        standardDefaults.deleteConfiguration()
        connector.canCreateConfigurationReturnValue = true

        let requestTimestamp = Date().timeIntervalSince1970
        let largeConfiguration = buildLargeFilterConfiguration()
        connector.compressConfigurationStorageReturnValue = false

        standardDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let uncompressedData = standardDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected stored configuration data")
            return
        }

        connector.compressConfigurationStorageReturnValue = true

        let restoredResponseConfig = MPUserDefaults.restore()
        XCTAssertNotNil(restoredResponseConfig)
        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            restoredResponseConfig?.configuration as NSDictionary?
        )

        guard let migratedData = standardDefaults.mpObject(
            forKey: kMResponseConfigurationKey,
            userId: connector.userId() ?? 0
        ) as? Data else {
            XCTFail("Expected migrated configuration data")
            return
        }

        XCTAssertTrue(MPZipPRIVATE.isGzipCompressedData(migratedData))
        XCTAssertLessThan(migratedData.count, uncompressedData.count)
        XCTAssertEqual(
            UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey) as? Bool,
            true
        )
    }

    func testMigrateConfigurationCompressionDoesNotCreateUncompressedFlag() {
        let requestTimestamp = Date().timeIntervalSince1970
        connector.compressConfigurationStorageReturnValue = false

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationCompressedKey)

        userDefaults.migrateConfigurationCompression()

        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
    }

    func testLargeFilterConfigurationCompressionReducesStoredSize() {
        connector.compressConfigurationStorageReturnValue = true

        let brazeConfiguration: [String: Any] = [
            "id": 28,
            "as": ["apiKey": "test-key"],
            "hs": [
                "ec": (0..<5000).reduce(into: [String: Int]()) { $0["\($1)"] = 0 },
                "ea": (0..<5000).reduce(into: [String: Int]()) { $0["\($1)"] = 0 }
            ]
        ]

        let largeConfiguration = buildResponseConfiguration(for: [brazeConfiguration])
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            largeConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        guard let storedData = userDefaults.mpObject(forKey: "responseConfiguration", userId: connector.userId() ?? 0) as? Data
            else {
            XCTFail("Expected stored configuration data")
            return
        }

        guard let archivedData = MPZipPRIVATE.decompressedData(from: storedData) else {
            XCTFail("Expected compressed stored configuration data")
            return
        }

        XCTAssertLessThan(storedData.count, archivedData.count)
        XCTAssertEqual(
            largeConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
    }

    func testNullConfig() {
        let configuration1: [String: Any] = [
            "id": 42,
            "as": [
                "appId": "cool app key Update Test",
                "foo": NSNull()
            ]
        ]
        let requestTimestamp = Date().timeIntervalSince1970
        userDefaults.setConfiguration(
            configuration1,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertEqual(
            configuration1 as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
    }

    func testSetConfigurationWhenNil() {
        XCTAssertNil(userDefaults.getConfiguration())

        let requestTimestamp = Date().timeIntervalSince1970
        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as NSDictionary?
        )
    }

    func testStringFromDeviceToken() {
        var data = Data()
        var tokenString = MPUserDefaults.stringFromDeviceToken(data)

        XCTAssertNil(tokenString)

        data = Data([0x0F])
        tokenString = MPUserDefaults.stringFromDeviceToken(data)

        XCTAssertEqual(tokenString, "0f")
    }

    func testMigrateConfiguration() {
        let userID: NSNumber = 1234
        let kMResponseConfigurationMigrationKey = "responseConfigurationMigrated"
        let kMPHTTPETagHeaderKey = "ETag"
        UserDefaults.standard.removeObject(forKey: kMResponseConfigurationMigrationKey)

        userDefaults.removeMPObject(forKey: kMPHTTPETagHeaderKey, userId: userID)
        XCTAssertNil(userDefaults.getConfiguration())

        XCTAssertNotNil(UserDefaults.standard.object(forKey: kMResponseConfigurationMigrationKey))
    }

    func testBadDataConfiguration() {
        userDefaults.deleteConfiguration()
        let kMResponseConfigurationKey = "responseConfiguration"
        let userID: NSNumber = 123

        let badBytes: [UInt8] = [0x01, 0x02, 0x03, 0x04, 0x05, 0x04, 0x01, 0x00, 0x0F]
        let badData = Data(badBytes)

        userDefaults.setMPObject(
            badData,
            forKey: kMResponseConfigurationKey,
            userId: userID
        )

        XCTAssertNil(userDefaults.getConfiguration())
    }

    func testDeleteConfiguration() {
        connector.compressConfigurationStorageReturnValue = true
        let requestTimestamp = Date().timeIntervalSince1970
        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertNotNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))

        userDefaults.deleteConfiguration()
        XCTAssertNil(userDefaults.getConfiguration())
        XCTAssertNil(UserDefaults.standard.object(forKey: kMResponseConfigurationCompressedKey))
    }

    func testValidExpandedConfigurationNoMaxAge() {
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 4000,
            maxAge: NSNumber(value: 90000)
        )

        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber,
            NSNumber(value: requestTimestamp - 4000)
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigMaxAgeHeaderKey] as? NSNumber,
            NSNumber(value: 90000)
        )

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 4000,
            maxAge: nil
        )

        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber,
            NSNumber(value: requestTimestamp - 4000)
        )

        XCTAssertNil(userDefaults[Miscellaneous.kMPConfigMaxAgeHeaderKey])
    }

    func testValidExpandedConfigurationWithNilCurrentAge() {
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0.0,
            maxAge: NSNumber(value: 90000)
        )

        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber,
            NSNumber(value: requestTimestamp)
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigMaxAgeHeaderKey] as? NSNumber,
            NSNumber(value: 90000)
        )
    }

    func testValidExpandedConfiguration() {
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 4000,
            maxAge: NSNumber(value: 90000)
        )

        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigProvisionedTimestampKey] as? NSNumber,
            NSNumber(value: requestTimestamp - 4000)
        )

        XCTAssertEqual(
            userDefaults[Miscellaneous.kMPConfigMaxAgeHeaderKey] as? NSNumber,
            NSNumber(value: 90000)
        )
    }

    func testUpdateConfigurations() {
        let responseConfiguration: [String: Any] = buildResponseConfiguration(for: [configuration1])
        let requestTimestamp = Date().timeIntervalSince1970

        userDefaults.setConfiguration(
            responseConfiguration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertNotNil(userDefaults.getConfiguration())
        XCTAssertEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )

        let responseConfiguration2: [String: Any] = buildResponseConfiguration(for: [configuration1, configuration2])

        userDefaults.setConfiguration(
            responseConfiguration2,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertNotEqual(
            responseConfiguration as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )

        XCTAssertEqual(
            responseConfiguration2 as NSDictionary,
            userDefaults.getConfiguration() as? NSDictionary
        )
    }

    func testDeleteDueToMaxConfigAge() {
        let userDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        userDefaults.deleteConfiguration()
        connector.configMaxAgeSecondsReturnValue = 1

        let configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]

        XCTAssertNil(userDefaults.getConfiguration())
        let requestTimestamp = Date().timeIntervalSince1970 - 100

        userDefaults.setConfiguration(
            configuration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )
        XCTAssertNotNil(userDefaults.getConfiguration())

        XCTAssertTrue(MPUserDefaults.isOlderThanConfigMaxAgeSeconds())
        if MPUserDefaults.isOlderThanConfigMaxAgeSeconds() {
            MPUserDefaults.deleteConfig()
        }
        XCTAssertNil(userDefaults.getConfiguration())
    }

    func testShouldDeleteDueToMaxConfigAge() {
        let userDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        userDefaults.deleteConfiguration()
        connector.configMaxAgeSecondsReturnValue = 60

        let configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]
        let requestTimestamp = Date().timeIntervalSince1970
        userDefaults.setConfiguration(
            configuration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertFalse(MPUserDefaults.isOlderThanConfigMaxAgeSeconds())

        userDefaults.setConfiguration(
            configuration,
            eTag: eTag,
            requestTimestamp: requestTimestamp - 100.0,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertTrue(MPUserDefaults.isOlderThanConfigMaxAgeSeconds())
    }

    func testShouldDeleteDueToMaxConfigAgeWhenNil() {
        connector.configMaxAgeSecondsReturnValue = nil

        let configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]

        let requestTimestamp = Date().timeIntervalSince1970
        userDefaults.setConfiguration(
            configuration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        XCTAssertFalse(MPUserDefaults.isOlderThanConfigMaxAgeSeconds())

        userDefaults.setConfiguration(
            configuration,
            eTag: eTag,
            requestTimestamp: requestTimestamp - 1000.0,
            currentAge: 0,
            maxAge: nil
        )
        XCTAssertFalse(MPUserDefaults.isOlderThanConfigMaxAgeSeconds())
    }

    func testSaveRestore() {
        let userDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        userDefaults.deleteConfiguration()
        connector.canCreateConfigurationReturnValue = true

        var configuration: [String: Any] = [
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]

        let requestTimestamp = Date().timeIntervalSince1970
        userDefaults.setConfiguration(
            configuration,
            eTag: eTag,
            requestTimestamp: requestTimestamp,
            currentAge: 0,
            maxAge: nil
        )

        configuration = [
            RemoteConfig.kMPRemoteConfigRampKey: 100,
            RemoteConfig.kMPRemoteConfigExceptionHandlingModeKey: RemoteConfig.kMPRemoteConfigExceptionHandlingModeForce,
            RemoteConfig.kMPRemoteConfigSessionTimeoutKey: 112
        ]

        let restoredResponseConfig = MPUserDefaults.restore()
        XCTAssertNotNil(restoredResponseConfig)
        XCTAssertEqual(
            (restoredResponseConfig?.configuration as! [String: Any]) as NSDictionary,
            configuration as NSDictionary
        )
    }

    // MARK: - Thread Safety Tests

    func testUserDefaultsSingletonThreadSafety() {
        // Stress test to verify the singleton accessor is thread-safe
        // This tests the fix for the race condition in standardUserDefaults()

        let expectation = self.expectation(description: "Thread safety test completed")

        let group = DispatchGroup()
        let concurrentQueue = DispatchQueue(
            label: "com.mparticle.test.userdefaults.concurrent",
            attributes: .concurrent
        )

        let iterations = 1000

        for i in 0..<iterations {
            // Concurrent reads of the singleton
            group.enter()
            concurrentQueue.async {
                let defaults = MPUserDefaults.standardUserDefaults(connector: self.connector)
                XCTAssertNotNil(defaults)

                // Concurrent reads/writes to user defaults
                let key = "testKey_\(i % 10)"
                defaults.setMPObject(NSNumber(value: i), forKey: key, userId: 1)
                let value = defaults.mpObject(forKey: key, userId: 1)
                // Value may or may not match due to concurrent writes - that's expected
                _ = value
                group.leave()
            }

            // Also test static class methods concurrently
            group.enter()
            concurrentQueue.async {
                _ = MPUserDefaults.isOlderThanConfigMaxAgeSeconds()
                group.leave()
            }

            group.enter()
            concurrentQueue.async {
                _ = MPUserDefaults.restore()
                group.leave()
            }

            group.enter()
            concurrentQueue.async {
                MPUserDefaults.deleteConfig()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30, handler: nil)
    }
}
