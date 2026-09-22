import Foundation

/// Pure array logic for reading stored user identities. The caller keeps every
/// side effect — user-defaults access, `MParticle`/ATT status reads,
/// `MPUserIdentityChangePRIVATE` construction, logging, and persistence.
@objc public final class MPUserIdentityLogic: NSObject {
    /// Keeps only well-formed identity entries: the type must be a number below
    /// the first non-user identity type (`maxValidTypeExclusive`). Malformed or
    /// out-of-range entries are dropped; order is preserved.
    @objc(validIdentities:typeKey:maxValidTypeExclusive:)
    public static func validIdentities(
        _ identities: [[AnyHashable: Any]],
        typeKey: String,
        maxValidTypeExclusive: Int
    ) -> [[AnyHashable: Any]] {
        identities.filter { entry in
            guard let type = entry[typeKey] as? NSNumber else { return false }
            return type.intValue < maxValidTypeExclusive
        }
    }

    /// Removes the first identity entry of `type` when the caller says it must be
    /// dropped (e.g. the advertiser id while ATT is not authorized). Order is
    /// preserved; a no-op when the flag is false or no entry matches.
    @objc(identities:removingType:when:typeKey:)
    public static func identities(
        _ identities: [[AnyHashable: Any]],
        removingType type: Int,
        when shouldRemove: Bool,
        typeKey: String
    ) -> [[AnyHashable: Any]] {
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

    /// Decides what setting `value` for `identityType` should do to the stored identity array.
    ///
    /// Two asymmetries in the original are preserved deliberately:
    ///
    /// - The "already set to this value" check inspects the **last** entry of the type, while the
    ///   mutation acts on the **first**. With well-formed storage there is at most one entry per
    ///   type and the two agree, but the original's behaviour on a duplicated type is kept.
    /// - An empty-string value is *valid* for the equality check (it is not null) yet *removes* in
    ///   the mutation, so setting "" over a stored "" reports unchanged rather than removing.
    ///
    /// The caller keeps every side effect: mutating the array, building
    /// `MPUserIdentityChangePRIVATE`, persisting, logging and reporting the exec status.
    @objc(planForIdentityType:value:currentIdentities:typeKey:idKey:dateFirstSetKey:now:)
    public static func plan(
        forIdentityType identityType: NSNumber,
        value: String?,
        currentIdentities: [[String: Any]],
        typeKey: String,
        idKey: String,
        dateFirstSetKey: String,
        now: Date
    ) -> MPUserIdentityChangePlan {
        let matchesType: ([String: Any]) -> Bool = { entry in
            guard let type = entry[typeKey] as? NSNumber else { return false }
            return type.isEqual(to: identityType)
        }

        // A stored id that is absent, `NSNull`, or not a string counts as "no valid old identity",
        // the same as the original's `MPIsNull` guard.
        if let existingValue = currentIdentities.last(where: matchesType)?[idKey] as? String,
           let value,
           existingValue == value {
            return MPUserIdentityChangePlan(kind: .unchanged)
        }

        let index = currentIdentities.firstIndex(where: matchesType)

        guard let value, !value.isEmpty else {
            guard let index else { return MPUserIdentityChangePlan(kind: .nothingToRemove) }
            return MPUserIdentityChangePlan(
                kind: .remove,
                index: index,
                existingIdentity: currentIdentities[index]
            )
        }

        guard let index else {
            return MPUserIdentityChangePlan(kind: .add, dateFirstSet: now, isFirstTimeSet: true)
        }

        let existingIdentity = currentIdentities[index]
        return MPUserIdentityChangePlan(
            kind: .replace,
            index: index,
            existingIdentity: existingIdentity,
            dateFirstSet: dateFirstSet(fromMilliseconds: existingIdentity[dateFirstSetKey] as? NSNumber),
            isFirstTimeSet: false
        )
    }
}

/// What setting a user identity should do to the stored identity array.
@objc public enum MPUserIdentityChangeKind: Int {
    /// The stored value already equals the requested one: persist nothing, report a failed status.
    case unchanged
    /// A removal was requested but no entry of that type exists: persist nothing, report success.
    case nothingToRemove
    case remove
    case add
    case replace
}

@objc(MPUserIdentityChangePlan)
public final class MPUserIdentityChangePlan: NSObject {
    @objc public let kind: MPUserIdentityChangeKind
    /// Index into the identities array for `remove`/`replace`, `NSNotFound` otherwise.
    @objc public let index: Int
    /// The entry being removed or replaced, so the caller can build the old identity from it.
    @objc public let existingIdentity: [String: Any]?
    /// What to stamp on the new identity: `now` for `add`, the stored first-set date for `replace`.
    @objc public let dateFirstSet: Date?
    @objc public let isFirstTimeSet: Bool

    init(
        kind: MPUserIdentityChangeKind,
        index: Int = NSNotFound,
        existingIdentity: [String: Any]? = nil,
        dateFirstSet: Date? = nil,
        isFirstTimeSet: Bool = false
    ) {
        self.kind = kind
        self.index = index
        self.existingIdentity = existingIdentity
        self.dateFirstSet = dateFirstSet
        self.isFirstTimeSet = isFirstTimeSet
        super.init()
    }
}
