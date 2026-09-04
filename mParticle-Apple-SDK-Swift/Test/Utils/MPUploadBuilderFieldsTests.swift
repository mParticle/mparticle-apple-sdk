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

    // MARK: - headerFields

    func testHeaderFieldsContainsEveryField() {
        let fields = MPUploadBuilderFields.headerFields(
            messageId: "uuid-1",
            timestampMs: 123456,
            sdkVersion: "9.4.1",
            apiKey: "key-1"
        )

        XCTAssertEqual(fields["dt"] as? String, "h")
        XCTAssertEqual(fields["sdk"] as? String, "9.4.1")
        XCTAssertEqual(fields["id"] as? String, "uuid-1")
        XCTAssertEqual(fields["ct"] as? NSNumber, 123456)
        XCTAssertEqual(fields["a"] as? String, "key-1")
    }

    func testHeaderFieldsOmitsApplicationKeyWhenApiKeyIsNil() {
        let fields = MPUploadBuilderFields.headerFields(
            messageId: "uuid-1",
            timestampMs: 123456,
            sdkVersion: "9.4.1",
            apiKey: nil
        )

        XCTAssertNil(fields["a"])
    }

    // MARK: - deviceInfoDictionary(byAddingAdvertiserId:isATTAuthorized:to:)

    func testDeviceInfoDictionaryAddsAdvertiserIdWhenAuthorized() {
        let result = MPUploadBuilderFields.deviceInfoDictionary(
            byAddingAdvertiserId: "aid-1",
            isATTAuthorized: true,
            to: ["existing": "value"]
        )

        XCTAssertEqual(result?["aid"] as? String, "aid-1")
        XCTAssertEqual(result?["existing"] as? String, "value")
    }

    func testDeviceInfoDictionaryIsNilWhenNotAuthorized() {
        XCTAssertNil(MPUploadBuilderFields.deviceInfoDictionary(
            byAddingAdvertiserId: "aid-1",
            isATTAuthorized: false,
            to: ["existing": "value"]
        ))
    }

    func testDeviceInfoDictionaryIsNilWithoutAnAdvertiserId() {
        XCTAssertNil(MPUploadBuilderFields.deviceInfoDictionary(
            byAddingAdvertiserId: nil,
            isATTAuthorized: true,
            to: ["existing": "value"]
        ))
    }

    func testDeviceInfoDictionaryIsNilWithoutAnExistingDictionary() {
        XCTAssertNil(MPUploadBuilderFields.deviceInfoDictionary(
            byAddingAdvertiserId: "aid-1",
            isATTAuthorized: true,
            to: nil
        ))
    }

    // MARK: - forwardRecordBatch

    func testForwardRecordBatchKeepsOnlyRecordsWithADataDictionary() {
        let batch = MPUploadBuilderFields.forwardRecordBatch(
            dataDictionaries: [["a": 1], NSNull(), ["b": 2]],
            recordIds: [10, 20, 30]
        )

        XCTAssertEqual(batch.dataDictionaries as? [[String: Int]], [["a": 1], ["b": 2]])
        XCTAssertEqual(batch.recordIds, [10, 30])
    }

    func testForwardRecordBatchIsEmptyWhenNoRecordHasData() {
        let batch = MPUploadBuilderFields.forwardRecordBatch(
            dataDictionaries: [NSNull(), NSNull()],
            recordIds: [10, 20]
        )

        XCTAssertTrue(batch.dataDictionaries.isEmpty)
        XCTAssertTrue(batch.recordIds.isEmpty)
    }

    // MARK: - mergedIntegrationAttributesDictionary

    func testMergedIntegrationAttributesDictionaryMergesAllEntries() {
        let merged = MPUploadBuilderFields.mergedIntegrationAttributesDictionary(from: [
            ["a": "1"],
            ["b": "2"]
        ])

        XCTAssertEqual(merged["a"] as? String, "1")
        XCTAssertEqual(merged["b"] as? String, "2")
    }

    func testMergedIntegrationAttributesDictionaryLaterEntryWinsOnCollision() {
        let merged = MPUploadBuilderFields.mergedIntegrationAttributesDictionary(from: [
            ["a": "1"],
            ["a": "2"]
        ])

        XCTAssertEqual(merged["a"] as? String, "2")
    }

    func testMergedIntegrationAttributesDictionaryIsEmptyForNoAttributes() {
        XCTAssertTrue(MPUploadBuilderFields.mergedIntegrationAttributesDictionary(from: []).isEmpty)
    }
}
