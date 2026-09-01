import Foundation

/// A Foundation-only view of the filtering fields in a kit configuration.
@objc(MPKitFilterConfigurationSnapshot)
public final class MPKitFilterConfigurationSnapshot: NSObject {
    fileprivate let filters: [String: Any]
    fileprivate let attributeValueFilteringIsActive: Bool
    fileprivate let attributeValueFilteringHashedAttribute: String?
    fileprivate let attributeValueFilteringHashedValue: String?
    fileprivate let attributeValueFilteringShouldIncludeMatches: Bool

    /// Creates an immutable snapshot from the fields used by kit filtering.
    @objc public init(filters: [AnyHashable: Any]?,
                      attributeValueFilteringIsActive: Bool,
                      attributeValueFilteringHashedAttribute: String?,
                      attributeValueFilteringHashedValue: String?,
                      attributeValueFilteringShouldIncludeMatches: Bool) {
        self.filters = filters?.reduce(into: [:]) { result, element in
            if let key = element.key as? String {
                result[key] = element.value
            }
        } ?? [:]
        self.attributeValueFilteringIsActive = attributeValueFilteringIsActive
        self.attributeValueFilteringHashedAttribute = attributeValueFilteringHashedAttribute
        self.attributeValueFilteringHashedValue = attributeValueFilteringHashedValue
        self.attributeValueFilteringShouldIncludeMatches = attributeValueFilteringShouldIncludeMatches
        super.init()
    }
}

/// A Foundation-only view of an event used by the kit filter engine.
@objc(MPKitEventSnapshot)
public final class MPKitEventSnapshot: NSObject {
    fileprivate let type: UInt
    fileprivate let name: String
    fileprivate let attributes: [String: Any]?
    fileprivate let selectorName: String

    /// Creates an immutable event snapshot.
    @objc public init(type: UInt,
                      name: String,
                      attributes: [String: Any]?,
                      selectorName: String) {
        self.type = type
        self.name = name
        self.attributes = attributes
        self.selectorName = selectorName
        super.init()
    }
}

/// A Foundation-only view of a user's consent state.
@objc(MPKitConsentSnapshot)
public final class MPKitConsentSnapshot: NSObject {
    fileprivate let gdprConsents: [String: NSNumber]?
    fileprivate let ccpaConsent: NSNumber?

    /// Creates an immutable consent snapshot. A missing dictionary remains distinct from an empty one.
    @objc public init(gdprConsents: [String: NSNumber]?, ccpaConsent: NSNumber?) {
        self.gdprConsents = gdprConsents
        self.ccpaConsent = ccpaConsent
        super.init()
    }
}

/// A Foundation-only view of a kit's consent matching rule.
@objc(MPKitConsentFilterSnapshot)
public final class MPKitConsentFilterSnapshot: NSObject {
    fileprivate let javascriptHashes: [NSNumber]
    fileprivate let consentedValues: [NSNumber]
    fileprivate let shouldIncludeOnMatch: Bool

    /// Creates an immutable consent-filter snapshot.
    @objc public init(javascriptHashes: [NSNumber],
                      consentedValues: [NSNumber],
                      shouldIncludeOnMatch: Bool) {
        self.javascriptHashes = javascriptHashes
        self.consentedValues = consentedValues
        self.shouldIncludeOnMatch = shouldIncludeOnMatch
        super.init()
    }
}

/// The entity-level action ObjC should apply to a commerce event copy.
@objc public enum MPKitCommerceEntityAction: Int {
    /// Continue applying commerce filters.
    case continueFiltering
    /// Remove product and impression entities and return the event copy.
    case removeProductsAndImpressions
    /// Remove promotion entities and return the event copy.
    case removePromotions
    /// Return the original event without applying additional filters.
    case returnOriginalEvent
}

/// Describes the policy result for an event.
@objc(MPKitEventFilterDecision)
public final class MPKitEventFilterDecision: NSObject {
    /// Whether the entire event should be filtered.
    @objc public let shouldFilter: Bool
    /// Attributes that remain after key filtering.
    @objc public let filteredAttributes: [String: Any]?
    /// The message type associated with the forwarded selector.
    @objc public let messageType: String?

    fileprivate init(shouldFilter: Bool,
                     filteredAttributes: [String: Any]?,
                     messageType: String?) {
        self.shouldFilter = shouldFilter
        self.filteredAttributes = filteredAttributes
        self.messageType = messageType
        super.init()
    }
}

/// Describes the policy result for a commerce event.
@objc(MPKitCommerceFilterDecision)
public final class MPKitCommerceFilterDecision: NSObject {
    /// Whether the entire commerce event should be filtered.
    @objc public let shouldFilter: Bool
    /// The entity-level action ObjC should apply.
    @objc public let entityAction: MPKitCommerceEntityAction
    /// The app-family property filter for the event kind.
    @objc public let appFamilyFilter: [AnyHashable: Any]?
    /// Expanded attributes that remain after filtering.
    @objc public let filteredBeautifiedAttributes: [String: Any]?
    /// Custom attributes that remain after filtering.
    @objc public let filteredCustomAttributes: [String: Any]?
    /// Transaction attribute keys that remain after filtering.
    @objc public let allowedTransactionAttributeKeys: Set<String>?
    /// Whether commerce attribute filters were configured.
    @objc public let hasAttributeFilters: Bool

    fileprivate init(shouldFilter: Bool,
                     entityAction: MPKitCommerceEntityAction = .continueFiltering,
                     appFamilyFilter: [AnyHashable: Any]? = nil,
                     filteredBeautifiedAttributes: [String: Any]? = nil,
                     filteredCustomAttributes: [String: Any]? = nil,
                     allowedTransactionAttributeKeys: Set<String>? = nil,
                     hasAttributeFilters: Bool = false) {
        self.shouldFilter = shouldFilter
        self.entityAction = entityAction
        self.appFamilyFilter = appFamilyFilter
        self.filteredBeautifiedAttributes = filteredBeautifiedAttributes
        self.filteredCustomAttributes = filteredCustomAttributes
        self.allowedTransactionAttributeKeys = allowedTransactionAttributeKeys
        self.hasAttributeFilters = hasAttributeFilters
        super.init()
    }
}

/// The action ObjC should use to materialize a consent-filter decision.
@objc public enum MPKitConsentAction: Int {
    /// Preserve the existing nil filter result.
    case noFilter
    /// Filter the entire consent state.
    case filterAll
    /// Forward only the CCPA consent state.
    case forwardCCPA
    /// Forward the allowed GDPR purposes.
    case forwardGDPR
}

/// Describes the policy result for a consent state.
@objc(MPKitConsentDecision)
public final class MPKitConsentDecision: NSObject {
    /// The action ObjC should materialize.
    @objc public let action: MPKitConsentAction
    /// GDPR purpose names that remain after filtering.
    @objc public let allowedGDPRPurposes: Set<String>

    fileprivate init(action: MPKitConsentAction, allowedGDPRPurposes: Set<String> = []) {
        self.action = action
        self.allowedGDPRPurposes = allowedGDPRPurposes
        super.init()
    }
}

/// Evaluates kit filtering policy using Foundation-only snapshots and decisions.
@objc(MPKitFilterEngine)
public final class MPKitFilterEngine: NSObject {
    private enum FilterKey {
        static let eventType = "et"
        static let eventName = "ec"
        static let eventAttribute = "ea"
        static let messageType = "mt"
        static let screenName = "svec"
        static let screenAttribute = "svea"
        static let userIdentity = "uid"
        static let userAttribute = "ua"
        static let commerceAttribute = "cea"
        static let commerceEntity = "ent"
        static let commerceAppFamily = "afa"
        static let consentRegulation = "reg"
        static let consentPurpose = "pur"
    }

    private enum Consent {
        static let gdprRegulation = "1"
        static let ccpaRegulation = "2"
        static let ccpaPurpose = "data_sale_opt_out"
    }

    private static let messageTypes = [
        "logBaseEvent:": "e",
        "logEvent:": "e",
        "logScreen:": "v",
        "logScreenEvent:": "v",
        "beginSession": "ss",
        "endSession": "se",
        "logTransaction:": "e",
        "logLTVIncrease:event:": "e",
        "logLTVIncrease:eventName:eventInfo:": "e",
        "leaveBreadcrumb:": "bc",
        "logError:exception:topmostContext:eventInfo:": "x",
        "logNetworkPerformanceMeasurement:": "npe",
        "profileChange:": "pro",
        "setOptOut:": "o",
        "logCommerceEvent:": "cm"
    ]

    private let hasher: MPIHasher
    private let attributeValueFilter: MPAttributeValueFilter

    /// Creates a filter engine using the SDK's stable hashing implementation.
    @objc public init(hasher: MPIHasher) {
        self.hasher = hasher
        attributeValueFilter = MPAttributeValueFilter(hasher: hasher)
        super.init()
    }

    /// Returns the message type associated with a kit selector.
    @objc public func messageType(forSelectorName selectorName: String) -> String? {
        Self.messageTypes[selectorName]
    }

    /// Evaluates event, screen, message, name, attribute, and attribute-value filters.
    @objc public func filterEvent(_ event: MPKitEventSnapshot,
                                  configuration: MPKitFilterConfigurationSnapshot) -> MPKitEventFilterDecision {
        let messageType = messageType(forSelectorName: event.selectorName)
        guard includesAttributeValues(event.attributes, configuration: configuration) else {
            return MPKitEventFilterDecision(shouldFilter: true,
                                            filteredAttributes: nil,
                                            messageType: messageType)
        }

        let isScreen = event.selectorName == "logScreen:"
        if !isScreen,
           isBlocked(hasher.hashString(String(event.type)),
                     by: dictionary(configuration, FilterKey.eventType)) {
            return MPKitEventFilterDecision(shouldFilter: true,
                                            filteredAttributes: nil,
                                            messageType: messageType)
        }

        if let messageType,
           isBlocked(messageType, by: dictionary(configuration, FilterKey.messageType)) {
            return MPKitEventFilterDecision(shouldFilter: true,
                                            filteredAttributes: nil,
                                            messageType: messageType)
        }

        let nameFilters = dictionary(configuration, isScreen ? FilterKey.screenName : FilterKey.eventName)
        let nameHash = hasher.hashString(isScreen ? "0\(event.name)" : "\(event.type)\(event.name)")
        if isBlocked(nameHash, by: nameFilters) {
            return MPKitEventFilterDecision(shouldFilter: true,
                                            filteredAttributes: nil,
                                            messageType: messageType)
        }

        let attributeFilters = dictionary(configuration,
                                          isScreen ? FilterKey.screenAttribute : FilterKey.eventAttribute)
        let filteredAttributes = event.attributes?.reduce(into: [String: Any]()) { result, element in
            let value = isScreen
                ? "0\(event.name)\(element.key)"
                : "\(event.type)\(event.name)\(element.key)"
            if !isBlocked(hasher.hashString(value), by: attributeFilters) {
                result[element.key] = element.value
            }
        }

        return MPKitEventFilterDecision(shouldFilter: false,
                                        filteredAttributes: filteredAttributes?.isEmpty == true ? nil : filteredAttributes,
                                        messageType: messageType)
    }

    /// Evaluates message-type filtering for a base event selector.
    @objc public func shouldFilterBaseEvent(selectorName: String,
                                            configuration: MPKitFilterConfigurationSnapshot) -> Bool {
        guard let messageType = messageType(forSelectorName: selectorName) else { return false }
        return isBlocked(messageType, by: dictionary(configuration, FilterKey.messageType))
    }

    /// Evaluates commerce event, entity, app-family, attribute, and attribute-value filters.
    @objc public func filterCommerceEvent(type: UInt,
                                          kind: Int,
                                          customAttributes: [String: Any]?,
                                          beautifiedAttributes: [String: Any]?,
                                          transactionAttributes: [String: Any]?,
                                          configuration: MPKitFilterConfigurationSnapshot) -> MPKitCommerceFilterDecision {
        guard includesAttributeValues(customAttributes, configuration: configuration),
              !isBlocked(hasher.hashString(String(type)),
                         by: dictionary(configuration, FilterKey.eventType)) else {
            return MPKitCommerceFilterDecision(shouldFilter: true)
        }

        let kindString = String(kind)
        if isBlocked(kindString, by: dictionary(configuration, FilterKey.commerceEntity)) {
            switch kind {
            case 1, 3:
                return MPKitCommerceFilterDecision(shouldFilter: false,
                                                   entityAction: .removeProductsAndImpressions)
            case 2:
                return MPKitCommerceFilterDecision(shouldFilter: false,
                                                   entityAction: .removePromotions)
            default:
                return MPKitCommerceFilterDecision(shouldFilter: false,
                                                   entityAction: .returnOriginalEvent)
            }
        }

        let appFamilyFilters = dictionary(configuration, FilterKey.commerceAppFamily)?[kindString]
            as? [AnyHashable: Any]
        guard let attributeFilters = dictionary(configuration, FilterKey.commerceAttribute) else {
            return MPKitCommerceFilterDecision(shouldFilter: false,
                                               appFamilyFilter: appFamilyFilters)
        }

        func filtered(_ attributes: [String: Any]?) -> [String: Any]? {
            guard let attributes else { return nil }
            let result = attributes.reduce(into: [String: Any]()) { result, element in
                let hash = hasher.hashString("\(type)\(element.key)")
                if !isBlocked(hash, by: attributeFilters) {
                    result[element.key] = element.value
                }
            }
            return result.isEmpty ? nil : result
        }

        let allowedTransactionKeys = Set(transactionAttributes?.keys.filter { key in
            !isBlocked(hasher.hashString("\(type)\(key)"), by: attributeFilters)
        } ?? [])

        return MPKitCommerceFilterDecision(
            shouldFilter: false,
            appFamilyFilter: appFamilyFilters,
            filteredBeautifiedAttributes: filtered(beautifiedAttributes),
            filteredCustomAttributes: filtered(customAttributes),
            allowedTransactionAttributeKeys: allowedTransactionKeys,
            hasAttributeFilters: true
        )
    }

    /// Returns user attributes that remain after filtering, preserving nil and empty-result behavior.
    @objc public func filterUserAttributes(_ attributes: [String: Any]?,
                                           configuration: MPKitFilterConfigurationSnapshot?) -> [String: Any]? {
        guard let attributes, let configuration else { return nil }
        let filters = dictionary(configuration, FilterKey.userAttribute)
        let result = attributes.reduce(into: [String: Any]()) { result, element in
            if !isBlocked(hasher.hashUserAttributeKey(element.key), by: filters) {
                result[element.key] = element.value
            }
        }
        return result.isEmpty ? nil : result
    }

    /// Returns whether a single user attribute should be filtered.
    @objc public func shouldFilterUserAttribute(key: String,
                                                configuration: MPKitFilterConfigurationSnapshot?) -> Bool {
        guard let configuration else { return false }
        return isBlocked(hasher.hashUserAttributeKey(key),
                         by: dictionary(configuration, FilterKey.userAttribute))
    }

    /// Returns whether a user identity type should be filtered.
    @objc public func shouldFilterUserIdentity(type: UInt,
                                               configuration: MPKitFilterConfigurationSnapshot?) -> Bool {
        guard let configuration else { return false }
        return isBlocked(String(type), by: dictionary(configuration, FilterKey.userIdentity))
    }

    /// Evaluates consent regulation and purpose filters.
    @objc public func filterConsent(_ consent: MPKitConsentSnapshot,
                                    configuration: MPKitFilterConfigurationSnapshot?) -> MPKitConsentDecision {
        guard let configuration else { return MPKitConsentDecision(action: .noFilter) }

        if consent.ccpaConsent != nil {
            let hash = hasher.hashConsentPurpose(Consent.ccpaRegulation, purpose: Consent.ccpaPurpose)
            let action: MPKitConsentAction = isBlocked(
                hash,
                by: dictionary(configuration, FilterKey.consentRegulation)
            ) ? .filterAll : .forwardCCPA
            return MPKitConsentDecision(action: action)
        }

        if consent.gdprConsents != nil {
            let hash = hasher.hashConsentPurpose(Consent.gdprRegulation, purpose: "")
            if isBlocked(hash, by: dictionary(configuration, FilterKey.consentRegulation)) {
                return MPKitConsentDecision(action: .filterAll)
            }
        }

        guard let gdprConsents = consent.gdprConsents,
              !gdprConsents.isEmpty,
              dictionary(configuration, FilterKey.consentPurpose) != nil else {
            return MPKitConsentDecision(action: .noFilter)
        }

        let purposeFilters = dictionary(configuration, FilterKey.consentPurpose)
        let allowedPurposes = Set(gdprConsents.keys.filter { purpose in
            let hash = hasher.hashConsentPurpose(Consent.gdprRegulation, purpose: purpose)
            return !isBlocked(hash, by: purposeFilters)
        })
        return allowedPurposes.isEmpty
            ? MPKitConsentDecision(action: .noFilter)
            : MPKitConsentDecision(action: .forwardGDPR, allowedGDPRPurposes: allowedPurposes)
    }

    /// Returns whether a kit should be disabled by its consent matching rule.
    @objc public func isDisabledByConsentFilter(_ filter: MPKitConsentFilterSnapshot?,
                                                consent: MPKitConsentSnapshot?) -> Bool {
        var isMatch = false
        if let filter, let consent {
            for (index, hashNumber) in filter.javascriptHashes.enumerated() {
                guard index < filter.consentedValues.count else { continue }
                let hash = hashNumber.stringValue
                let consented = filter.consentedValues[index].boolValue

                for (purpose, userConsented) in consent.gdprConsents ?? [:] {
                    let purposeHash = hasher.hashConsentPurpose(Consent.gdprRegulation, purpose: purpose)
                    if consented == userConsented.boolValue, purposeHash == hash {
                        isMatch = true
                        break
                    }
                }

                if let ccpaConsent = consent.ccpaConsent {
                    let purposeHash = hasher.hashConsentPurpose(Consent.ccpaRegulation,
                                                                purpose: Consent.ccpaPurpose)
                    if consented == ccpaConsent.boolValue, purposeHash == hash {
                        isMatch = true
                        break
                    }
                }
            }
        }

        let shouldInclude = filter?.shouldIncludeOnMatch == true ? isMatch : !isMatch
        return !shouldInclude
    }

    /// Returns whether an optional bracket excludes the current user.
    @objc public func isDisabledByBracket(mpId: Int64,
                                          low: Int16,
                                          high: Int16,
                                          hasBracket: Bool) -> Bool {
        hasBracket && !MPBracket(mpId: mpId, low: low, high: high).shouldForward()
    }

    /// Combines consent and explicit disabled-kit policy.
    @objc public func isKitDisabled(isDisabledKit: Bool,
                                    consentFilter: MPKitConsentFilterSnapshot?,
                                    consent: MPKitConsentSnapshot?) -> Bool {
        isDisabledKit || isDisabledByConsentFilter(consentFilter, consent: consent)
    }

    /// Combines active, bracket, consent, anonymous-user, and disabled-kit decisions.
    @objc public func isKitActive(active: Bool,
                                  mpId: Int64,
                                  bracketLow: Int16,
                                  bracketHigh: Int16,
                                  hasBracket: Bool,
                                  consentFilter: MPKitConsentFilterSnapshot?,
                                  consent: MPKitConsentSnapshot?,
                                  excludesAnonymousUsers: Bool,
                                  isLoggedIn: Bool,
                                  isDisabledKit: Bool) -> Bool {
        active &&
            !isDisabledByBracket(mpId: mpId, low: bracketLow, high: bracketHigh, hasBracket: hasBracket) &&
            !isKitDisabled(isDisabledKit: isDisabledKit, consentFilter: consentFilter, consent: consent) &&
            !(excludesAnonymousUsers && !isLoggedIn)
    }

    private func includesAttributeValues(_ attributes: [String: Any]?,
                                         configuration: MPKitFilterConfigurationSnapshot) -> Bool {
        attributeValueFilter.shouldIncludeEvent(
            withAttributes: attributes,
            filteringActive: configuration.attributeValueFilteringIsActive,
            hashedAttribute: configuration.attributeValueFilteringHashedAttribute,
            hashedValue: configuration.attributeValueFilteringHashedValue,
            shouldIncludeMatches: configuration.attributeValueFilteringShouldIncludeMatches
        )
    }

    private func dictionary(_ configuration: MPKitFilterConfigurationSnapshot,
                            _ key: String) -> [String: Any]? {
        configuration.filters[key] as? [String: Any]
    }

    private func isBlocked(_ key: String, by filters: [String: Any]?) -> Bool {
        guard let number = filters?[key] as? NSNumber else { return false }
        return number.compare(0) == .orderedSame
    }
}
