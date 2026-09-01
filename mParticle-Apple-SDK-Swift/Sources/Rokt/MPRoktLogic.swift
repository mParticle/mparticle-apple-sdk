import Foundation

/// Foundation-only helpers behind `MPRokt`. The ObjC wrapper owns SDK types, kit
/// forwarding, identity calls, and logging; this type remaps attributes, reads kit
/// config, and determines whether an identity update is needed.
@objc(MPRoktLogicPRIVATE) public final class MPRoktLogicPRIVATE: NSObject {
    @objc public static let kitId: Int = 181
    @objc public static let kitConfigurationIdKey = "id"
    @objc public static let attributeMappingSourceKey = "map"
    @objc public static let attributeMappingDestinationKey = "value"
    @objc public static let sandboxAttributeKey = "sandbox"
    @objc public static let remoteConfigKitConfigurationKey = "as"
    @objc public static let placementAttributesMappingKey = "placementAttributesMapping"
    @objc public static let hashedEmailUserIdentityTypeKey = "hashedEmailUserIdentityType"
    @objc public static let emailAttributeKey = "email"
    @objc public static let hashedEmailAttributeKey = "emailsha256"

    @objc public static var emailIdentityNumber: NSNumber {
        NSNumber(value: MPIdentitySwift.email.rawValue)
    }

    // MARK: - Kit configuration

    @objc(kitConfigurationFromOriginalConfig:)
    public static func kitConfiguration(fromOriginalConfig configs: NSArray?) -> NSDictionary? {
        guard let configs else { return nil }
        for case let kitConfig as NSDictionary in configs where integerValue(kitConfig[kitConfigurationIdKey]) == kitId {
            return kitConfig
        }
        return nil
    }

    @objc(kitIdsFromOriginalConfig:)
    public static func kitIds(fromOriginalConfig configs: NSArray?) -> NSArray {
        let ids = NSMutableArray()
        guard let configs else { return ids }
        for case let kitConfig as NSDictionary in configs {
            ids.add(kitConfig[kitConfigurationIdKey] ?? "nil")
        }
        return ids
    }

    @objc(placementAttributesMappingFromKitConfig:)
    public static func placementAttributesMapping(from kitConfig: NSDictionary?) -> NSArray? {
        guard kitConfig != nil else { return nil }

        var attributeMap: NSArray = []
        let nested = kitConfig?[remoteConfigKitConfigurationKey] as? NSDictionary
        let configJSONString = nested?[placementAttributesMappingKey]
        if let configJSONString, !(configJSONString is NSNull),
           let encoded = configJSONString as? String,
           let decoded = encoded.removingPercentEncoding,
           let data = decoded.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                if let array = json as? NSArray {
                    attributeMap = array
                } else {
                    attributeMap = []
                }
            } catch {
                return nil
            }
        }
        return attributeMap
    }

    @objc(hashedEmailIdentityTypeFromKitConfig:)
    public static func hashedEmailIdentityType(from kitConfig: NSDictionary?) -> NSNumber? {
        let nested = kitConfig?[remoteConfigKitConfigurationKey] as? NSDictionary
        let typeString = nested?[hashedEmailUserIdentityTypeKey] as? String
        return MPIdentityHTTPIdentitiesPRIVATE.identityType(for: typeString?.lowercased())
    }

    // MARK: - Attributes

    @objc(mappedPlacementAttributes:attributeMap:)
    public static func mappedPlacementAttributes(_ attributes: NSDictionary?,
                                                 attributeMap: NSArray?) -> NSMutableDictionary {
        let mapped = NSMutableDictionary()
        attributes?.enumerateKeysAndObjects { key, value, _ in
            mapped[key] = value
        }
        guard let attributeMap else { return mapped }
        for case let map as NSDictionary in attributeMap {
            let mapFrom = map[attributeMappingSourceKey]
            let mapTo = map[attributeMappingDestinationKey]
            if let mapFrom, let value = mapped[mapFrom] {
                mapped.removeObject(forKey: mapFrom)
                if let mapTo {
                    mapped[mapTo] = value
                }
            }
        }
        return mapped
    }

    @objc(attributesByConfirmingSandbox:isDevelopment:)
    public static func attributesByConfirmingSandbox(_ attributes: NSDictionary?,
                                                     isDevelopment: Bool) -> NSDictionary {
        let sandboxValue = isDevelopment ? "true" : "false"
        let finalAttributes = NSMutableDictionary()
        if let attributes {
            attributes.enumerateKeysAndObjects { key, value, _ in
                finalAttributes[key] = value
            }
            if !(finalAttributes.allKeys as NSArray).contains(sandboxAttributeKey) {
                finalAttributes[sandboxAttributeKey] = sandboxValue
            }
        } else {
            finalAttributes[sandboxAttributeKey] = sandboxValue
        }
        return finalAttributes
    }

    @objc(confirmUserDecisionWithEmail:hashedEmail:hashedEmailIdentity:identities:)
    public static func confirmUserDecision(email: String?,
                                           hashedEmail: String?,
                                           hashedEmailIdentity: NSNumber?,
                                           identities: NSDictionary?) -> MPRoktConfirmUserDecisionPRIVATE {
        let decision = MPRoktConfirmUserDecisionPRIVATE()
        if let email {
            let current = identities?[emailIdentityNumber]
            decision.shouldIdentifyFromEmail = !(email as NSString).isEqual(current)
        }
        if let hashedEmail, let hashedEmailIdentity {
            let current = identities?[hashedEmailIdentity]
            decision.shouldIdentifyFromHash = !(hashedEmail as NSString).isEqual(current)
        }
        return decision
    }

    // MARK: - Kit dispatch

    @objc(sessionIdFromKit:)
    public static func sessionId(from kitInstance: Any?) -> String? {
        guard let dispatchTarget = kitInstance as? MPRoktKitDispatchTarget else {
            return nil
        }
        return dispatchTarget.getSessionId?()
    }

    @objc(invokeHandleURLCallbackOnKit:url:)
    public static func invokeHandleURLCallback(on kitInstance: Any?, url: URL?) -> Bool {
        guard let dispatchTarget = kitInstance as? MPRoktKitDispatchTarget,
              let url else {
            return false
        }
        return dispatchTarget.handleURLCallback?(url) ?? false
    }

    @objc(performLogMParticleApiDiagnosticOnKit:code:)
    public static func performLogMParticleApiDiagnostic(on kitInstance: Any?, code: String) {
        guard let dispatchTarget = kitInstance as? MPRoktKitDispatchTarget else {
            return
        }
        dispatchTarget.logMParticleApiDiagnostic?(code)
    }

    private static func integerValue(_ value: Any?) -> Int {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let string as NSString:
            return string.integerValue
        default:
            return 0
        }
    }
}

@objc(MPRoktConfirmUserDecisionPRIVATE) public final class MPRoktConfirmUserDecisionPRIVATE: NSObject {
    @objc public var shouldIdentifyFromEmail = false
    @objc public var shouldIdentifyFromHash = false

    @objc public var shouldIdentify: Bool {
        shouldIdentifyFromEmail || shouldIdentifyFromHash
    }
}
