import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUploadBuilderFieldsTests: XCTestCase {
    // MARK: - seedDictionary

    func testSeedDictionaryContainsAllThreeFields() {
        let dictionary = MPUploadBuilderFields.seedDictionary(optOut: true, uploadInterval: 30, lifetimeValue: 42)

        XCTAssertEqual(dictionary["oo"] as? Bool, true)
        XCTAssertEqual(dictionary["uitl"] as? TimeInterval, 30)
        XCTAssertEqual(dictionary["ltv"] as? NSNumber, 42)
    }

    // MARK: - dataPlanDictionary

    func testDataPlanDictionaryIsNilWithoutADataPlanId() {
        XCTAssertNil(MPUploadBuilderFields.dataPlanDictionary(dataPlanId: nil, dataPlanVersion: 3))
    }

    func testDataPlanDictionaryWithIdOnly() {
        let dictionary = MPUploadBuilderFields.dataPlanDictionary(dataPlanId: "plan1", dataPlanVersion: nil)

        let inner = dictionary?["dpln"] as? [String: Any]
        XCTAssertEqual(inner?["id"] as? String, "plan1")
        XCTAssertNil(inner?["v"])
    }

    func testDataPlanDictionaryWithIdAndVersion() {
        let dictionary = MPUploadBuilderFields.dataPlanDictionary(dataPlanId: "plan1", dataPlanVersion: 5)

        let inner = dictionary?["dpln"] as? [String: Any]
        XCTAssertEqual(inner?["id"] as? String, "plan1")
        XCTAssertEqual(inner?["v"] as? NSNumber, 5)
    }

    // MARK: - customModulesDictionary

    func testCustomModulesDictionaryIsNilForNilInput() {
        XCTAssertNil(MPUploadBuilderFields.customModulesDictionary(from: nil))
    }

    func testCustomModulesDictionaryIsEmptyForAnEmptyArray() {
        XCTAssertEqual(MPUploadBuilderFields.customModulesDictionary(from: [])?.isEmpty, true)
    }

    func testCustomModulesDictionaryKeysByStringifiedModuleId() throws {
        let connector = MPUserDefaultsConnectorMock()
        let group: [AnyHashable: Any] = ["ps": [["k": "r", "n": "w"]], "f": "NSUserDefaults"]
        let module = try XCTUnwrap(CustomModule(
            dictionary: ["id": 7, "pr": [group]],
            connector: connector
        ))

        let dictionary = MPUploadBuilderFields.customModulesDictionary(from: [module])

        XCTAssertNotNil(dictionary?["7"])
    }

    // MARK: - stringifiedUserAttributes

    func testStringifiedUserAttributesStringifiesNumbers() {
        let result = MPUploadBuilderFields.stringifiedUserAttributes(["age": NSNumber(value: 30)])
        XCTAssertEqual(result["age"] as? String, "30")
    }

    func testStringifiedUserAttributesLeavesNonNumbersUntouched() {
        let result = MPUploadBuilderFields.stringifiedUserAttributes(["color": "blue"])
        XCTAssertEqual(result["color"] as? String, "blue")
    }
}
