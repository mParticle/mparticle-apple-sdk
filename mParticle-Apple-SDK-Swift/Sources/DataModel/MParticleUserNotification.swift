import Foundation

@objc(MParticleUserNotificationPRIVATE)
public final class MParticleUserNotificationPRIVATE: NSObject {
    private enum Keys {
        static let aps = "aps"
        static let alert = "alert"
        static let body = "body"
        static let contentAvailable = "content-available"
        static let category = "category"
    }

    @objc public private(set) var redactedUserNotificationString: String?
    @objc public private(set) var categoryIdentifier: String?

    @objc(initWithNotificationDictionary:)
    public init(notificationDictionary: [AnyHashable: Any]?) {
        super.init()
        redact(notificationDictionary)
    }

    private func redact(_ notification: [AnyHashable: Any]?) {
        guard let notification else { return }

        if notification[Keys.contentAvailable] != nil {
            redactedUserNotificationString = Self.jsonString(from: notification)
            return
        }

        guard let aps = notification[Keys.aps] as? [AnyHashable: Any] else {
            return
        }

        categoryIdentifier = aps[Keys.category] as? String

        guard let alert = aps[Keys.alert] else {
            redactedUserNotificationString = Self.jsonString(from: notification)
            return
        }

        var redactedNotification = notification
        redactedNotification.removeValue(forKey: Keys.aps)
        var redactedAps: [AnyHashable: Any] = [:]

        if alert is String {
            for (key, value) in aps where (key as? String) != Keys.alert {
                redactedAps[key] = value
            }
        } else if let alertDictionary = alert as? [AnyHashable: Any] {
            for (key, value) in aps {
                if (key as? String) == Keys.alert {
                    var strippedAlert: [AnyHashable: Any] = [:]
                    for (alertKey, alertValue) in alertDictionary where (alertKey as? String) != Keys.body {
                        strippedAlert[alertKey] = alertValue
                    }
                    redactedAps[Keys.alert] = strippedAlert
                } else {
                    redactedAps[key] = value
                }
            }
        }

        redactedNotification[Keys.aps] = redactedAps
        redactedUserNotificationString = Self.jsonString(from: redactedNotification)
    }

    @objc(isEqualWithUserNotificationId:redactedString:otherUserNotificationId:otherRedactedString:)
    public static func isEqual(userNotificationId: Int64,
                               redactedString: String?,
                               otherUserNotificationId: Int64,
                               otherRedactedString: String?) -> Bool {
        if userNotificationId > 0, otherUserNotificationId > 0, userNotificationId == otherUserNotificationId {
            return true
        }

        if let redactedString,
           let otherRedactedString,
           let first = jsonDictionary(from: redactedString),
           let second = jsonDictionary(from: otherRedactedString) {
            return first.isEqual(second)
        }

        return false
    }

    private static func jsonString(from dictionary: [AnyHashable: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private static func jsonDictionary(from string: String) -> NSDictionary? {
        guard let data = string.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: []) else {
            return nil
        }
        return object as? NSDictionary
    }
}
