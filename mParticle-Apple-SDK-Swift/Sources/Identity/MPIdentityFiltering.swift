import Foundation

/// Swift-backed identity marshalling and kit-filtering logic shared by the
/// identity "filtered" wrappers (`FilteredMParticleUser`,
/// `FilteredMPIdentityApiRequest`) and the `MParticleUser` identity read path.
///
/// The Swift module cannot import the ObjC module, so every SDK-type access
/// (the data-plan filter, the state machine, the kit configuration, the hasher)
/// stays in the ObjC callers. This helper operates only on Foundation values
/// handed across the boundary, including an `isBlocked` block the caller uses to
/// consult the data-plan filter.
@objc public final class MPIdentityFilteringPRIVATE: NSObject {

    /// Identity types at or above this raw value are device identities (IDFA,
    /// IDFV, push token, application stamp) that are never forwarded to kits.
    private static let firstDeviceIdentityType = MPIdentitySwift.iosAdvertiserId.rawValue

    /// Parse the persisted user-identity array (`[{"n": type, "i": value}]`)
    /// into a `type → value` map. Mirrors the array→dictionary transform in
    /// `MParticleUser.identities`; the device-privacy (ATT) strip stays in ObjC
    /// because it reads the state machine.
    @objc(userIdentitiesFromStoredArray:)
    public func userIdentities(fromStoredArray array: [[AnyHashable: Any]]?) -> [NSNumber: String] {
        var result: [NSNumber: String] = [:]
        array?.forEach { entry in
            if let type = entry["n"] as? NSNumber, let identity = entry["i"] as? String {
                result[type] = identity
            }
        }
        return result
    }

    /// Filter a `type → value` identity map for a kit: drop identities the kit
    /// config blocks (`userIdentityFilters[type] == 0`), all device identities,
    /// and any type the data-plan filter blocks (via `isBlocked`). Values are
    /// `Any` because a request map may hold `NSNull` for a cleared identity.
    @objc(filterUserIdentities:userIdentityFilters:isBlocked:)
    public func filterUserIdentities(_ identities: [NSNumber: Any],
                                     userIdentityFilters: [AnyHashable: Any]?,
                                     isBlocked: (NSNumber) -> Bool) -> [NSNumber: Any] {
        var result: [NSNumber: Any] = [:]
        for (key, value) in identities {
            if isIdentityFiltered(key, filters: userIdentityFilters) {
                continue
            }
            if !isBlocked(key) {
                result[key] = value
            }
        }
        return result
    }

    /// Filter a user-attribute map for a kit: drop attributes the kit config
    /// blocks (`userAttributeFilters[hash(key)] == 0`) and any key the data-plan
    /// filter blocks (via `isBlocked`). Hashing uses the caller's `MPIHasher`
    /// so the key hashing stays byte-identical to the previous implementation.
    @objc(filterUserAttributes:userAttributeFilters:hasher:isBlocked:)
    public func filterUserAttributes(_ attributes: [String: Any],
                                     userAttributeFilters: [AnyHashable: Any]?,
                                     hasher: MPIHasher,
                                     isBlocked: (String) -> Bool) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in attributes {
            let hashKey = hasher.hashString(key)
            if isZero(userAttributeFilters?[hashKey]) {
                continue
            }
            if !isBlocked(key) {
                result[key] = value
            }
        }
        return result
    }

    private func isIdentityFiltered(_ key: NSNumber, filters: [AnyHashable: Any]?) -> Bool {
        if isZero(filters?[key.stringValue]) {
            return true
        }
        return key.intValue >= MPIdentityFilteringPRIVATE.firstDeviceIdentityType
    }

    /// A filter entry blocks its key when it exists and equals `0` — the exact
    /// `entry && [entry isEqualToNumber:@0]` test from the ObjC filters.
    private func isZero(_ value: Any?) -> Bool {
        return (value as? NSNumber)?.intValue == 0
    }
}
