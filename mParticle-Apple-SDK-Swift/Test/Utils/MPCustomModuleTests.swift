import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPCustomModuleSwiftTests: XCTestCase {
    private let connector = MPUserDefaultsConnectorMock()

    private func makeModule(_ dictionary: [AnyHashable: Any]) -> CustomModule? {
        return CustomModule(dictionary: dictionary, connector: connector)
    }

    private func configuration(preferenceSettings: [[AnyHashable: Any]],
                               location: Any? = "NSUserDefaults",
                               moduleId: Any? = 28) -> [AnyHashable: Any] {
        var group: [AnyHashable: Any] = ["ps": preferenceSettings]
        if let location = location {
            group["f"] = location
        }
        var configuration: [AnyHashable: Any] = ["pr": [group]]
        if let moduleId = moduleId {
            configuration["id"] = moduleId
        }
        return configuration
    }

    // MARK: - Required shape

    func testMissingModuleIdIsRejected() {
        XCTAssertNil(makeModule(configuration(preferenceSettings: [["k": "r", "n": "w"]], moduleId: nil)))
    }

    func testNonNumberModuleIdIsRejected() {
        XCTAssertNil(makeModule(configuration(preferenceSettings: [["k": "r", "n": "w"]], moduleId: "28")))
    }

    func testMissingPreferencesIsRejected() {
        XCTAssertNil(makeModule(["id": 28]))
    }

    func testNonArrayPreferencesIsRejected() {
        XCTAssertNil(makeModule(["id": 28, "pr": "not an array"]))
    }

    // MARK: - Preference parsing

    func testPreferencesAreParsed() {
        let module = makeModule(configuration(preferenceSettings: [
            ["k": "read1", "n": "write1"],
            ["k": "read2", "n": "write2"]
        ]))

        XCTAssertEqual(module?.customModuleId, 28)
        XCTAssertEqual(module?.preferences?.count, 2)
        XCTAssertEqual(module?.preferences?.first?.readKey, "read1")
    }

    /// Matches the ObjC original: an empty result is nil rather than an empty array.
    func testNoValidPreferencesYieldsNilRatherThanEmptyArray() {
        let module = makeModule(configuration(preferenceSettings: [["n": "write-without-read"]]))
        XCTAssertNotNil(module)
        XCTAssertNil(module?.preferences)
    }

    func testInvalidPreferenceEntriesAreSkipped() {
        let module = makeModule(configuration(preferenceSettings: [
            ["k": "good", "n": "good"],
            ["n": "missing read key"]
        ]))
        XCTAssertEqual(module?.preferences?.count, 1)
    }

    func testAbsentLocationDefaultsRatherThanSkipping() {
        let module = makeModule(configuration(preferenceSettings: [["k": "r", "n": "w"]], location: nil))
        XCTAssertEqual(module?.preferences?.count, 1)
    }

    // MARK: - Dictionary representation

    func testDictionaryRepresentationKeysOnWriteKey() {
        let module = makeModule(configuration(preferenceSettings: [
            ["k": "mp.test.module.read", "n": "mp.test.module.write", "t": 1, "d": "value"]
        ]))

        let representation = module?.dictionaryRepresentation()
        XCTAssertEqual(representation?["mp.test.module.write"] as? String, "value")

        cleanUp(writeKeys: ["mp.test.module.write"])
    }

    func testDictionaryRepresentationIsMemoised() {
        let module = makeModule(configuration(preferenceSettings: [
            ["k": "mp.test.memo.read", "n": "mp.test.memo.write", "t": 1, "d": "value"]
        ]))

        let first = module?.dictionaryRepresentation() as NSDictionary?
        let second = module?.dictionaryRepresentation() as NSDictionary?
        XCTAssertEqual(first, second)

        cleanUp(writeKeys: ["mp.test.memo.write"])
    }

    // MARK: - Equality and copying

    func testEqualityComparesDictionaryRepresentation() {
        let configuration = configuration(preferenceSettings: [
            ["k": "mp.test.eq.read", "n": "mp.test.eq.write", "t": 1, "d": "value"]
        ])
        let first = makeModule(configuration)
        let second = makeModule(configuration)

        XCTAssertEqual(first, second)
        XCTAssertNotEqual(first, NSObject())
        XCTAssertEqual(first?.hash, second?.hash)

        cleanUp(writeKeys: ["mp.test.eq.write"])
    }

    /// Shallow, as before: the copy shares its preference objects with the original.
    func testCopyIsEqualAndSharesPreferences() {
        let module = makeModule(configuration(preferenceSettings: [
            ["k": "mp.test.copy.read", "n": "mp.test.copy.write", "t": 1, "d": "value"]
        ]))
        let copy = module?.copy() as? CustomModule

        XCTAssertEqual(copy?.customModuleId, module?.customModuleId)
        XCTAssertEqual(copy?.preferences?.count, module?.preferences?.count)
        XCTAssertTrue(copy?.preferences?.first === module?.preferences?.first)
        XCTAssertFalse(copy === module)

        cleanUp(writeKeys: ["mp.test.copy.write"])
    }

    private func cleanUp(writeKeys: [String]) {
        let userDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        for writeKey in writeKeys {
            userDefaults.removeMPObject(forKey: "cms::28::\(writeKey)", userId: connector.mpId())
        }
    }
}
