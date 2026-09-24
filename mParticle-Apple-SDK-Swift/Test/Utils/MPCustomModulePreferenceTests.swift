import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPCustomModulePreferenceTests: XCTestCase {
    private let connector = MPUserDefaultsConnectorMock()

    /// The tests below name their own read keys, so they allow whatever key the dictionary asks
    /// for unless a test is specifically about the allow-list.
    private func makePreference(_ dictionary: [AnyHashable: Any],
                                location: String? = "NSUserDefaults",
                                moduleId: NSNumber = 28,
                                allowedPreferenceKeys: Set<String>? = nil) -> CustomModulePreference? {
        let allowed = allowedPreferenceKeys
            ?? Set([dictionary[CustomModuleConfigKey.readKey] as? String].compactMap { $0 })
        return CustomModulePreference(dictionary: dictionary,
                                      location: location,
                                      moduleId: moduleId,
                                      connector: connector,
                                      allowedPreferenceKeys: allowed,
                                      logger: MPLog(logLevel: .none))
    }

    // MARK: - Allow-list

    func testReadKeyOutsideTheAllowListIsRejected() {
        // Rejected at construction rather than at read time, so there is no object left to resolve
        // the value or write it to the cache.
        XCTAssertNil(makePreference(["k": "mp.test.session_token", "n": "tok"],
                                    allowedPreferenceKeys: CustomModulePreferenceAllowList.defaultKeys))
    }

    func testReadKeyInsideTheAllowListIsAccepted() {
        for key in CustomModulePreferenceAllowList.defaultKeys {
            let preference = makePreference(["k": key, "n": "write"],
                                            allowedPreferenceKeys: CustomModulePreferenceAllowList.defaultKeys)
            XCTAssertEqual(preference?.readKey, key, "\(key) is one of the keys the feature exists to carry")
        }
    }

    func testAnEmptyAllowListAcceptsNothing() {
        XCTAssertNil(makePreference(["k": "ADOBEMOBILE_STOREDDEFAULTS_AID", "n": "aid"],
                                    allowedPreferenceKeys: []))
    }

    // MARK: - Required keys

    func testMissingReadKeyIsRejected() {
        XCTAssertNil(makePreference(["n": "write"]))
    }

    func testMissingWriteKeyIsRejected() {
        XCTAssertNil(makePreference(["k": "read"]))
    }

    func testNonStringKeysAreRejected() {
        XCTAssertNil(makePreference(["k": 1, "n": "write"]))
        XCTAssertNil(makePreference(["k": "read", "n": NSNull()]))
    }

    func testKeysAreCarriedThrough() {
        let preference = makePreference(["k": "read", "n": "write"])
        XCTAssertEqual(preference?.readKey, "read")
        XCTAssertEqual(preference?.writeKey, "write")
        XCTAssertEqual(preference?.moduleId, 28)
    }

    // MARK: - Data type

    func testDataTypeDefaultsToStringWhenAbsent() {
        XCTAssertEqual(makePreference(["k": "read", "n": "write"])?.dataType,
                       CustomModuleDataType.string.rawValue)
    }

    func testDataTypeDefaultsToStringWhenNotANumber() {
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": "2"])?.dataType,
                       CustomModuleDataType.string.rawValue)
    }

    func testDataTypeIsReadFromConfig() {
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": 4])?.dataType,
                       CustomModuleDataType.float.rawValue)
    }

    // MARK: - Default value resolution

    func testLiteralDefaultValueIsUsedVerbatim() {
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "d": "hello"])?.defaultValue, "hello")
    }

    func testMacroPlaceholderIsExpanded() {
        let preference = makePreference(["k": "read", "n": "write", "d": "%gn%"])
        let expanded = preference?.defaultValue
        XCTAssertEqual(expanded?.count, 32, "an undashed UUID is 32 characters")
        XCTAssertFalse(expanded?.contains("-") ?? true)
    }

    func testAbsentDefaultFallsBackToDataTypeDefault() {
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": 3])?.defaultValue, "false")
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": 2])?.defaultValue, "0")
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": 4])?.defaultValue, "0.0")
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": 1])?.defaultValue, "")
    }

    func testNonStringDefaultFallsBackToDataTypeDefault() {
        XCTAssertEqual(makePreference(["k": "read", "n": "write", "t": 2, "d": 7])?.defaultValue, "0")
    }

    /// The header this replaced annotated defaultValue nonnull, but an unrecognised data type
    /// has always left it unset. MPCustomModuleTests asserts the same thing through ObjC.
    func testUnrecognisedDataTypeLeavesDefaultValueNil() {
        XCTAssertNil(makePreference(["k": "read", "n": "write", "t": 99])?.defaultValue)
    }

    // MARK: - Value resolution

    func testValueFallsBackToTypedDefaultWhenNothingStored() {
        let readKey = "mp.test.absent.\(#function)"
        let writeKey = "mp.test.write.\(#function)"
        let preference = makePreference(["k": readKey, "n": writeKey, "t": 2, "d": "12"])

        XCTAssertEqual(preference?.value as? NSNumber, 12)

        cleanUp(writeKey: writeKey)
    }

    func testValueIsNilWhenDataTypeIsUnrecognised() {
        let readKey = "mp.test.unrecognised.\(#function)"
        let writeKey = "mp.test.write.unrecognised.\(#function)"
        let preference = makePreference(["k": readKey, "n": writeKey, "t": 99])

        XCTAssertNil(preference?.value)

        cleanUp(writeKey: writeKey)
    }

    func testValueReadsThroughFromStandardUserDefaults() {
        let readKey = "mp.test.present.\(#function)"
        let writeKey = "mp.test.write.present.\(#function)"
        UserDefaults.standard.set("stored", forKey: readKey)
        defer { UserDefaults.standard.removeObject(forKey: readKey) }

        let preference = makePreference(["k": readKey, "n": writeKey, "t": 1, "d": "unused"])
        XCTAssertEqual(preference?.value as? String, "stored")

        cleanUp(writeKey: writeKey)
    }

    private func cleanUp(writeKey: String) {
        let userDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        userDefaults.removeMPObject(forKey: "cms::28::\(writeKey)", userId: connector.mpId())
    }
}
