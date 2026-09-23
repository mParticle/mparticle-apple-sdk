import Foundation

/// Coerces a projection's string value to the typed value a kit expects.
/// Behavior-preserving port of `-[MPKitContainer transformValue:dataType:]`. Reuses
/// `CustomModuleDataType`; the ObjC boundary passes the raw `MPDataType` integer, and an
/// unrecognised value yields nil.
@objc public final class MPKitValueTransformer: NSObject {
    private let logger: MPLog

    @objc public init(logger: MPLog) {
        self.logger = logger
    }

    @objc public func transformValue(_ originalValue: Any?, dataType rawDataType: Int) -> Any? {
        let isNull = originalValue == nil || originalValue is NSNull

        switch CustomModuleDataType(rawValue: rawDataType) {
        case .string:
            return isNull ? nil : originalValue

        case .int, .long:
            if isNull { return NSNumber(value: 0) }
            // An NSNumber uses its own integer value (ObjC sent `integerValue` to the object);
            // stringifying first would mis-parse scientific notation and fractional values.
            if let number = originalValue as? NSNumber { return NSNumber(value: number.int64Value) }
            let string = originalValue as? String ?? ""
            let integerValue = (string as NSString).integerValue
            if integerValue != 0 || string == "0" {
                return NSNumber(value: integerValue)
            }
            logger.error("Value '\(string)' was expected to be a number string.")
            return nil

        case .float:
            if isNull { return NSNumber(value: 0.0) }
            if let number = originalValue as? NSNumber { return NSNumber(value: number.floatValue) }
            let string = originalValue as? String ?? ""
            let floatValue = (string as NSString).floatValue
            if (floatValue != .infinity && floatValue != -.infinity && floatValue != 0.0)
                || string == "0" || string == "0.0" || string == ".0" {
                return NSNumber(value: floatValue)
            }
            logger.error("Attribute '\(string)' was expected to be a number string.")
            return NSNull()

        case .bool:
            if isNull { return NSNumber(value: false) }
            // An NSNumber attribute (e.g. @YES/@NO or 1/0) uses its boolValue; a String is true
            // only when it reads "true" (case-insensitive), matching the ObjC original for strings.
            if let number = originalValue as? NSNumber { return NSNumber(value: number.boolValue) }
            let string = originalValue as? String ?? ""
            let isTrue = (string as NSString).caseInsensitiveCompare("true") == .orderedSame
            return NSNumber(value: isTrue)

        case .none:
            return nil
        }
    }
}
