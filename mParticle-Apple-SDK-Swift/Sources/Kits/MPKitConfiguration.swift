import Foundation

/// One kit's entry from the server configuration's `eks` array, parsed once when it arrives.
@objc(MPKitConfiguration)
public final class MPKitConfiguration: NSObject {
    /// Mirrors `+[MPEnum messageTypeSize]`, which this module cannot import. The Objective-C
    /// MPKitConfigurationTests compare the projection arrays this sizes against the real one.
    static let messageTypeSize: UInt = 20

    @objc let configurationHash: NSNumber
    /// The kit's `as` settings with the attribute lists merged in, or nil when `as` is not an object.
    @objc public let configuration: NSDictionary?
    @objc public let filters: NSDictionary?
    @objc public let bracketConfiguration: NSDictionary?
    @objc public let configuredMessageTypeProjections: [NSNumber]?
    /// Index-aligned with `configuredMessageTypeProjections`: each entry is an
    /// `MPKitProjectionSnapshot`, or `NSNull` where that message type has no default projection.
    @objc public let defaultProjections: NSArray?
    @objc public let projections: [MPKitProjectionSnapshot]?
    /// Never nil on a configuration that exists; the initialiser rejects an entry without one.
    @objc public let integrationId: NSNumber?

    @objc public let attributeValueFilteringIsActive: Bool
    @objc public let attributeValueFilteringShouldIncludeMatches: Bool
    @objc public let attributeValueFilteringHashedAttribute: String?
    @objc public let attributeValueFilteringHashedValue: String?

    @objc let eventTypeFilters: NSDictionary?
    @objc let eventNameFilters: NSDictionary?
    @objc let eventAttributeFilters: NSDictionary?
    @objc let messageTypeFilters: NSDictionary?
    @objc let screenNameFilters: NSDictionary?
    @objc let screenAttributeFilters: NSDictionary?
    @objc public let userIdentityFilters: NSDictionary?
    @objc public let userAttributeFilters: NSDictionary?
    @objc let commerceEventAttributeFilters: NSDictionary?
    @objc let commerceEventEntityTypeFilters: NSDictionary?
    @objc let commerceEventAppFamilyAttributeFilters: NSDictionary?
    @objc let addEventAttributeList: NSDictionary?
    @objc let removeEventAttributeList: NSDictionary?
    @objc let singleItemEventAttributeList: NSDictionary?
    @objc public let consentRegulationFilters: NSDictionary?
    @objc public let consentPurposeFilters: NSDictionary?
    @objc public let consentKitFilter: MPConsentKitFilter?
    @objc public let excludeAnonymousUsers: Bool

    /// For tests only: parses with a logger that logs nothing. It is internal, so the SwiftPM and
    /// CocoaPods builds do not export it; the SDK passes its own logger to `init(dictionary:logger:)`.
    @objc(initWithDictionary:)
    convenience init?(dictionary configurationDictionary: Any?) {
        self.init(dictionary: configurationDictionary, logger: MPLog(logLevel: .none))
    }

    /// Returns nil for an entry that is not a JSON object or has no numeric `id`. `logger` receives
    /// the parse warnings, and is not used for an entry rejected as not being a JSON object.
    @objc(initWithDictionary:logger:)
    public init?(dictionary configurationDictionary: Any?, logger: MPLog) {
        // A kit entry reaches here straight from parsed or unarchived configuration, so its type is
        // only known now. Every read below, starting with the configuration hash, assumes an object.
        guard let dictionary = configurationDictionary as? NSDictionary,
              JSONSerialization.isValidJSONObject(dictionary)
        else {
            return nil
        }

        let configurationData = (try? JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys)) ?? Data()
        let hasher = MPIHasher(logger: logger)
        configurationHash = Self.hashNumber(from: hasher.hashString(String(data: configurationData, encoding: .utf8) ?? ""))

        let attributeValueFilter = MPKitConfigurationParser.attributeValueFilter(from: dictionary as? [AnyHashable: Any])
        let isAttributeValueFilterActive = attributeValueFilter.isActive
        attributeValueFilteringIsActive = isAttributeValueFilterActive
        attributeValueFilteringShouldIncludeMatches = isAttributeValueFilterActive && attributeValueFilter.shouldIncludeMatches
        attributeValueFilteringHashedAttribute = isAttributeValueFilterActive ? attributeValueFilter.hashedAttribute : nil
        attributeValueFilteringHashedValue = isAttributeValueFilterActive ? attributeValueFilter.hashedValue : nil

        // sanitizedFilters(from:) types the filter container but not its members, and every
        // sub-filter is subscripted by its consumers, so a wrong-typed member is dropped rather
        // than published under a type it does not have.
        let filters = MPKitConfigurationParser.sanitizedFilters(from: dictionary[RemoteConfig.kMPRemoteConfigKitHashesKey])
        func subFilter(_ key: String) -> NSDictionary? {
            filters?[key] as? NSDictionary
        }
        self.filters = filters
        eventTypeFilters = subFilter("et")
        eventNameFilters = subFilter("ec")
        eventAttributeFilters = subFilter("ea")
        messageTypeFilters = subFilter("mt")
        screenNameFilters = subFilter("svec")
        screenAttributeFilters = subFilter("svea")
        userIdentityFilters = subFilter("uid")
        userAttributeFilters = subFilter("ua")
        commerceEventAttributeFilters = subFilter("cea")
        commerceEventEntityTypeFilters = subFilter("ent")
        commerceEventAppFamilyAttributeFilters = subFilter("afa")
        addEventAttributeList = subFilter("eaa")
        removeEventAttributeList = subFilter("ear")
        singleItemEventAttributeList = subFilter("eas")
        consentRegulationFilters = subFilter(ConsentFilteringSwift.kMPConsentRegulationFilters)
        consentPurposeFilters = subFilter(ConsentFilteringSwift.kMPConsentPurposeFilters)

        configuration = MPKitConfigurationParser.mergedConfiguration(
            from: dictionary["as"],
            addEventAttributeList: addEventAttributeList,
            removeEventAttributeList: removeEventAttributeList,
            singleItemEventAttributeList: singleItemEventAttributeList
        )

        // The factory skips any element that is not an object, but needs the container to be an array.
        let projectionSet = MPKitProjectionSnapshotFactory(hasher: hasher, logger: logger)
            .projectionSet(from: dictionary["pr"] as? [Any], messageTypeCount: Self.messageTypeSize)
        configuredMessageTypeProjections = projectionSet.configuredMessageTypeProjections
        defaultProjections = projectionSet.defaultProjections.map { $0 as NSArray }
        projections = projectionSet.projections

        consentKitFilter = MPConsentSerializationPRIVATE.filter(from: dictionary[ConsentFilteringSwift.kMPConsentKitFilter])

        // The container subscripts bracketConfiguration for lo/hi and keys kitConfigurations by
        // integrationId, comparing it with isEqualToNumber:, so neither tolerates another type.
        bracketConfiguration = dictionary[RemoteConfig.kMPRemoteConfigBracketKey] as? NSDictionary
        integrationId = dictionary["id"] as? NSNumber
        guard integrationId != nil else {
            return nil
        }

        // NSNumber and NSString both answer boolValue and remote configuration uses either
        // interchangeably; anything else is ignored.
        let excludeAnonymousUsersValue = dictionary[RemoteConfig.kMPRemoteConfigExcludeAnonymousUsersKey]
        excludeAnonymousUsers = MPJSONCoercion.boolValue(excludeAnonymousUsersValue) ?? false

        super.init()
    }

    /// `-[NSString intValue]`, as Objective-C read the hash: it clamps an out-of-range value and
    /// reads an empty string as 0, where `Int32(_:)` would return nil.
    static func hashNumber(from hashString: String) -> NSNumber {
        NSNumber(value: (hashString as NSString).intValue)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPKitConfiguration else {
            return false
        }
        return configurationHash.isEqual(to: other.configurationHash)
    }

    override public var hash: Int {
        configurationHash.hash
    }
}
