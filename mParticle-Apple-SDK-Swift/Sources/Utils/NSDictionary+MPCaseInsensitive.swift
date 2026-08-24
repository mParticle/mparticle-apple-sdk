import Foundation

public extension NSDictionary {
    @objc func mpCaseInsensitiveKey(_ key: String) -> String? {
        let lowerCaseKey = key.lowercased()
        for case let candidate as String in allKeys where candidate.lowercased() == lowerCaseKey {
            return candidate
        }
        return nil
    }

    @objc func mpValueForCaseInsensitiveKey(_ key: String) -> Any? {
        guard let matchedKey = mpCaseInsensitiveKey(key) else {
            return nil
        }
        return self[matchedKey]
    }
}

@objc(MPAttributeValueTransformer) public final class AttributeValueTransformer: NSObject {
    /// The supported types here must stay in step with `transformedValue(for:)`. This is a
    /// separate check because a supported value can still convert to nil, and the caller has
    /// to tell that apart from an unsupported type.
    @objc(isSupportedAttributeValue:) public static func isSupportedValue(_ value: Any) -> Bool {
        switch value {
        case is String, is NSNumber, is Date, is NSDictionary, is NSArray, is NSNull:
            return true
        case let data as Data:
            return !data.isEmpty
        default:
            return false
        }
    }

    @objc(transformedValueForAttribute:) public static func transformedValue(for value: Any) -> Any? {
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return number.boolValue ? "true" : "false"
            }
            return number.stringValue
        }
        if let date = value as? Date {
            guard let formatted = MPDateFormatter.string(fromDateRFC3339: date) else {
                return nil
            }
            return formatted
        }
        if let data = value as? Data, !data.isEmpty {
            guard let decoded = String(data: data, encoding: .utf8) else {
                return nil
            }
            return decoded
        }
        if let dictionary = value as? NSDictionary {
            return dictionary.description
        }
        if let array = value as? NSArray {
            return array.description
        }
        if value is NSNull {
            return NSNull()
        }
        return nil
    }
}
