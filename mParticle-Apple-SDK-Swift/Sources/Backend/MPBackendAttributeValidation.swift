import Foundation

/// The code of the error an attribute check reports, by what was wrong with the key or value.
@objc public enum MPAttributeValidationErrorCode: Int {
    case nilValue = 101
    case valueTooLong = 104
    case keyTooLong = 105
    case invalidDataType = 106
    case invalidKey = 107
}

/// Validates an attribute key and value against the SDK's length limits, and logs why a pair was
/// rejected.
@objc(MPBackendAttributeValidation)
public final class MPBackendAttributeValidation: NSObject {
    static let errorDomain = "Attribute Validation"

    /// The result of validating `key` and `value`, after logging the reason for a rejection at the
    /// error level. A nil value logs nothing, because a caller may treat it as a removal.
    static func validate(key: Any?, value: Any?, host: MPBackendHost) -> MPAttributeValidationResult {
        var invalidArrayEntry: AnyObject?
        let result = MPAttributeValidator.validate(
            key: key,
            value: value,
            keyLengthLimit: host.attributeKeyLengthLimit(),
            valueLengthLimit: host.attributeValueLengthLimit(),
            invalidArrayEntry: &invalidArrayEntry
        )
        let logger = host.sdkLogger()
        switch result {
        case .invalidKey:
            logError(logger, "Error while setting attribute key: the key parameter cannot be nil")
        case .keyTooLong:
            logError(logger, "Error while setting attribute key: the key parameter is longer than the maximum allowed length.")
        case .invalidType:
            logError(logger, "Error while setting attribute value: must be an NSString or NSArray")
        case .valueTooLong:
            logError(logger, "Error while setting attribute value: value is longer than the maximum allowed \(describe(value))")
        case .invalidArrayEntry:
            logError(
                logger,
                "Error while setting attribute value list: all user attribute entries in the array must be of type string. "
                    + "Error entry: \(describe(invalidArrayEntry))"
            )
        case .arrayValueTooLong:
            logError(
                logger,
                "Error while setting attribute value list: combined length of list values longer than the maximum alowed."
            )
        case .nilValue, .valid:
            break
        }
        return result
    }

    /// The code `check(key:value:host:)` reports for a validation result.
    static func errorCode(for result: MPAttributeValidationResult) -> MPAttributeValidationErrorCode {
        switch result {
        case .invalidKey: .invalidKey
        case .keyTooLong: .keyTooLong
        case .nilValue: .nilValue
        case .valueTooLong, .arrayValueTooLong: .valueTooLong
        case .invalidType, .invalidArrayEntry, .valid: .invalidDataType
        }
    }

    /// Validates like `validate(key:value:host:)` and throws a rejection as an error in the
    /// "Attribute Validation" domain, with the code `errorCode(for:)` gives.
    @objc(checkKey:value:host:error:)
    public static func check(key: Any?, value: Any?, host: MPBackendHost) throws {
        let result = validate(key: key, value: value, host: host)
        guard result == .valid else {
            throw NSError(domain: errorDomain, code: errorCode(for: result).rawValue)
        }
    }

    /// Builds the message only when the logger would print it: a value a caller passes can be a
    /// test double that answers nothing but its length.
    private static func logError(_ logger: MPLog?, _ message: @autoclosure () -> String) {
        guard let logger, logger.logLevel.rawValue >= MPILogLevelSwift.error.rawValue else { return }
        logger.error(message())
    }

    private static func describe(_ value: Any?) -> String {
        guard let value else { return "(null)" }
        return String(describing: value)
    }
}
