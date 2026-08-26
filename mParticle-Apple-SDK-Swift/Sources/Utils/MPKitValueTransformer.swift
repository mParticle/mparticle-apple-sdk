import Foundation

/// Mirrors the internal Objective-C `MPDataType` (MPIConstants.h). Duplicated here because the
/// Foundation-only Swift module cannot import the ObjC module; callers cast `(MPDataTypeSwift)`.
@objc public enum MPDataTypeSwift: Int {
    case string = 1
    case int = 2
    case bool = 3
    case float = 4
    case long = 5
}

/// Coerces a projection's string value to the typed value a kit expects.
/// Behavior-preserving port of `-[MPKitContainer transformValue:dataType:]`.
@objc public final class MPKitValueTransformer: NSObject {
    private let logger: MPLog

    @objc public init(logger: MPLog) {
        self.logger = logger
    }

    @objc public func transformValue(_ originalValue: Any?, dataType: MPDataTypeSwift) -> Any? {
        let isNull = originalValue == nil || originalValue is NSNull

        switch dataType {
        case .string:
            return isNull ? nil : originalValue

        case .int, .long:
            if isNull { return NSNumber(value: 0) }
            let string = originalValue as? String ?? ""
            let integerValue = (string as NSString).integerValue
            if integerValue != 0 || string == "0" {
                return NSNumber(value: integerValue)
            }
            logger.error("Value '\(string)' was expected to be a number string.")
            return nil

        case .float:
            if isNull { return NSNumber(value: 0.0) }
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
            let string = originalValue as? String ?? ""
            let isTrue = (string as NSString).caseInsensitiveCompare("true") == .orderedSame
            return NSNumber(value: isTrue)
        }
    }
}
