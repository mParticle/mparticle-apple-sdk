import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPEventProjectionParserTests: XCTestCase {
    private let unlimited = UInt(Int32.max)

    // MARK: - matches

    func testMatchesReadsAttributeKeysForNonCommerceEvents() {
        let configuration: [AnyHashable: Any] = ["matches": [
            ["attribute_key": "k", "attribute_values": ["a", "b"]]
        ]]

        let matches = MPEventProjectionParser.matches(from: configuration, isCommerceEvent: false)

        XCTAssertEqual(matches?.count, 1)
        XCTAssertEqual(matches?.first?.attributeKey, "k")
        XCTAssertEqual(matches?.first?.attributeValues as? [String], ["a", "b"])
    }

    func testMatchesReadsPropertyKeysForCommerceEvents() {
        let configuration: [AnyHashable: Any] = ["matches": [
            ["property_name": "p", "property_value": ["v"], "attribute_key": "ignored"]
        ]]

        let matches = MPEventProjectionParser.matches(from: configuration, isCommerceEvent: true)

        XCTAssertEqual(matches?.first?.attributeKey, "p")
        XCTAssertEqual(matches?.first?.attributeValues as? [String], ["v"])
    }

    func testMatchesRequiresBothAKeyAndNonEmptyValues() {
        let configuration: [AnyHashable: Any] = ["matches": [
            ["attribute_key": "no_values"],
            ["attribute_values": ["no_key"]],
            ["attribute_key": "", "attribute_values": ["empty_key"]],
            ["attribute_key": "empty_values", "attribute_values": []],
            ["attribute_key": "good", "attribute_values": ["v"]]
        ]]

        let matches = MPEventProjectionParser.matches(from: configuration, isCommerceEvent: false)

        XCTAssertEqual(matches?.count, 1)
        XCTAssertEqual(matches?.first?.attributeKey, "good")
    }

    func testMatchesIsNilWhenNothingQualifies() {
        XCTAssertNil(MPEventProjectionParser.matches(from: nil, isCommerceEvent: false))
        XCTAssertNil(MPEventProjectionParser.matches(from: [:], isCommerceEvent: false))
        XCTAssertNil(MPEventProjectionParser.matches(from: ["matches": []], isCommerceEvent: false))
        XCTAssertNil(MPEventProjectionParser.matches(from: ["matches": NSNull()], isCommerceEvent: false))
        XCTAssertNil(MPEventProjectionParser.matches(
            from: ["matches": [["attribute_key": "k"]]], isCommerceEvent: false
        ))
    }

    func testMatchesKeepsNonStringValuesUntouched() {
        let configuration: [AnyHashable: Any] = ["matches": [
            ["attribute_key": "k", "attribute_values": [1, 2]]
        ]]

        let matches = MPEventProjectionParser.matches(from: configuration, isCommerceEvent: false)

        XCTAssertEqual(matches?.first?.attributeValues.count, 2)
    }

    // MARK: - behavior

    func testBehaviorDefaultsWithoutABehaviorBlock() {
        for configuration in [nil, [:], ["behavior": NSNull()]] as [[AnyHashable: Any]?] {
            let behavior = MPEventProjectionParser.behavior(from: configuration)

            XCTAssertTrue(behavior.appendAsIs)
            XCTAssertFalse(behavior.isDefault)
            XCTAssertEqual(behavior.maxCustomParameters, unlimited)
            XCTAssertFalse(behavior.selectsLast)
        }
    }

    func testBehaviorDefaultsForAnEmptyBehaviorBlock() {
        let behavior = MPEventProjectionParser.behavior(from: ["behavior": [:]])

        XCTAssertTrue(behavior.appendAsIs)
        XCTAssertFalse(behavior.isDefault)
        XCTAssertEqual(behavior.maxCustomParameters, unlimited)
        XCTAssertFalse(behavior.selectsLast)
    }

    func testBehaviorReadsEveryField() {
        let behavior = MPEventProjectionParser.behavior(from: ["behavior": [
            "append_unmapped_as_is": false,
            "is_default": true,
            "max_custom_params": 4,
            "selector": "last"
        ]])

        XCTAssertFalse(behavior.appendAsIs)
        XCTAssertTrue(behavior.isDefault)
        XCTAssertEqual(behavior.maxCustomParameters, 4)
        XCTAssertTrue(behavior.selectsLast)
    }

    func testBehaviorAcceptsStringEncodedNumbersAndBooleans() {
        // Remote configuration sends these as JSON strings; -boolValue and
        // -integerValue accepted an NSString.
        let behavior = MPEventProjectionParser.behavior(from: ["behavior": [
            "append_unmapped_as_is": "false",
            "is_default": "true",
            "max_custom_params": "9"
        ]])

        XCTAssertFalse(behavior.appendAsIs)
        XCTAssertTrue(behavior.isDefault)
        XCTAssertEqual(behavior.maxCustomParameters, 9)
    }

    func testAnySelectorOtherThanLastIsForEach() {
        for selector in ["", "first", "Last", "LAST"] {
            XCTAssertFalse(
                MPEventProjectionParser.behavior(from: ["behavior": ["selector": selector]]).selectsLast,
                selector
            )
        }
    }

    // MARK: - message types

    func testMessageTypeComesFromTheFirstMatch() {
        XCTAssertEqual(
            MPEventProjectionParser.messageType(
                fromMatchesIn: ["matches": [["message_type": 16], ["message_type": 4]]],
                defaultValue: 4
            ),
            16
        )
    }

    func testMessageTypeFallsBackToTheDefault() {
        XCTAssertEqual(MPEventProjectionParser.messageType(fromMatchesIn: nil, defaultValue: 4), 4)
        XCTAssertEqual(MPEventProjectionParser.messageType(fromMatchesIn: [:], defaultValue: 4), 4)
        XCTAssertEqual(
            MPEventProjectionParser.messageType(
                fromMatchesIn: ["matches": [["message_type": NSNull()]]], defaultValue: 4
            ),
            4
        )
    }

    func testOutboundMessageTypeReadsTheActionOrFallsBack() {
        XCTAssertEqual(
            MPEventProjectionParser.outboundMessageType(
                from: ["outbound_message_type": 16], defaultValue: 4
            ),
            16
        )
        XCTAssertEqual(MPEventProjectionParser.outboundMessageType(from: nil, defaultValue: 4), 4)
        XCTAssertEqual(MPEventProjectionParser.outboundMessageType(from: [:], defaultValue: 4), 4)
    }
}
