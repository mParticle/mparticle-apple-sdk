import Foundation

@objc(MPAttributeValueFilterConfig)
public final class MPAttributeValueFilterConfig: NSObject {
    @objc public let isActive: Bool
    @objc public let shouldIncludeMatches: Bool
    @objc public let hashedAttribute: String?
    @objc public let hashedValue: String?

    init(isActive: Bool, shouldIncludeMatches: Bool, hashedAttribute: String?, hashedValue: String?) {
        self.isActive = isActive
        self.shouldIncludeMatches = shouldIncludeMatches
        self.hashedAttribute = hashedAttribute
        self.hashedValue = hashedValue
        super.init()
    }

    static let inactive = MPAttributeValueFilterConfig(
        isActive: false,
        shouldIncludeMatches: false,
        hashedAttribute: nil,
        hashedValue: nil
    )
}

@objc(MPKitConfigurationParser)
public final class MPKitConfigurationParser: NSObject {
    @objc(attributeValueFilterFromConfiguration:)
    public static func attributeValueFilter(
        from configuration: [AnyHashable: Any]?
    ) -> MPAttributeValueFilterConfig {
        guard let avf = configuration?["avf"] as? [AnyHashable: Any] else {
            return .inactive
        }

        // Only `i` was null-guarded in ObjC. `a` and `v` were plain non-nil
        // checks, so an explicit null still activates the filter and stringifies
        // through %@ as "<null>".
        guard !MPJSONCoercion.isNull(avf["i"]),
              let hashedAttribute = avf["a"],
              let hashedValue = avf["v"]
        else {
            return .inactive
        }

        return MPAttributeValueFilterConfig(
            isActive: true,
            shouldIncludeMatches: MPJSONCoercion.boolValue(avf["i"]) ?? false,
            hashedAttribute: describing(hashedAttribute),
            hashedValue: describing(hashedValue)
        )
    }

    /// Drops the `eks` entries `MPKitConfiguration` would refuse, so an entry that can never
    /// configure a kit is not written to the cache and replayed at every launch. The two
    /// conditions here are exactly what makes that parser return nil: an entry has to be an
    /// object, and its integration id has to be a number, because the id keys the kit
    /// configuration dictionary and is compared with `isEqualToNumber:`.
    ///
    /// Returns the configuration unchanged when every entry is usable, so a well-formed response
    /// is stored byte for byte as it arrived.
    @objc(configurationDroppingUnusableKitsFrom:)
    public static func configurationDroppingUnusableKits(
        from configuration: [AnyHashable: Any]
    ) -> [AnyHashable: Any] {
        guard let kits = configuration[RemoteConfig.kMPRemoteConfigKitsKey] as? [Any] else {
            return configuration
        }

        let usableKits = kits.filter { kit in
            guard let kit = kit as? [AnyHashable: Any] else { return false }
            return kit["id"] is NSNumber
        }

        guard usableKits.count != kits.count else {
            return configuration
        }

        var sanitized = configuration
        sanitized[RemoteConfig.kMPRemoteConfigKitsKey] = usableKits
        return sanitized
    }

    @objc(sanitizedFiltersFrom:)
    public static func sanitizedFilters(from filters: Any?) -> NSDictionary? {
        guard let filters = filters as? [AnyHashable: Any] else {
            return nil
        }

        let sanitized = filters.filter { !MPJSONCoercion.isNull($0.value) }
        return sanitized.isEmpty ? nil : sanitized as NSDictionary
    }

    @objc(mergedConfigurationFrom:addEventAttributeList:removeEventAttributeList:singleItemEventAttributeList:)
    public static func mergedConfiguration(
        from configuration: Any?,
        addEventAttributeList: Any?,
        removeEventAttributeList: Any?,
        singleItemEventAttributeList: Any?
    ) -> NSDictionary? {
        guard let configuration = configuration as? [AnyHashable: Any] else {
            return nil
        }

        // Each overlay was guarded in ObjC, so a nil list leaves any key already
        // present in `as` untouched rather than removing it.
        var merged = configuration
        if let addEventAttributeList {
            merged["eaa"] = addEventAttributeList
        }
        if let removeEventAttributeList {
            merged["ear"] = removeEventAttributeList
        }
        if let singleItemEventAttributeList {
            merged["eas"] = singleItemEventAttributeList
        }

        return merged.filter { !MPJSONCoercion.isNull($0.value) } as NSDictionary
    }

    /// Matches `[NSString stringWithFormat:@"%@", value]`.
    private static func describing(_ value: Any) -> String {
        (value as AnyObject).description ?? String(describing: value)
    }
}
