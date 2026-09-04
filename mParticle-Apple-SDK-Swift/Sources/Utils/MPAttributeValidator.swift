import Foundation

/// Which attribute-validation rule a key-value pair failed, or `.valid`.
/// The numeric error code, NSError construction, and console logging stay in
/// the Objective-C caller so the log level continues to gate message building.
@objc public enum MPAttributeValidationResult: Int {
    case valid
    case invalidKey
    case keyTooLong
    case nilValue
    case invalidType
    case valueTooLong
    case invalidArrayEntry
    case arrayValueTooLong
}

@objc public final class MPAttributeValidator: NSObject {
    @objc(validateKey:value:keyLengthLimit:valueLengthLimit:invalidArrayEntry:)
    public static func validate(
        key: Any?,
        value: Any?,
        keyLengthLimit: Int,
        valueLengthLimit: Int,
        invalidArrayEntry: AutoreleasingUnsafeMutablePointer<AnyObject?>?
    ) -> MPAttributeValidationResult {
        invalidArrayEntry?.pointee = nil

        if key == nil || key is NSNull {
            return .invalidKey
        }

        if let key = key as? NSString, key.length > keyLengthLimit {
            return .keyTooLong
        }

        guard let value = value else {
            // Matches the original !value branch: a nil pointer may just be a
            // removal, so the caller does not log an error for it.
            return .nilValue
        }

        let isStringValue = value is NSString
        let isArrayValue = value is NSArray
        let isNumberValue = value is NSNumber
        let isNSNullValue = value is NSNull

        if !isStringValue && !isArrayValue && !isNumberValue && !isNSNullValue {
            return .invalidType
        }

        if isStringValue, let string = value as? NSString, string.length > valueLengthLimit {
            return .valueTooLong
        }

        if isArrayValue, let values = value as? NSArray {
            var totalValueLength = 0
            for entry in values {
                guard let entryString = entry as? NSString else {
                    invalidArrayEntry?.pointee = entry as AnyObject
                    return .invalidArrayEntry
                }
                totalValueLength += entryString.length
            }
            if totalValueLength > valueLengthLimit {
                return .arrayValueTooLong
            }
        }

        return .valid
    }

    /// Whether a scalar attribute value may be passed on for full validation: a non-empty string,
    /// any number, or nil — a nil value reaches the change path as a removal rather than being
    /// rejected here.
    @objc(isAcceptableScalarValue:)
    public static func isAcceptableScalarValue(_ value: Any?) -> Bool {
        guard let value else { return true }
        if let string = value as? NSString { return string.length > 0 }
        return value is NSNumber
    }

    /// Whether a list attribute value may be passed on: a non-empty array. Entry types are checked
    /// later by `validate(key:value:...)`, which reports the offending entry.
    @objc(isAcceptableValueList:)
    public static func isAcceptableValueList(_ values: Any?) -> Bool {
        guard let values = values as? NSArray else { return false }
        return !values.isEmpty
    }
}
