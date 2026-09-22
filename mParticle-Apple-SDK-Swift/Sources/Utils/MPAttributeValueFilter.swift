import Foundation

/// Decides whether an event survives a kit's attribute-value filter.
/// Behavior-preserving port of
/// `-[MPKitContainer shouldIncludeEventWithAttributes:afterAttributeValueFilteringWithConfiguration:]`.
/// The config lives in ObjC `MPKitConfiguration` (not importable here), so the relevant
/// fields are passed as primitives.
@objc public final class MPAttributeValueFilter: NSObject {
    private let hasher: MPIHasher

    @objc public init(hasher: MPIHasher) {
        self.hasher = hasher
    }

    @objc public func shouldIncludeEvent(withAttributes attributes: [String: Any]?,
                                         filteringActive: Bool,
                                         hashedAttribute: String?,
                                         hashedValue: String?,
                                         shouldIncludeMatches: Bool) -> Bool {
        if !filteringActive {
            return true
        }

        var isMatch = false
        for (key, value) in attributes ?? [:] where hasher.hashUserAttributeKey(key) == hashedAttribute {
            if let stringValue = value as? String,
               hasher.hashUserAttributeValue(stringValue) == hashedValue {
                isMatch = true
            }
            break
        }

        return shouldIncludeMatches ? isMatch : !isMatch
    }
}
