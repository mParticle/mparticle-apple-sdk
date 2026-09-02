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
}
