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
