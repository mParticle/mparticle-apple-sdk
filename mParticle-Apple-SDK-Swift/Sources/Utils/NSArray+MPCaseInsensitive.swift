import Foundation

public extension NSArray {
    /// Returns whether the array contains a string equal to `object`, ignoring case.
    ///
    /// The parameter is `Any?` rather than `String` because Objective-C callers pass raw
    /// attribute values, which may be `NSNull` or a number. A `String` parameter is bridged
    /// by the generated `@objc` thunk before this body runs, so those callers would raise
    /// an unrecognised-selector exception from inside the bridge instead of getting `false`.
    @objc func caseInsensitiveContainsObject(_ object: Any?) -> Bool {
        guard let object = object as? String else {
            return false
        }
        return contains { item in
            guard let item = item as? String else {
                return false
            }
            return item.caseInsensitiveCompare(object) == .orderedSame
        }
    }
}

public extension Array {
    func caseInsensitiveContainsObject(_ object: String) -> Bool {
        return (self as NSArray).caseInsensitiveContainsObject(object)
    }
}
