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
