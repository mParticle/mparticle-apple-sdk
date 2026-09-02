import Foundation

/// Pure array logic for reading stored user identities. The caller keeps every
/// side effect — user-defaults access, `MParticle`/ATT status reads,
/// `MPUserIdentityChangePRIVATE` construction, logging, and persistence.
@objc public final class MPUserIdentityLogic: NSObject {
    /// Keeps only well-formed identity entries: the type must be a number below
    /// the first non-user identity type (`maxValidTypeExclusive`). Malformed or
    /// out-of-range entries are dropped; order is preserved.
    @objc(validIdentities:typeKey:maxValidTypeExclusive:)
    public static func validIdentities(_ identities: [[AnyHashable: Any]], typeKey: String,
                                       maxValidTypeExclusive: Int) -> [[AnyHashable: Any]] {
        identities.filter { entry in
            guard let type = entry[typeKey] as? NSNumber else { return false }
            return type.intValue < maxValidTypeExclusive
        }
    }

    /// Removes the first identity entry of `type` when the caller says it must be
    /// dropped (e.g. the advertiser id while ATT is not authorized). Order is
    /// preserved; a no-op when the flag is false or no entry matches.
    @objc(identities:removingType:when:typeKey:)
    public static func identities(_ identities: [[AnyHashable: Any]], removingType type: Int,
                                  when shouldRemove: Bool, typeKey: String) -> [[AnyHashable: Any]] {
        guard shouldRemove,
              let index = identities.firstIndex(where: { ($0[typeKey] as? NSNumber)?.intValue == type })
        else {
            return identities
        }
        var result = identities
        result.remove(at: index)
        return result
    }

    /// The "first set" date for an identity: the stored millisecond timestamp
    /// converted to a `Date`, or the current date when absent.
    @objc(dateFirstSetFromMilliseconds:)
    public static func dateFirstSet(fromMilliseconds milliseconds: NSNumber?) -> Date {
        guard let milliseconds else { return Date() }
        return Date(timeIntervalSince1970: milliseconds.doubleValue/1000.0)
    }
}
