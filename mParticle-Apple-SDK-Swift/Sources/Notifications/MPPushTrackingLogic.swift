import Foundation

/// Which notification event, if any, the SDK logs for an incoming push.
@objc(MPPushTrackingAction) public enum PushTrackingAction: Int {
    case none
    case logReceived
    case logOpened
}

/// The decisions MPAppNotificationHandler makes before forwarding a push to kits.
///
/// Everything here operates on Foundation values. The caller resolves UIKit and
/// UserNotifications state — application state, action identifiers — into plain
/// booleans and strings, so this type never sees an SDK or UIKit type.
@objc(MPPushTrackingLogic) public final class PushTrackingLogic: NSObject {
    /// Mirrors `hasContentAvail:`. The ObjC original read the value into an `NSString *`
    /// but compared it with `isEqual:@1`, so it matches the number 1 rather than a string.
    /// Typing the local as `Any?` keeps that behaviour rather than quietly tightening it.
    @objc(hasContentAvailable:) public static func hasContentAvailable(_ userInfo: [AnyHashable: Any]?) -> Bool {
        guard let aps = userInfo?["aps"] as? [AnyHashable: Any] else {
            return false
        }
        let contentAvailable = aps["content-available"]
        return (contentAvailable as? NSObject)?.isEqual(1) ?? false
    }

    /// Mirrors `is9`, which tested `[systemVersion floatValue] < 10.0`. `floatValue`
    /// parses a leading number and yields 0 for anything unparseable, which `Float(_:)`
    /// would instead turn into nil — so the parse is done the lenient way on purpose.
    @objc(isPreIOS10WithSystemVersion:) public static func isPreIOS10(systemVersion: String) -> Bool {
        return leadingFloat(systemVersion) < 10.0
    }

    /// `didReceiveRemoteNotification:`. Before iOS 10 the SDK inferred "opened" from the
    /// app not being active; from iOS 10 onward only silent pushes are logged here,
    /// because the UNUserNotificationCenter callbacks cover the rest.
    @objc(remoteNotificationActionWithTrackNotifications:isPreIOS10:applicationIsActive:userInfo:)
    public static func remoteNotificationAction(trackNotifications: Bool,
                                                isPreIOS10: Bool,
                                                applicationIsActive: Bool,
                                                userInfo: [AnyHashable: Any]?) -> PushTrackingAction {
        guard trackNotifications else {
            return .none
        }

        let contentAvailable = hasContentAvailable(userInfo)

        if isPreIOS10 {
            return (!applicationIsActive || !contentAvailable) ? .logOpened : .logReceived
        }

        return contentAvailable ? .logReceived : .none
    }

    /// `userNotificationCenter:willPresentNotification:`. A silent push is skipped here
    /// because `didReceiveRemoteNotification:` has already logged it.
    @objc(willPresentActionWithTrackNotifications:userInfo:)
    public static func willPresentAction(trackNotifications: Bool,
                                         userInfo: [AnyHashable: Any]?) -> PushTrackingAction {
        guard trackNotifications, !hasContentAvailable(userInfo) else {
            return .none
        }
        return .logReceived
    }

    /// `userNotificationCenter:didReceiveNotificationResponse:`. Dismissing a notification
    /// is not opening it, so the dismiss action identifier logs nothing.
    @objc(notificationResponseActionWithTrackNotifications:actionIdentifier:dismissActionIdentifier:)
    public static func notificationResponseAction(trackNotifications: Bool,
                                                  actionIdentifier: String?,
                                                  dismissActionIdentifier: String?) -> PushTrackingAction {
        guard trackNotifications else {
            return .none
        }
        if let actionIdentifier = actionIdentifier,
           actionIdentifier == dismissActionIdentifier {
            return .none
        }
        return .logOpened
    }

    private static func leadingFloat(_ string: String) -> Float {
        let scanner = Scanner(string: string)
        scanner.charactersToBeSkipped = CharacterSet.whitespaces
        return scanner.scanFloat() ?? 0
    }
}
