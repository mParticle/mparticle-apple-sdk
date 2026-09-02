import UIKit

/// Mirrors the Objective-C `MPMessageType`; raw values must stay in step.
@objc public enum MPMessageTypeSwift: UInt {
    case unknown = 0
    case sessionStart = 1
    case sessionEnd = 2
    case screenView = 3
    case event = 4
    case crashReport = 5
    case optOut = 6
    case firstRun = 7
    case preAttribution = 8
    case pushRegistration = 9
    case appStateTransition = 10
    case pushNotification = 11
    case networkPerformance = 12
    case breadcrumb = 13
    case profile = 14
    case pushNotificationInteraction = 15
    case commerceEvent = 16
    case userAttributeChange = 17
    case userIdentityChange = 18
    case media = 20
}

@objc(MPUserAttributeChangeFields)
public final class MPUserAttributeChangeFields: NSObject {
    @objc public let deleted: Bool
    @objc public let attributeKey: String
    @objc public let oldValue: Any
    @objc public let newValue: Any
    @objc public let newlyAdded: Bool

    init(deleted: Bool, attributeKey: String, oldValue: Any, newValue: Any, newlyAdded: Bool) {
        self.deleted = deleted
        self.attributeKey = attributeKey
        self.oldValue = oldValue
        self.newValue = newValue
        self.newlyAdded = newlyAdded
        super.init()
    }
}

@objc(MPStateTransitionFields)
public final class MPStateTransitionFields: NSObject {
    @objc public let sourceApplication: String?
    @objc public let launchURLString: String?
    @objc public let launchParameters: Any?
    @objc public let numberOfSessionInterruptions: Int
    @objc public let sessionFinalized: Bool

    init(
        sourceApplication: String?,
        launchURLString: String?,
        launchParameters: Any?,
        numberOfSessionInterruptions: Int,
        sessionFinalized: Bool
    ) {
        self.sourceApplication = sourceApplication
        self.launchURLString = launchURLString
        self.launchParameters = launchParameters
        self.numberOfSessionInterruptions = numberOfSessionInterruptions
        self.sessionFinalized = sessionFinalized
        super.init()
    }
}

@objc(MPMessageBuilderFields)
public final class MPMessageBuilderFields: NSObject {
    /// `nil` when `rawValue` is not one of `MPMessageTypeSwift`'s defined
    /// cases (e.g. the unused value 19) — the Objective-C caller logs and
    /// falls back to `kMPMessageTypeStringUnknown` in that case, the same as
    /// the original switch's `default:` branch did.
    @objc(stringForMessageTypeRawValue:)
    public static func string(forMessageTypeRawValue rawValue: UInt) -> String? {
        guard let messageType = MPMessageTypeSwift(rawValue: rawValue) else {
            return nil
        }
        return string(forMessageType: messageType)
    }

    private static func string(forMessageType messageType: MPMessageTypeSwift) -> String {
        switch messageType {
        case .unknown: kMPMessageTypeStringUnknownSwift
        case .sessionStart: "ss"
        case .sessionEnd: "se"
        case .screenView: "v"
        case .event: "e"
        case .crashReport: "x"
        case .optOut: "o"
        case .firstRun: "fr"
        case .preAttribution: kMPMessageTypeStringUnknownSwift
        case .pushRegistration: "pr"
        case .appStateTransition: "ast"
        case .pushNotification: "pm"
        case .networkPerformance: "npe"
        case .breadcrumb: "bc"
        case .profile: "pro"
        case .pushNotificationInteraction: "pre"
        case .commerceEvent: "cm"
        case .userAttributeChange: "uac"
        case .userIdentityChange: "uic"
        case .media: "media"
        }
    }

    /// The reverse of `string(forMessageType:)`, boxed as `NSNumber?` since an
    /// `@objc` function cannot return an optional enum to Objective-C. `nil`
    /// means the string matched none of the known constants — the caller
    /// logs and falls back to `MPMessageTypeUnknown` in that case, same as
    /// the original if/else chain's final `else` branch.
    ///
    /// Checked in the same order as that chain:
    /// `kMPMessageTypeStringPreAttribution` duplicates
    /// `kMPMessageTypeStringUnknown`'s value ("unknown"), and unknown is
    /// checked first, so a "unknown" string can never round-trip to
    /// `.preAttribution` — that quirk is preserved intentionally.
    @objc(rawMessageTypeForString:)
    public static func rawMessageType(forString string: String) -> NSNumber? {
        guard let messageType = knownMessageType(forString: string) else {
            return nil
        }
        return NSNumber(value: messageType.rawValue)
    }

    private static func knownMessageType(forString string: String) -> MPMessageTypeSwift? {
        if string == kMPMessageTypeStringUnknownSwift {
            .unknown
        } else if string == "ss" {
            .sessionStart
        } else if string == "se" {
            .sessionEnd
        } else if string == "v" {
            .screenView
        } else if string == "e" {
            .event
        } else if string == "x" {
            .crashReport
        } else if string == "o" {
            .optOut
        } else if string == "fr" {
            .firstRun
        } else if string == "pr" {
            .pushRegistration
        } else if string == "ast" {
            .appStateTransition
        } else if string == "pm" {
            .pushNotification
        } else if string == "npe" {
            .networkPerformance
        } else if string == "bc" {
            .breadcrumb
        } else if string == "pro" {
            .profile
        } else if string == "pre" {
            .pushNotificationInteraction
        } else if string == "cm" {
            .commerceEvent
        } else if string == "uac" {
            .userAttributeChange
        } else if string == "uic" {
            .userIdentityChange
        } else if string == "media" {
            .media
        } else {
            nil
        }
    }

    /// Splits a comma-separated session user-id string into non-zero numbers.
    @objc(filteredUserIdsFrom:)
    public static func filteredUserIds(from sessionUserIds: String) -> [NSNumber] {
        sessionUserIds
            .components(separatedBy: ",")
            .map { NSNumber(value: ($0 as NSString).longLongValue) }
            .filter { $0 != 0 }
    }

    /// Builds the launch-info string mParticle logs when the app cold-starts
    /// from a URL scheme. `launchInfo` is the `NSDictionary` UIKit hands the
    /// app delegate at launch.
    @objc(launchInfoStringFrom:)
    public static func launchInfoString(from launchInfo: [AnyHashable: Any]) -> String? {
        guard let launchURL = launchInfo[UIApplication.LaunchOptionsKey.url] as? URL else {
            return nil
        }
        guard let launchSource = launchInfo[UIApplication.LaunchOptionsKey.sourceApplication] as? String else {
            return nil
        }

        let launchScheme = launchURL.absoluteString
        let sourcePrefix = launchScheme.contains("?") ? "&" : "?"
        return "\(launchScheme)\(sourcePrefix)\(kMPLaunchSourceKeySwift)=\(launchSource)"
    }

    @objc(userAttributeChangeFieldsWithDeleted:key:oldValue:newValue:)
    public static func userAttributeChangeFields(
        deleted: Bool,
        key: String,
        oldValue: Any?,
        newValue: Any?
    ) -> MPUserAttributeChangeFields {
        MPUserAttributeChangeFields(
            deleted: deleted,
            attributeKey: key,
            oldValue: oldValue ?? NSNull(),
            newValue: (newValue != nil && !deleted) ? newValue! : NSNull(),
            newlyAdded: oldValue == nil
        )
    }

    @objc(
        stateTransitionFieldsWithSourceApplication:launchURLString:launchParameters:previousSessionInterruptions:sessionFinalized:
    )
    public static func stateTransitionFields(
        sourceApplication: String?,
        launchURLString: String?,
        launchParameters: Any?,
        previousSessionInterruptions: Int,
        sessionFinalized: Bool
    ) -> MPStateTransitionFields {
        MPStateTransitionFields(
            sourceApplication: sourceApplication,
            launchURLString: launchURLString,
            launchParameters: launchParameters,
            numberOfSessionInterruptions: previousSessionInterruptions,
            sessionFinalized: sessionFinalized
        )
    }
}

/// `kMPMessageTypeStringUnknown` ("unknown", `MPIConstants.m`). Mirrored
/// because the Swift module cannot import the ObjC module.
private let kMPMessageTypeStringUnknownSwift = "unknown"

/// `kMPLaunchSourceKey` (`MPIConstants.m:23`). Mirrored for the same reason.
private let kMPLaunchSourceKeySwift = "src"
