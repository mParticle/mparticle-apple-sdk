import Foundation

// A received push notification, with its payload redacted for logging.
//
// Keeps the MParticleUserNotification Objective-C runtime name the deleted wrapper had, so the
// forward declarations and -logUserNotification: signatures in Include/MPBackendController.h and
// Include/MPPersistenceController.h stay byte-identical. Reference
// MParticleUserNotificationPRIVATE from Swift, MParticleUserNotification from Objective-C.
//
// behavior and mode cross the boundary as their underlying integer types, and both typedefs stay
// in MParticleUserNotification.h as NS_OPTIONS / NS_ENUM.
//
// Keeping MPUserNotificationBehavior a C NS_OPTIONS is what makes it idiomatic on BOTH sides: the
// Swift importer already turns an NS_OPTIONS into an OptionSet, so any Swift caller that can see
// the Objective-C module writes `[.read, .directOpen]` and `.contains(.read)` today. Only this
// module cannot, because it cannot import the Objective-C one — hence the UInt here.
//
// It must NOT become an @objc enum. Swift emits those as SWIFT_ENUM(..., closed), which cannot
// represent a combined value: mParticle.m passes Read | DirectOpen, and 6 compiles without a
// warning under this project's flags (CLANG_WARN_ENUM_CONVERSION is -Wenum-conversion, which does
// not catch it; -Wassign-enum would, and is off) and then compares false against every case and
// falls through to @unknown default. A silent wrong answer, not a build error.
//
// Note: these are `//` comments, not `///` doc comments. Swift copies doc comments into the
// generated Objective-C header, where clang parses `@class` / `@objc` as documentation commands
// and emits -Wdocumentation-html for the backticks around them.
@objc(MParticleUserNotification)
public final class MParticleUserNotificationPRIVATE: NSObject, NSSecureCoding {
    @objc public var actionTitle: String?
    @objc public var actionIdentifier: String?
    @objc public var deferredPayload: [AnyHashable: Any]?
    @objc public var type: String
    @objc public var uuid: String?
    @objc public var userNotificationId: Int64 = 0
    @objc public var behavior: UInt = 0
    @objc public var shouldPersist: Bool = true

    @objc public private(set) var categoryIdentifier: String?
    @objc public private(set) var localAlertDate: Date?
    @objc public private(set) var redactedUserNotificationString: String?
    @objc public private(set) var receiptTime: Date
    @objc public private(set) var state: String
    @objc public private(set) var mode: Int

    /// Designated initializer. `state` is `nonnull` on the Objective-C interface, so the wrapper's
    /// `if (!state) return nil` guard was unreachable from any caller and is not reproduced.
    @objc(initWithDictionary:state:behavior:mode:)
    public init(dictionary notificationDictionary: [AnyHashable: Any]?,
                state: String,
                behavior: UInt,
                mode: Int) {
        self.state = state
        self.behavior = behavior
        self.mode = mode == Mode.autoDetect ? Mode.remote : mode
        shouldPersist = true
        uuid = NSUUID().uuidString
        type = Constants.pushMessageReceived
        receiptTime = Date()
        super.init()

        let redaction = Self.redact(notificationDictionary)
        redactedUserNotificationString = redaction.redactedString
        categoryIdentifier = redaction.categoryIdentifier
    }

    override public var description: String {
        var description = "User Notification\n Receipt Time: \(receiptTime)\n State: \(state)\n Type Id: \(type)\n"

        if let redactedUserNotificationString {
            description += " Redacted notification: \(redactedUserNotificationString)\n"
        }

        if let categoryIdentifier {
            description += " Category identifier: \(categoryIdentifier)\n"
        }

        if behavior > 0 {
            description += " Behavior: \(Int32(truncatingIfNeeded: behavior))\n"
        }

        if userNotificationId > 0 {
            description += " Notification Id: \(Int32(truncatingIfNeeded: userNotificationId))\n"
        }

        return description
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MParticleUserNotificationPRIVATE else { return false }
        return Self.isEqual(userNotificationId: userNotificationId,
                            redactedString: redactedUserNotificationString,
                            otherUserNotificationId: other.userNotificationId,
                            otherRedactedString: other.redactedUserNotificationString)
    }

    override public var hash: Int {
        Int(truncatingIfNeeded: userNotificationId)
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(receiptTime, forKey: CodingKeys.receiptTime)
        coder.encode(state, forKey: CodingKeys.state)
        coder.encode(type, forKey: CodingKeys.type)
        coder.encode(uuid, forKey: CodingKeys.uuid)
        coder.encode(userNotificationId, forKey: CodingKeys.userNotificationId)
        coder.encode(Int(bitPattern: behavior), forKey: CodingKeys.behavior)
        coder.encode(mode, forKey: CodingKeys.mode)

        if let redactedUserNotificationString {
            coder.encode(redactedUserNotificationString, forKey: CodingKeys.redactedUserNotificationString)
        }
        if let categoryIdentifier {
            coder.encode(categoryIdentifier, forKey: CodingKeys.categoryIdentifier)
        }
        if let actionTitle {
            coder.encode(actionTitle, forKey: CodingKeys.actionTitle)
        }
        if let actionIdentifier {
            coder.encode(actionIdentifier, forKey: CodingKeys.actionIdentifier)
        }
        if let localAlertDate {
            coder.encode(localAlertDate, forKey: CodingKeys.localAlertDate)
        }
        if let deferredPayload {
            coder.encode(deferredPayload, forKey: CodingKeys.deferredPayload)
        }
    }

    /// Every key is read with the class-checked `decodeObject(of:forKey:)`.
    ///
    /// The deleted wrapper read four of them — `actionTitle`, `actionIdentifier`, `localAlertDate`
    /// and `deferredPayload` — with the unchecked `decodeObject(forKey:)` while still reporting
    /// `supportsSecureCoding == true`. Under a secure unarchiver that combination cannot succeed:
    /// the unchecked call validates against the allowed-class set, which holds only the root
    /// class, so the first `NSDate`/`NSDictionary` sets `NSCoder.error` and the whole unarchive
    /// throws. Nothing in the SDK archives this type (persistence stores raw sqlite columns), so
    /// that path was never exercised and no shipped behaviour changes here — but porting the
    /// asymmetry forward would only preserve a decode that cannot run.
    public init?(coder: NSCoder) {
        receiptTime = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.receiptTime) as Date? ?? Date()
        state = coder.decodeObject(of: NSString.self, forKey: CodingKeys.state) as String? ?? ""
        type = coder.decodeObject(of: NSString.self, forKey: CodingKeys.type) as String? ?? ""
        uuid = coder.decodeObject(of: NSString.self, forKey: CodingKeys.uuid) as String?
        userNotificationId = coder.decodeInt64(forKey: CodingKeys.userNotificationId)
        behavior = UInt(bitPattern: coder.decodeInteger(forKey: CodingKeys.behavior))
        mode = coder.decodeInteger(forKey: CodingKeys.mode)
        shouldPersist = true
        super.init()

        categoryIdentifier = coder.decodeObject(of: NSString.self, forKey: CodingKeys.categoryIdentifier) as String?
        redactedUserNotificationString =
            coder.decodeObject(of: NSString.self, forKey: CodingKeys.redactedUserNotificationString) as String?
        actionTitle = coder.decodeObject(of: NSString.self, forKey: CodingKeys.actionTitle) as String?
        actionIdentifier = coder.decodeObject(of: NSString.self, forKey: CodingKeys.actionIdentifier) as String?
        localAlertDate = coder.decodeObject(of: NSDate.self, forKey: CodingKeys.localAlertDate) as Date?
        deferredPayload = coder.decodeObject(of: Self.payloadClasses,
                                             forKey: CodingKeys.deferredPayload) as? [AnyHashable: Any]
    }

    // MARK: - Redaction

    /// Strips the user-visible alert text from a push payload so it can be logged.
    static func redact(_ notification: [AnyHashable: Any]?) -> (redactedString: String?, categoryIdentifier: String?) {
        guard let notification else { return (nil, nil) }

        if notification[Keys.contentAvailable] != nil {
            return (jsonString(from: notification), nil)
        }

        guard let aps = notification[Keys.aps] as? [AnyHashable: Any] else {
            return (nil, nil)
        }

        let categoryIdentifier = aps[Keys.category] as? String

        guard let alert = aps[Keys.alert] else {
            return (jsonString(from: notification), categoryIdentifier)
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
        return (jsonString(from: redactedNotification), categoryIdentifier)
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

    /// The property-list classes a `deferredPayload` may legitimately contain. Needed because a
    /// class-checked decode of a container must name every class reachable inside it.
    private static let payloadClasses: [AnyClass] = [
        NSDictionary.self, NSArray.self, NSString.self, NSNumber.self, NSDate.self, NSData.self, NSNull.self
    ]

    private enum Keys {
        static let aps = "aps"
        static let alert = "alert"
        static let body = "body"
        static let contentAvailable = "content-available"
        static let category = "category"
    }

    private enum CodingKeys {
        static let receiptTime = "receiptTime"
        static let state = "state"
        static let type = "type"
        static let uuid = "uuid"
        static let userNotificationId = "userNotificationId"
        static let behavior = "behavior"
        static let mode = "mode"
        static let redactedUserNotificationString = "redactedUserNotificationString"
        static let categoryIdentifier = "categoryIdentifier"
        static let actionTitle = "actionTitle"
        static let actionIdentifier = "actionIdentifier"
        static let localAlertDate = "localAlertDate"
        static let deferredPayload = "deferredPayload"
    }

    /// Mirrors `MPUserNotificationMode` from `MParticleUserNotification.h`.
    private enum Mode {
        static let autoDetect = 0
        static let remote = 1
    }

    /// Private copy of `kMPPushMessageReceived` (`MPIConstants.m`), which is a C global the Swift
    /// module cannot read.
    private enum Constants {
        static let pushMessageReceived = "received"
    }
}
