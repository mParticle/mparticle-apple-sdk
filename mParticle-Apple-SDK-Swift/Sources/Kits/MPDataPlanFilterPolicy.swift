import Foundation

@objc(MPDataPlanFilterPolicy)
public final class MPDataPlanFilterPolicy: NSObject {
    /// `%@` renders a nil object as "(null)", and several of these keys are
    /// built from optional criteria, so that spelling is part of the key.
    private static let nilDescription = "(null)"

    @objc(matchKeyForScreenName:)
    public static func matchKey(screenName: String?) -> String {
        matchKey(matchType: "screen_view", key: screenName)
    }

    @objc(matchKeyForMatchType:key:)
    public static func matchKey(matchType: String, key: String?) -> String {
        guard let key else {
            return "\(matchType).\(nilDescription)"
        }
        return "\(matchType).\(key.replacingOccurrences(of: "_", with: ""))"
    }

    @objc(matchKeyForEventType:eventName:)
    public static func matchKey(eventType: String?, eventName: String?) -> String {
        let mutatedType = eventType
            .map { $0.replacingOccurrences(of: "_", with: "").lowercased() } ?? nilDescription
        return "custom_event.\(eventName ?? nilDescription).\(mutatedType)"
    }

    @objc(keyForMatch:)
    public static func key(forMatch match: [AnyHashable: Any]?) -> String? {
        guard let matchType = match?["type"] as? String else {
            return nil
        }
        let criteria = match?["criteria"] as? [AnyHashable: Any]

        switch matchType {
        case "custom_event":
            guard let eventName = criteria?["event_name"] as? String,
                  let eventType = criteria?["custom_event_type"] as? String
            else {
                return nil
            }
            return matchKey(eventType: eventType, eventName: eventName)
        case "screen_view":
            return matchKey(screenName: criteria?["screen_name"] as? String)
        case "product_action", "promotion_action":
            return matchKey(matchType: matchType, key: criteria?["action"] as? String)
        case "product_impression", "user_attributes", "user_identities":
            return matchType
        default:
            return nil
        }
    }

    @objc(isBlockedUserAttributeKey:plannedAttributes:blockUserAttributes:)
    public static func isBlockedUserAttributeKey(
        _ userAttributeKey: String,
        plannedAttributes: [Any]?,
        blockUserAttributes: Bool
    ) -> Bool {
        guard blockUserAttributes, let plannedAttributes else {
            return false
        }
        return !plannedAttributes.contains { ($0 as? String) == userAttributeKey }
    }

    @objc(isBlockedUserIdentityType:plannedIdentities:blockUserIdentities:)
    public static func isBlockedUserIdentityType(
        _ userIdentityType: Int,
        plannedIdentities: [Any]?,
        blockUserIdentities: Bool
    ) -> Bool {
        guard blockUserIdentities, let plannedIdentities else {
            return false
        }
        return !plannedIdentities.contains { ($0 as? NSNumber)?.intValue == userIdentityType }
    }
}
