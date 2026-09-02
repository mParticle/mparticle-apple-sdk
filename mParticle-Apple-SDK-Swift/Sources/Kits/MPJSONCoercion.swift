import Foundation

/// Mirrors the Objective-C accessors kit configurations relied on. `-boolValue`
/// and `-integerValue` are defined on both NSString and NSNumber, and remote
/// configuration uses either interchangeably; Swift's NSNumber bridge accepts
/// only the latter.
enum MPJSONCoercion {
    static func isNull(_ value: Any?) -> Bool {
        value == nil || value is NSNull
    }

    static func nonEmptyString(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else {
            return nil
        }
        return string
    }

    static func integerValue(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber: Int(truncating: number)
        case let string as NSString: string.integerValue
        default: nil
        }
    }

    static func boolValue(_ value: Any?) -> Bool? {
        switch value {
        case let number as NSNumber: number.boolValue
        case let string as NSString: string.boolValue
        default: nil
        }
    }
}
