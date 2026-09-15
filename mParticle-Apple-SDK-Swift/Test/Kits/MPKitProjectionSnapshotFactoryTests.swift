import XCTest
@testable import mParticle_Apple_SDK_Swift

/// Mirrors UnitTests/ObjCTests/MPBase_Attribute_Event_ProjectionTests.m, which
/// covers the Objective-C projection classes this factory replaces.
final class MPKitProjectionSnapshotFactoryTests: XCTestCase {
    private let unlimited = UInt(Int32.max)
    private let messageTypeCount: UInt = 20

    // MPMessageType raw values (Include/MPEnums.h).
    private let messageTypeScreenView: UInt = 3
    private let messageTypeEvent: UInt = 4
    private let messageTypeCommerceEvent: UInt = 16
    private let messageTypeMedia: UInt = 20

    // MPDataType raw values (MPIConstants.h).
    private let dataTypeString = 1
    private let dataTypeLong = 5

    private var factory: MPKitProjectionSnapshotFactory!

    override func setUp() {
        super.setUp()
        let logger = MPLog(logLevel: .none)
        factory = MPKitProjectionSnapshotFactory(hasher: MPIHasher(logger: logger), logger: logger)
    }

    override func tearDown() {
        factory = nil
        super.tearDown()
    }

    // MARK: - Event projection fields

    func testProjectionReadsNameProjectedNameAndIdentifier() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event"],
            "id": "314",
            "matches": [["event": "Non-projected event", "event_match_type": "String"]]
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.name, "Non-projected event")
        XCTAssertEqual(projection?.projectedName, "Projected Event")
        XCTAssertEqual(projection?.projectionId, 314)
        XCTAssertEqual(projection?.propertyKind, MPProjectionPropertyKindSwift.eventField.rawValue)
        XCTAssertEqual(projection?.matchType, MPProjectionMatchTypeSwift.string.rawValue)
    }

    /// An unrecognized match type or property left the Objective-C ivar at its
    /// zero default rather than falling back to "not specified".
    func testProjectionFallsBackToStringAndEventFieldForUnrecognizedValues() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event"],
            "id": "314",
            "matches": [[
                "event": "Non-projected event",
                "event_match_type": "This is not even remotely valid",
                "property": "Same here, this is not valid"
            ]]
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.matchType, MPProjectionMatchTypeSwift.string.rawValue)
        XCTAssertEqual(projection?.propertyKind, MPProjectionPropertyKindSwift.eventField.rawValue)
    }

    func testProjectionIsNilWithoutAnAction() {
        XCTAssertNil(factory.projectionSnapshot(from: nil))
        XCTAssertNil(factory.projectionSnapshot(from: ["id": "314"]))
    }

    func testEventProjectionReadsBehaviorMatchesAndTypes() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event", "outbound_message_type": "4"],
            "id": "314",
            "matches": [[
                "event": "52",
                "event_match_type": "String",
                "attribute_key": "aKey",
                "attribute_values": ["aValue"]
            ]],
            "behavior": ["append_unmapped_as_is": true, "is_default": false, "max_custom_params": 42]
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.eventType, MPEventTypeSwift.transaction.rawValue)
        XCTAssertEqual(projection?.messageType, messageTypeEvent)
        XCTAssertEqual(projection?.outboundMessageType, messageTypeEvent)
        XCTAssertEqual(projection?.maxCustomParameters, 42)
        XCTAssertEqual(projection?.projectionMatches?.first?.attributeKey, "aKey")
        XCTAssertEqual(projection?.projectionMatches?.first?.attributeValues, ["aValue"])
        XCTAssertEqual(projection?.appendAsIs, true)
        XCTAssertEqual(projection?.behaviorSelector, 0)
    }

    func testCommerceEventProjectionReadsPropertyKeyedMatches() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event", "outbound_message_type": "16"],
            "id": "314",
            "matches": [[
                "event": "1567",
                "event_match_type": "String",
                "property_name": "pName",
                "property_value": ["pValue"],
                "message_type": "16"
            ]],
            "behavior": ["append_unmapped_as_is": true, "is_default": false, "max_custom_params": 42]
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.eventType, MPEventTypeSwift.addToCart.rawValue)
        XCTAssertEqual(projection?.messageType, messageTypeCommerceEvent)
        XCTAssertEqual(projection?.outboundMessageType, messageTypeCommerceEvent)
        XCTAssertEqual(projection?.projectionMatches?.first?.attributeKey, "pName")
        XCTAssertEqual(projection?.projectionMatches?.first?.attributeValues, ["pValue"])
    }

    func testProjectionDefaultsWhenMatchesAndBehaviorAreNull() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event", "outbound_message_type": "16"],
            "id": "314",
            "matches": NSNull(),
            "behavior": NSNull()
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.eventType, MPEventTypeSwift.other.rawValue)
        XCTAssertEqual(projection?.messageType, messageTypeEvent)
        XCTAssertEqual(projection?.maxCustomParameters, unlimited)
        XCTAssertNil(projection?.projectionMatches)
        XCTAssertEqual(projection?.appendAsIs, true)
    }

    func testProjectionDefaultsWhenIndividualBehaviorValuesAreNull() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event", "outbound_message_type": NSNull()],
            "id": "314",
            "matches": [[
                "event": "1567",
                "event_match_type": "String",
                "property_name": NSNull(),
                "property_value": NSNull(),
                "message_type": "16"
            ]],
            "behavior": [
                "append_unmapped_as_is": NSNull(),
                "is_default": NSNull(),
                "max_custom_params": NSNull()
            ]
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.eventType, MPEventTypeSwift.addToCart.rawValue)
        XCTAssertEqual(projection?.messageType, messageTypeCommerceEvent)
        XCTAssertEqual(projection?.outboundMessageType, messageTypeEvent)
        XCTAssertEqual(projection?.maxCustomParameters, unlimited)
        XCTAssertNil(projection?.projectionMatches)
        XCTAssertEqual(projection?.appendAsIs, true)
    }

    func testProjectionSelectsLastBehaviorSelector() {
        let configuration: [AnyHashable: Any] = [
            "action": ["projected_event_name": "Projected Event"],
            "behavior": ["selector": "last"]
        ]

        XCTAssertEqual(factory.projectionSnapshot(from: configuration)?.behaviorSelector, 1)
    }

    // MARK: - Attribute projections

    func testAttributeProjectionReadsFields() {
        let projection = factory.attributeProjectionSnapshot(
            from: attributeConfiguration(dataType: dataTypeString, isRequired: true),
            attributeIndex: 0
        )

        XCTAssertEqual(projection?.name, "original attribute")
        XCTAssertEqual(projection?.projectedName, "projected attribute")
        XCTAssertEqual(projection?.propertyKind, MPProjectionPropertyKindSwift.eventAttribute.rawValue)
        XCTAssertEqual(projection?.matchType, MPProjectionMatchTypeSwift.string.rawValue)
        XCTAssertEqual(projection?.dataType, dataTypeString)
        XCTAssertEqual(projection?.required, true)
    }

    func testAttributeProjectionClampsOutOfRangeDataTypeToString() {
        let belowRange = factory.attributeProjectionSnapshot(
            from: attributeConfiguration(dataType: 0, isRequired: false),
            attributeIndex: 0
        )
        let aboveRange = factory.attributeProjectionSnapshot(
            from: attributeConfiguration(dataType: 200, isRequired: false),
            attributeIndex: 0
        )
        let inRange = factory.attributeProjectionSnapshot(
            from: attributeConfiguration(dataType: dataTypeLong, isRequired: false),
            attributeIndex: 0
        )

        XCTAssertEqual(belowRange?.dataType, dataTypeString)
        XCTAssertEqual(aboveRange?.dataType, dataTypeString)
        XCTAssertEqual(inRange?.dataType, dataTypeLong)
    }

    func testAttributeProjectionDefaultsWhenDataTypeAndRequiredAreNull() {
        let configuration: [AnyHashable: Any] = ["action": ["attribute_maps": [[
            "value": "original attribute",
            "projected_attribute_name": "projected attribute",
            "property": "EventAttribute",
            "data_type": NSNull(),
            "is_required": NSNull()
        ]]]]

        let projection = factory.attributeProjectionSnapshot(from: configuration, attributeIndex: 0)

        XCTAssertEqual(projection?.dataType, dataTypeString)
        XCTAssertEqual(projection?.required, false)
    }

    /// The Objective-C subscripted `attribute_maps[attributeIndex]` with no guard
    /// on the element, so a null entry crashed.
    func testAttributeProjectionDefaultsForANullAttributeMap() {
        let configuration: [AnyHashable: Any] = ["action": ["attribute_maps": [NSNull()]]]

        let projection = factory.attributeProjectionSnapshot(from: configuration, attributeIndex: 0)

        XCTAssertNotNil(projection)
        XCTAssertEqual(projection?.dataType, dataTypeString)
        XCTAssertEqual(projection?.required, false)
    }

    func testAttributeProjectionIsNilForAMissingIndexOrNonArrayMaps() {
        XCTAssertNil(factory.attributeProjectionSnapshot(from: nil, attributeIndex: 0))
        XCTAssertNil(factory.attributeProjectionSnapshot(
            from: attributeConfiguration(dataType: dataTypeString, isRequired: true),
            attributeIndex: 1
        ))
        XCTAssertNil(factory.attributeProjectionSnapshot(
            from: ["action": ["attribute_maps": "not an array"]],
            attributeIndex: 0
        ))
    }

    func testEventProjectionCarriesItsAttributeProjections() {
        let configuration: [AnyHashable: Any] = [
            "action": [
                "projected_event_name": "Projected Event",
                "attribute_maps": [
                    ["value": "first", "property": "EventAttribute"],
                    ["value": "second", "property": "ProductField"]
                ]
            ]
        ]

        let projection = factory.projectionSnapshot(from: configuration)

        XCTAssertEqual(projection?.attributeProjections.count, 2)
        XCTAssertEqual(projection?.attributeProjections.first?.name, "first")
        XCTAssertEqual(projection?.attributeProjections.last?.name, "second")
    }

    func testEventProjectionHasNoAttributeProjectionsWithoutAttributeMaps() {
        let configuration: [AnyHashable: Any] = ["action": ["projected_event_name": "Projected Event"]]

        XCTAssertEqual(factory.projectionSnapshot(from: configuration)?.attributeProjections, [])
    }

    // MARK: - Projection set

    func testProjectionSetIsEmptyForNoConfiguredProjections() {
        for configurations in [nil, []] as [[Any]?] {
            let set = factory.projectionSet(from: configurations, messageTypeCount: messageTypeCount)

            XCTAssertNil(set.configuredMessageTypeProjections)
            XCTAssertNil(set.defaultProjections)
            XCTAssertNil(set.projections)
        }
    }

    func testProjectionSetMarksConfiguredMessageTypes() {
        let set = factory.projectionSet(
            from: [projectionConfiguration(messageType: messageTypeCommerceEvent, isDefault: false)],
            messageTypeCount: messageTypeCount
        )

        XCTAssertEqual(set.configuredMessageTypeProjections?.count, Int(messageTypeCount))
        XCTAssertEqual(set.configuredMessageTypeProjections?[Int(messageTypeCommerceEvent)], true)
        XCTAssertEqual(set.configuredMessageTypeProjections?[Int(messageTypeScreenView)], false)
        XCTAssertEqual(set.projections?.count, 1)
    }

    func testProjectionSetBucketsDefaultProjectionsByMessageType() {
        let set = factory.projectionSet(
            from: [projectionConfiguration(messageType: messageTypeCommerceEvent, isDefault: true)],
            messageTypeCount: messageTypeCount
        )

        XCTAssertNil(set.projections)
        XCTAssertTrue(set.defaultProjections?[Int(messageTypeCommerceEvent)] is MPKitProjectionSnapshot)
        XCTAssertTrue(set.defaultProjections?[Int(messageTypeEvent)] is NSNull)
    }

    /// `-setObject:atIndexedSubscript:` appends at `index == count`, which is how
    /// MPMessageTypeMedia (20) has always registered against a count of 20.
    func testProjectionSetAppendsForTheMessageTypeEqualToTheCount() {
        let set = factory.projectionSet(
            from: [projectionConfiguration(messageType: messageTypeMedia, isDefault: true)],
            messageTypeCount: messageTypeCount
        )

        XCTAssertEqual(set.configuredMessageTypeProjections?.count, Int(messageTypeCount) + 1)
        XCTAssertEqual(set.configuredMessageTypeProjections?[Int(messageTypeMedia)], true)
        XCTAssertTrue(set.defaultProjections?[Int(messageTypeMedia)] is MPKitProjectionSnapshot)
    }

    func testProjectionSetSkipsOutOfRangeMessageTypes() {
        let set = factory.projectionSet(
            from: [projectionConfiguration(messageType: messageTypeCount + 1, isDefault: false)],
            messageTypeCount: messageTypeCount
        )

        XCTAssertEqual(set.configuredMessageTypeProjections?.count, Int(messageTypeCount))
        XCTAssertNil(set.projections)
    }

    func testProjectionSetSkipsEntriesThatAreNotProjections() {
        let set = factory.projectionSet(
            from: ["not a dictionary", ["id": "1"], projectionConfiguration(messageType: messageTypeEvent, isDefault: false)],
            messageTypeCount: messageTypeCount
        )

        XCTAssertEqual(set.projections?.count, 1)
    }

    // MARK: - Helpers

    private func attributeConfiguration(dataType: Int, isRequired: Bool) -> [AnyHashable: Any] {
        ["action": ["attribute_maps": [[
            "value": "original attribute",
            "projected_attribute_name": "projected attribute",
            "property": "EventAttribute",
            "data_type": dataType,
            "is_required": isRequired
        ]]]]
    }

    private func projectionConfiguration(messageType: UInt, isDefault: Bool) -> [AnyHashable: Any] {
        [
            "action": ["projected_event_name": "Projected Event"],
            "id": "314",
            "matches": [["event": "an event", "message_type": messageType]],
            "behavior": ["is_default": isDefault]
        ]
    }
}
