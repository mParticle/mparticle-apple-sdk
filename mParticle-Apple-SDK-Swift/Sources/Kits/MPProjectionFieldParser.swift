import Foundation

/// Mirrors the Objective-C `MPProjectionMatchType`; raw values must stay in step.
@objc public enum MPProjectionMatchTypeSwift: Int {
    case notSpecified = -1
    case string = 0
    case hash = 1
    case field = 2
    case staticValue = 3
}

/// Mirrors the Objective-C `MPProjectionPropertyKind`; raw values must stay in step.
@objc public enum MPProjectionPropertyKindSwift: UInt {
    case eventField = 0
    case eventAttribute = 1
    case productField = 2
    case productAttribute = 3
    case promotionField = 4
    case promotionAttribute = 5
}

@objc(MPProjectionFields)
public final class MPProjectionFields: NSObject {
    @objc public let name: String?
    @objc public let projectedName: String?
    @objc public let propertyKind: MPProjectionPropertyKindSwift
    @objc public let matchType: MPProjectionMatchTypeSwift

    init(
        name: String?,
        projectedName: String?,
        propertyKind: MPProjectionPropertyKindSwift,
        matchType: MPProjectionMatchTypeSwift
    ) {
        self.name = name
        self.projectedName = projectedName
        self.propertyKind = propertyKind
        self.matchType = matchType
        super.init()
    }
}

@objc(MPProjectionFieldParser)
public final class MPProjectionFieldParser: NSObject {
    @objc(actionFromConfiguration:)
    public static func action(from configuration: [AnyHashable: Any]?) -> [AnyHashable: Any]? {
        configuration?["action"] as? [AnyHashable: Any]
    }

    @objc(attributeFieldsFromAction:attributeIndex:)
    public static func attributeFields(
        from action: [AnyHashable: Any],
        attributeIndex: UInt
    ) -> MPProjectionFields? {
        guard let attributeMaps = action["attribute_maps"] as? [Any],
              attributeIndex < attributeMaps.count
        else {
            return nil
        }

        guard let attributeMap = attributeMaps[Int(attributeIndex)] as? [AnyHashable: Any] else {
            return MPProjectionFields(
                name: nil,
                projectedName: nil,
                propertyKind: .eventField,
                matchType: .notSpecified
            )
        }

        let rawMatchType = attributeMap["match_type"]
        return MPProjectionFields(
            name: nonEmptyString(attributeMap["value"]),
            projectedName: nonEmptyString(attributeMap["projected_attribute_name"]),
            propertyKind: propertyKind(for: attributeMap["property"]),
            matchType: matchType(for: isNull(rawMatchType) ? "String" : rawMatchType)
        )
    }

    @objc(eventFieldsFromConfiguration:action:)
    public static func eventFields(
        from configuration: [AnyHashable: Any]?,
        action: [AnyHashable: Any]
    ) -> MPProjectionFields {
        guard let matches = configuration?["matches"] as? [Any],
              let matchDictionary = matches.first as? [AnyHashable: Any]
        else {
            return MPProjectionFields(
                name: nil,
                projectedName: nil,
                propertyKind: .eventField,
                matchType: .notSpecified
            )
        }

        return MPProjectionFields(
            name: nonEmptyString(matchDictionary["event"]),
            projectedName: nonEmptyString(action["projected_event_name"]),
            propertyKind: propertyKind(for: matchDictionary["property"]),
            matchType: matchType(for: matchDictionary["event_match_type"])
        )
    }

    /// `id` arrives as a JSON string in real kit configurations, so this mirrors
    /// `-integerValue`, which Objective-C could send to either an NSString or an
    /// NSNumber.
    @objc(projectionIdFromConfiguration:)
    public static func projectionId(from configuration: [AnyHashable: Any]?) -> UInt {
        switch configuration?["id"] {
        case let number as NSNumber:
            return UInt(bitPattern: Int(truncating: number))
        case let string as NSString:
            return UInt(bitPattern: string.integerValue)
        default:
            return 0
        }
    }

    @objc(propertyKindForProperty:)
    public static func propertyKind(for property: Any?) -> MPProjectionPropertyKindSwift {
        switch nonEmptyString(property) {
        case "EventField": .eventField
        case "EventAttribute": .eventAttribute
        case "ProductField": .productField
        case "ProductAttribute": .productAttribute
        case "PromotionField": .promotionField
        case "PromotionAttribute": .promotionAttribute
        default: .eventField
        }
    }

    @objc(matchTypeForValue:)
    public static func matchType(for value: Any?) -> MPProjectionMatchTypeSwift {
        if isNull(value) {
            return .notSpecified
        }

        switch value as? String {
        case "String": return .string
        case "Hash": return .hash
        case "Field": return .field
        case "Static": return .staticValue
        // A present-but-unrecognized value left the Objective-C ivar at its
        // zero default, which is String rather than NotSpecified.
        default: return .string
        }
    }

    private static func isNull(_ value: Any?) -> Bool {
        value == nil || value is NSNull
    }

    private static func nonEmptyString(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else {
            return nil
        }
        return string
    }
}
