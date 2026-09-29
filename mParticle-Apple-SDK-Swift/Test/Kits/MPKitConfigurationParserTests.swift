import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitConfigurationParserTests: XCTestCase {
    // MARK: - attribute value filtering

    func testAttributeValueFilterIsInactiveWithoutAnAVFBlock() {
        for configuration in [nil, [:], ["avf": NSNull()]] as [[AnyHashable: Any]?] {
            XCTAssertFalse(MPKitConfigurationParser.attributeValueFilter(from: configuration).isActive)
        }
    }

    func testAttributeValueFilterNeedsAllThreeKeys() {
        let cases: [[AnyHashable: Any]] = [
            ["i": true, "a": 1],
            ["i": true, "v": 2],
            ["a": 1, "v": 2]
        ]

        for avf in cases {
            XCTAssertFalse(
                MPKitConfigurationParser.attributeValueFilter(from: ["avf": avf]).isActive,
                "\(avf)"
            )
        }
    }

    func testAttributeValueFilterReadsAllThreeKeys() {
        let filter = MPKitConfigurationParser.attributeValueFilter(
            from: ["avf": ["i": true, "a": 1234, "v": 5678]]
        )

        XCTAssertTrue(filter.isActive)
        XCTAssertTrue(filter.shouldIncludeMatches)
        XCTAssertEqual(filter.hashedAttribute, "1234")
        XCTAssertEqual(filter.hashedValue, "5678")
    }

    func testAttributeValueFilterIsInactiveForANullIncludeFlag() {
        XCTAssertFalse(
            MPKitConfigurationParser.attributeValueFilter(
                from: ["avf": ["i": NSNull(), "a": 1, "v": 2]]
            ).isActive
        )
    }

    func testANullAttributeOrValueStillActivatesAndStringifiesAsNull() {
        // Only `i` was null-guarded; `a` and `v` were plain non-nil checks, so
        // NSNull passed through %@ as "<null>".
        let filter = MPKitConfigurationParser.attributeValueFilter(
            from: ["avf": ["i": false, "a": NSNull(), "v": NSNull()]]
        )

        XCTAssertTrue(filter.isActive)
        XCTAssertFalse(filter.shouldIncludeMatches)
        XCTAssertEqual(filter.hashedAttribute, "<null>")
        XCTAssertEqual(filter.hashedValue, "<null>")
    }

    func testAttributeValueFilterAcceptsStringEncodedValues() {
        let filter = MPKitConfigurationParser.attributeValueFilter(
            from: ["avf": ["i": "true", "a": "abc", "v": "def"]]
        )

        XCTAssertTrue(filter.shouldIncludeMatches)
        XCTAssertEqual(filter.hashedAttribute, "abc")
        XCTAssertEqual(filter.hashedValue, "def")
    }

    // MARK: - filters

    func testSanitizedFiltersDropsNullValues() {
        let filters = MPKitConfigurationParser.sanitizedFilters(from: [
            "et": ["1": 0],
            "ec": NSNull()
        ])

        XCTAssertEqual(filters?.count, 1)
        XCTAssertNotNil(filters?["et"])
        XCTAssertNil(filters?["ec"])
    }

    func testSanitizedFiltersIsNilWhenEmptyOrAbsent() {
        XCTAssertNil(MPKitConfigurationParser.sanitizedFilters(from: nil))
        XCTAssertNil(MPKitConfigurationParser.sanitizedFilters(from: NSNull()))
        XCTAssertNil(MPKitConfigurationParser.sanitizedFilters(from: [:]))
        XCTAssertNil(MPKitConfigurationParser.sanitizedFilters(from: ["ec": NSNull()]))
    }

    // MARK: - dropping unusable kits

    func testUnusableKitEntriesAreDroppedBeforeStorage() {
        let configuration: [AnyHashable: Any] = [
            "dt": "ac",
            "eks": [
                "not-an-object",
                ["as": ["appId": "entry carrying no id"]],
                ["id": "80"],
                ["id": 42, "as": ["appId": "usable"]]
            ]
        ]

        let sanitized = MPKitConfigurationParser.configurationDroppingUnusableKits(from: configuration)
        let kits = sanitized["eks"] as? [[AnyHashable: Any]]

        XCTAssertEqual(kits?.count, 1)
        XCTAssertEqual(kits?.first?["id"] as? Int, 42)
        XCTAssertEqual(sanitized["dt"] as? String, "ac", "Unrelated settings are untouched")
    }

    func testWellFormedConfigurationIsStoredUnchanged() {
        let configuration: [AnyHashable: Any] = [
            "dt": "ac",
            "eks": [["id": 42], ["id": 312]]
        ]

        let sanitized = MPKitConfigurationParser.configurationDroppingUnusableKits(from: configuration)

        XCTAssertEqual((sanitized["eks"] as? [Any])?.count, 2)
        XCTAssertTrue(NSDictionary(dictionary: sanitized).isEqual(to: configuration))
    }

    func testConfigurationWithoutKitsIsStoredUnchanged() {
        XCTAssertTrue(NSDictionary(
            dictionary: MPKitConfigurationParser.configurationDroppingUnusableKits(from: ["dt": "ac"])
        ).isEqual(to: ["dt": "ac"]))

        // A non-array `eks` is left alone; the consumers already cast it and get nil.
        XCTAssertTrue(NSDictionary(
            dictionary: MPKitConfigurationParser.configurationDroppingUnusableKits(from: ["eks": "nope"])
        ).isEqual(to: ["eks": "nope"]))
    }

    // MARK: - merged configuration

    func testMergedConfigurationIsNilWithoutAnASBlock() {
        XCTAssertNil(MPKitConfigurationParser.mergedConfiguration(
            from: nil, addEventAttributeList: nil,
            removeEventAttributeList: nil, singleItemEventAttributeList: nil
        ))
    }

    func testMergedConfigurationOverlaysTheAttributeLists() {
        let merged = MPKitConfigurationParser.mergedConfiguration(
            from: ["key": "value"],
            addEventAttributeList: ["a": 1],
            removeEventAttributeList: ["r": 1],
            singleItemEventAttributeList: ["s": 1]
        )

        XCTAssertEqual(merged?["key"] as? String, "value")
        XCTAssertNotNil(merged?["eaa"])
        XCTAssertNotNil(merged?["ear"])
        XCTAssertNotNil(merged?["eas"])
    }

    func testANilListLeavesAnExistingKeyIntact() {
        // The ObjC overlays were each guarded, so a nil list must not delete a
        // key that `as` already carried.
        let merged = MPKitConfigurationParser.mergedConfiguration(
            from: ["eaa": "from_as"],
            addEventAttributeList: nil,
            removeEventAttributeList: nil,
            singleItemEventAttributeList: nil
        )

        XCTAssertEqual(merged?["eaa"] as? String, "from_as")
    }

    func testMergedConfigurationStripsNullValues() {
        let merged = MPKitConfigurationParser.mergedConfiguration(
            from: ["keep": 1, "drop": NSNull()],
            addEventAttributeList: nil,
            removeEventAttributeList: nil,
            singleItemEventAttributeList: nil
        )

        XCTAssertEqual(merged?.count, 1)
        XCTAssertNil(merged?["drop"])
    }
}
