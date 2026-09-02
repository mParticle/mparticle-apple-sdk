import Foundation

@objc(MPProjectionMatchFields)
public final class MPProjectionMatchFields: NSObject {
    @objc public let attributeKey: String
    @objc public let attributeValues: [Any]

    init(attributeKey: String, attributeValues: [Any]) {
        self.attributeKey = attributeKey
        self.attributeValues = attributeValues
        super.init()
    }
}

@objc(MPEventProjectionBehavior)
public final class MPEventProjectionBehavior: NSObject {
    @objc public let appendAsIs: Bool
    @objc public let isDefault: Bool
    @objc public let maxCustomParameters: UInt
    @objc public let selectsLast: Bool

    init(appendAsIs: Bool, isDefault: Bool, maxCustomParameters: UInt, selectsLast: Bool) {
        self.appendAsIs = appendAsIs
        self.isDefault = isDefault
        self.maxCustomParameters = maxCustomParameters
        self.selectsLast = selectsLast
        super.init()
    }
}

@objc(MPEventProjectionParser)
public final class MPEventProjectionParser: NSObject {
    /// `max_custom_params` defaults to INT_MAX, not NSUIntegerMax.
    private static let unlimitedCustomParameters = UInt(Int32.max)

    @objc(matchesFromConfiguration:isCommerceEvent:)
    public static func matches(
        from configuration: [AnyHashable: Any]?,
        isCommerceEvent: Bool
    ) -> [MPProjectionMatchFields]? {
        guard let matches = configuration?["matches"] as? [Any], !matches.isEmpty else {
            return nil
        }

        let keyName = isCommerceEvent ? "property_name" : "attribute_key"
        let valuesName = isCommerceEvent ? "property_value" : "attribute_values"

        let fields = matches.compactMap { match -> MPProjectionMatchFields? in
            guard let match = match as? [AnyHashable: Any],
                  let key = MPJSONCoercion.nonEmptyString(match[keyName]),
                  let values = match[valuesName] as? [Any],
                  !values.isEmpty
            else {
                return nil
            }
            return MPProjectionMatchFields(attributeKey: key, attributeValues: values)
        }

        return fields.isEmpty ? nil : fields
    }

    @objc(behaviorFromConfiguration:)
    public static func behavior(from configuration: [AnyHashable: Any]?) -> MPEventProjectionBehavior {
        guard let behavior = configuration?["behavior"] as? [AnyHashable: Any] else {
            return MPEventProjectionBehavior(
                appendAsIs: true,
                isDefault: false,
                maxCustomParameters: unlimitedCustomParameters,
                selectsLast: false
            )
        }

        return MPEventProjectionBehavior(
            appendAsIs: MPJSONCoercion.boolValue(behavior["append_unmapped_as_is"]) ?? true,
            isDefault: MPJSONCoercion.boolValue(behavior["is_default"]) ?? false,
            maxCustomParameters: MPJSONCoercion.integerValue(behavior["max_custom_params"])
                .map { UInt(bitPattern: $0) } ?? unlimitedCustomParameters,
            selectsLast: MPJSONCoercion.nonEmptyString(behavior["selector"]) == "last"
        )
    }

    @objc(messageTypeFromMatchesInConfiguration:defaultValue:)
    public static func messageType(
        fromMatchesIn configuration: [AnyHashable: Any]?,
        defaultValue: UInt
    ) -> UInt {
        guard let matches = configuration?["matches"] as? [Any],
              let first = matches.first as? [AnyHashable: Any],
              let messageType = MPJSONCoercion.integerValue(first["message_type"])
        else {
            return defaultValue
        }
        return UInt(bitPattern: messageType)
    }

    @objc(outboundMessageTypeFromAction:defaultValue:)
    public static func outboundMessageType(
        from action: [AnyHashable: Any]?,
        defaultValue: UInt
    ) -> UInt {
        guard let outbound = MPJSONCoercion.integerValue(action?["outbound_message_type"]) else {
            return defaultValue
        }
        return UInt(bitPattern: outbound)
    }
}
