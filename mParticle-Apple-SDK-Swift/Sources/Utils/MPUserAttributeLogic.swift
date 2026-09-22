import Foundation

/// Pure value transforms for user attributes. The caller keeps every side
/// effect — storage reads/writes, `MParticle`/persistence access,
/// `MPUserAttributeChange` construction, and logging.
@objc public final class MPUserAttributeLogic: NSObject {
    /// Storage encodes a null/removed attribute as a sentinel string. Reading
    /// converts that sentinel back to `NSNull` for in-memory use; only string
    /// values are considered, every other value is left untouched.
    @objc(attributesFromStorage:nullSentinel:)
    public static func attributesFromStorage(_ attributes: [AnyHashable: Any], nullSentinel: String) -> [AnyHashable: Any] {
        var result = attributes
        for (key, value) in attributes where (value as? String) == nullSentinel {
            result[key] = NSNull()
        }
        return result
    }

    /// The inverse used before persisting: an `NSNull` value becomes the
    /// sentinel string; every other value is left untouched.
    @objc(attributesForStorage:nullSentinel:)
    public static func attributesForStorage(_ attributes: [AnyHashable: Any], nullSentinel: String) -> [AnyHashable: Any] {
        var result = attributes
        for (key, value) in attributes where value is NSNull {
            result[key] = nullSentinel
        }
        return result
    }

    /// Sums two numeric attribute values using `NSDecimalNumber` on their string
    /// representations, matching the Objective-C `decimalNumberByAdding:`.
    @objc(incrementedValueFrom:byValue:)
    public static func incrementedValue(from current: NSNumber, byValue value: NSNumber) -> NSNumber {
        let base = NSDecimalNumber(string: current.stringValue)
        let increment = NSDecimalNumber(string: value.stringValue)
        return base.adding(increment)
    }

    /// What applying an attribute change should do to the stored attributes.
    ///
    /// A nil value is only a removal when the key is actually present; asking to remove an absent
    /// key is rejected, as is every other validation failure. The caller reports
    /// `MPExecStatusInvalidDataType` for `reject` regardless of which rule failed, which is what
    /// the original did once its redundant early return for `kInvalidDataType` is folded in.
    @objc(mutationForValidationResult:keyExists:)
    public static func mutation(
        forValidationResult result: MPAttributeValidationResult,
        keyExists: Bool
    ) -> MPUserAttributeMutation {
        switch result {
        case .valid: .store
        case .nilValue: keyExists ? .delete : .reject
        default: .reject
        }
    }

    /// The value as it is reported in the attribute-change message: numbers are logged as their
    /// string representation, everything else unchanged.
    @objc(valueToLogFor:)
    public static func valueToLog(for value: Any?) -> Any? {
        (value as? NSNumber)?.stringValue ?? value
    }
}

/// What `setUserAttributeChange:` should do to the stored attribute dictionary.
@objc public enum MPUserAttributeMutation: Int {
    /// Write the value at the key.
    case store
    /// Remove the key and record it as deleted for the next upload.
    case delete
    /// Change nothing and report an invalid data type.
    case reject
}
