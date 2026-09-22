import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPProjectionFieldParserTests: XCTestCase {
    // MARK: - action

    func testActionIsNilWhenAbsentOrNull() {
        XCTAssertNil(MPProjectionFieldParser.action(from: nil))
        XCTAssertNil(MPProjectionFieldParser.action(from: [:]))
        XCTAssertNil(MPProjectionFieldParser.action(from: ["action": NSNull()]))
    }

    func testActionIsReturnedWhenPresent() {
        let action = MPProjectionFieldParser.action(from: ["action": ["a": 1]])

        XCTAssertEqual(action?["a"] as? Int, 1)
    }

    // MARK: - propertyKind

    func testPropertyKindMapsEveryKnownName() {
        let expected: [String: MPProjectionPropertyKindSwift] = [
            "EventField": .eventField,
            "EventAttribute": .eventAttribute,
            "ProductField": .productField,
            "ProductAttribute": .productAttribute,
            "PromotionField": .promotionField,
            "PromotionAttribute": .promotionAttribute
        ]

        for (name, kind) in expected {
            XCTAssertEqual(MPProjectionFieldParser.propertyKind(for: name), kind, name)
        }
    }

    func testPropertyKindFallsBackToEventField() {
        for value in [nil, NSNull(), "", "Nonsense", 7] as [Any?] {
            XCTAssertEqual(MPProjectionFieldParser.propertyKind(for: value), .eventField)
        }
    }

    // MARK: - matchType

    func testMatchTypeMapsEveryKnownName() {
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: "String"), .string)
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: "Hash"), .hash)
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: "Field"), .field)
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: "Static"), .staticValue)
    }

    func testMatchTypeIsNotSpecifiedOnlyForNullOrAbsent() {
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: nil), .notSpecified)
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: NSNull()), .notSpecified)
    }

    func testUnrecognizedMatchTypeFallsBackToStringNotNotSpecified() {
        // The ObjC if/else chain had no final else, so a present-but-unknown
        // value left the ivar at its zero default, which is String.
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: "Nonsense"), .string)
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: ""), .string)
        XCTAssertEqual(MPProjectionFieldParser.matchType(for: 42), .string)
    }

    // MARK: - attribute fields

    func testAttributeFieldsReadsTheIndexedMap() {
        let action: [AnyHashable: Any] = ["attribute_maps": [
            ["value": "ignored"],
            [
                "value": "attr_name",
                "projected_attribute_name": "projected",
                "property": "ProductAttribute",
                "match_type": "Hash"
            ]
        ]]

        let fields = MPProjectionFieldParser.attributeFields(from: action, attributeIndex: 1)

        XCTAssertEqual(fields?.name, "attr_name")
        XCTAssertEqual(fields?.projectedName, "projected")
        XCTAssertEqual(fields?.propertyKind, .productAttribute)
        XCTAssertEqual(fields?.matchType, .hash)
    }

    func testAttributeFieldsDefaultsMatchTypeToStringWhenAbsentOrNull() {
        XCTAssertEqual(
            MPProjectionFieldParser.attributeFields(
                from: ["attribute_maps": [["value": "a"]]], attributeIndex: 0
            )?.matchType,
            .string
        )
        XCTAssertEqual(
            MPProjectionFieldParser.attributeFields(
                from: ["attribute_maps": [["value": "a", "match_type": NSNull()]]], attributeIndex: 0
            )?.matchType,
            .string
        )
    }

    func testAttributeFieldsIsNilWhenTheIndexIsOutOfRangeOrMapsAreMissing() {
        XCTAssertNil(MPProjectionFieldParser.attributeFields(from: [:], attributeIndex: 0))
        XCTAssertNil(MPProjectionFieldParser.attributeFields(
            from: ["attribute_maps": NSNull()], attributeIndex: 0
        ))
        XCTAssertNil(MPProjectionFieldParser.attributeFields(
            from: ["attribute_maps": [["value": "a"]]], attributeIndex: 1
        ))
    }

    func testAttributeFieldsYieldsDefaultsForANullMapAtAValidIndex() {
        let fields = MPProjectionFieldParser.attributeFields(
            from: ["attribute_maps": [NSNull()]], attributeIndex: 0
        )

        XCTAssertNotNil(fields)
        XCTAssertNil(fields?.name)
        XCTAssertNil(fields?.projectedName)
        XCTAssertEqual(fields?.propertyKind, .eventField)
        XCTAssertEqual(fields?.matchType, .notSpecified)
    }

    func testAttributeFieldsTreatsEmptyStringsAsNil() {
        let action: [AnyHashable: Any] = ["attribute_maps": [
            ["value": "", "projected_attribute_name": ""]
        ]]

        let fields = MPProjectionFieldParser.attributeFields(from: action, attributeIndex: 0)

        XCTAssertNil(fields?.name)
        XCTAssertNil(fields?.projectedName)
    }

    // MARK: - event fields

    func testEventFieldsReadsTheFirstMatchAndTheAction() {
        let configuration: [AnyHashable: Any] = ["matches": [
            ["event": "ev_name", "event_match_type": "Field", "property": "EventAttribute"],
            ["event": "ignored"]
        ]]

        let fields = MPProjectionFieldParser.eventFields(
            from: configuration, action: ["projected_event_name": "projected"]
        )

        XCTAssertEqual(fields.name, "ev_name")
        XCTAssertEqual(fields.projectedName, "projected")
        XCTAssertEqual(fields.propertyKind, .eventAttribute)
        XCTAssertEqual(fields.matchType, .field)
    }

    func testEventFieldsMatchTypeIsNotSpecifiedWhenAbsent() {
        let fields = MPProjectionFieldParser.eventFields(
            from: ["matches": [["event": "e"]]], action: [:]
        )

        XCTAssertEqual(fields.matchType, .notSpecified)
    }

    func testEventFieldsYieldsDefaultsWithoutMatches() {
        for configuration in [nil, [:], ["matches": NSNull()], ["matches": []]] as [[AnyHashable: Any]?] {
            let fields = MPProjectionFieldParser.eventFields(from: configuration, action: [:])

            XCTAssertNil(fields.name)
            XCTAssertNil(fields.projectedName)
            XCTAssertEqual(fields.propertyKind, .eventField)
            XCTAssertEqual(fields.matchType, .notSpecified)
        }
    }

    // MARK: - projection id

    func testProjectionIdReadsTheIdOrZero() {
        XCTAssertEqual(MPProjectionFieldParser.projectionId(from: ["id": 42]), 42)
        XCTAssertEqual(MPProjectionFieldParser.projectionId(from: [:]), 0)
        XCTAssertEqual(MPProjectionFieldParser.projectionId(from: nil), 0)
        XCTAssertEqual(MPProjectionFieldParser.projectionId(from: ["id": NSNull()]), 0)
    }

    func testProjectionIdParsesAStringId() {
        // Real kit configurations carry `id` as a JSON string, and -integerValue
        // accepted that. Swift's NSNumber bridge does not, so this is explicit.
        XCTAssertEqual(MPProjectionFieldParser.projectionId(from: ["id": "314"]), 314)
        XCTAssertEqual(MPProjectionFieldParser.projectionId(from: ["id": "not a number"]), 0)
    }

    // MARK: - attribute projection fields

    private func attributeConfiguration(_ attributeMaps: Any) -> [AnyHashable: Any] {
        ["action": ["attribute_maps": attributeMaps]]
    }

    func testAttributeProjectionFieldsReadsTheDataTypeAndRequiredFlag() {
        let fields = MPProjectionFieldParser.attributeProjectionFields(
            from: attributeConfiguration([["data_type": 3, "is_required": true]]),
            attributeIndex: 0
        )

        XCTAssertEqual(fields.dataType, 3)
        XCTAssertTrue(fields.isRequired)
    }

    func testAttributeProjectionFieldsDefaultsWhenTheKeysAreAbsent() {
        let fields = MPProjectionFieldParser.attributeProjectionFields(
            from: attributeConfiguration([["value": "attr"]]),
            attributeIndex: 0
        )

        // MPDataTypeString, and not required.
        XCTAssertEqual(fields.dataType, 1)
        XCTAssertFalse(fields.isRequired)
    }

    func testAttributeProjectionFieldsDefaultsOnExplicitNulls() {
        let fields = MPProjectionFieldParser.attributeProjectionFields(
            from: attributeConfiguration([["data_type": NSNull(), "is_required": NSNull()]]),
            attributeIndex: 0
        )

        XCTAssertEqual(fields.dataType, 1)
        XCTAssertFalse(fields.isRequired)
    }

    func testAttributeProjectionFieldsAcceptsStringEncodedValues() {
        // -integerValue and -boolValue were defined on NSString too, and remote
        // configuration uses either form.
        let fields = MPProjectionFieldParser.attributeProjectionFields(
            from: attributeConfiguration([["data_type": "3", "is_required": "true"]]),
            attributeIndex: 0
        )

        XCTAssertEqual(fields.dataType, 3)
        XCTAssertTrue(fields.isRequired)
    }

    func testAttributeProjectionFieldsDefaultsOnANullAttributeMap() {
        // The ObjC subscripted this element unguarded, so NSNull crashed with
        // -[NSNull objectForKeyedSubscript:].
        let fields = MPProjectionFieldParser.attributeProjectionFields(
            from: attributeConfiguration([NSNull()]),
            attributeIndex: 0
        )

        XCTAssertEqual(fields.dataType, 1)
        XCTAssertFalse(fields.isRequired)
    }

    func testAttributeProjectionFieldsDefaultsWhenAttributeMapsIsNotAnArray() {
        for maps: Any in [["not": "an array"] as [AnyHashable: Any], "string", 7, NSNull()] {
            let fields = MPProjectionFieldParser.attributeProjectionFields(
                from: attributeConfiguration(maps),
                attributeIndex: 0
            )

            XCTAssertEqual(fields.dataType, 1)
            XCTAssertFalse(fields.isRequired)
        }
    }

    func testAttributeProjectionFieldsDefaultsOutOfBoundsAndWithoutAConfiguration() {
        let outOfBounds = MPProjectionFieldParser.attributeProjectionFields(
            from: attributeConfiguration([["data_type": 3]]),
            attributeIndex: 9
        )
        let missing = MPProjectionFieldParser.attributeProjectionFields(from: nil, attributeIndex: 0)

        XCTAssertEqual(outOfBounds.dataType, 1)
        XCTAssertEqual(missing.dataType, 1)
    }
}
