import Foundation
import UIKit
#if os(iOS)
import UserNotifications
#endif

/// The app-delegate and notification-center callbacks `MParticle` hands to its notification handler.
///
/// The Objective-C name, selectors and iOS-only members are the ones the deleted Objective-C protocol
/// declared. The device token and the remote-notification dictionary are nullable here where that
/// protocol said nonnull: Swift turns a nil passed for a nonnull value into an empty one, and the
/// handler treats nil differently from empty.
@objc(MPAppNotificationHandlerProtocol)
public protocol MPAppNotificationHandlerProtocol {
    #if os(iOS)
    @objc(didFailToRegisterForRemoteNotificationsWithError:)
    func didFailToRegisterForRemoteNotificationsWithError(_ error: Error?)

    @objc(didRegisterForRemoteNotificationsWithDeviceToken:)
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data?)

    @objc(handleActionWithIdentifier:forRemoteNotification:)
    func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any]?)

    @objc(handleActionWithIdentifier:forRemoteNotification:withResponseInfo:)
    func handleAction(
        withIdentifier identifier: String?,
        forRemoteNotification userInfo: [AnyHashable: Any]?,
        withResponseInfo responseInfo: [AnyHashable: Any]?
    )

    @objc(didReceiveRemoteNotification:)
    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]?)

    @objc(userNotificationCenter:willPresentNotification:)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification)

    @objc(userNotificationCenter:didReceiveNotificationResponse:)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse)
    #endif

    @objc(continueUserActivity:restorationHandler:)
    func `continue`(
        _ userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool

    @objc(openURL:options:)
    func open(_ url: URL, options: [String: Any]?)
}

/// The SDK as the notification handler sees it: `MParticle`, its kit container and its state
/// machine, which this module cannot import.
///
/// The Objective-C module supplies the conformance and reads `MParticle.sharedInstance` on every
/// call, so each callback sees the SDK as it is then, and a test's stubs on those reads apply.
@objc(MPAppNotificationHost)
public protocol MPAppNotificationHost: NSObjectProtocol {
    @objc(optOut) func optOut() -> Bool
    /// A logger at the SDK's current log level, with its custom logger.
    @objc var logger: MPLog { get }
    @objc(setLaunchInfo:) func setLaunchInfo(_ launchInfo: MPLaunchInfo)
    /// Forwards to the kit container's forwardSDKCall:event:parameters:messageType:userInfo: with no event.
    @objc(forwardSDKCall:parameters:messageType:userInfo:)
    func forwardSDKCall(
        _ selector: Selector,
        parameters: MPForwardQueueParameters,
        messageType: MPMessageTypeSwift,
        userInfo: [AnyHashable: Any]?
    )
    /// Whether the wrapper instance of any registered kit responds to `selector`.
    @objc(registeredKitRespondsToSelector:) func registeredKitResponds(to selector: Selector) -> Bool

    #if os(iOS)
    @objc(isAppExtension) func isAppExtension() -> Bool
    @objc(trackNotifications) func trackNotifications() -> Bool
    @objc(notificationController) func notificationController() -> MPNotificationControllerProtocol
    @objc(logNotificationReceivedWithUserInfo:) func logNotificationReceived(userInfo: [AnyHashable: Any])
    @objc(logNotificationOpenedWithUserInfo:andActionIdentifier:)
    func logNotificationOpened(userInfo: [AnyHashable: Any], actionIdentifier: String?)
    /// Calls each active kit that implements the notification-center callback, saving a forward record
    /// for each kit that succeeds. Kits can raise, and only Objective-C can contain that.
    @objc(forwardUserNotificationCenter:willPresentNotification:)
    func forwardUserNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification)
    @objc(forwardUserNotificationCenter:didReceiveNotificationResponse:)
    func forwardUserNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse)
    #endif
}

/// Applies the push-tracking decisions in `PushTrackingLogic` and forwards app-delegate and
/// notification-center callbacks to kits on the main queue.
@objc(MPAppNotificationHandler)
public final class MPAppNotificationHandler: NSObject, MPAppNotificationHandlerProtocol, OpenURLHandlerProtocolPRIVATE {
    /// The MPKitProtocol selectors forwarded to kits, spelled out because this module cannot import
    /// that protocol.
    private enum KitSelector {
        static let failedToRegister = NSSelectorFromString("failedToRegisterForUserNotifications:")
        static let setDeviceToken = NSSelectorFromString("setDeviceToken:")
        static let handleAction = NSSelectorFromString("handleActionWithIdentifier:forRemoteNotification:")
        static let handleActionWithResponseInfo =
            NSSelectorFromString("handleActionWithIdentifier:forRemoteNotification:withResponseInfo:")
        static let receivedUserNotification = NSSelectorFromString("receivedUserNotification:")
        static let continueUserActivity = NSSelectorFromString("continueUserActivity:restorationHandler:")
        static let openURL = NSSelectorFromString("openURL:options:")
    }

    private let host: MPAppNotificationHost

    @objc(initWithHost:)
    public init(host: MPAppNotificationHost) {
        self.host = host
        super.init()
    }

    #if os(iOS)
    public func didFailToRegisterForRemoteNotificationsWithError(_ error: Error?) {
        guard !host.optOut() else { return }

        if !host.isAppExtension() {
            host.notificationController().setDeviceToken(nil)
        }

        forwardOnMain(KitSelector.failedToRegister, [error], messageType: .unknown)
    }

    public func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data?) {
        guard !host.optOut() else { return }

        if !host.isAppExtension() {
            host.notificationController().setDeviceToken(deviceToken)
        }

        forwardOnMain(KitSelector.setDeviceToken, [deviceToken], messageType: .pushRegistration, userInfo: ["state": 1])
    }

    public func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any]?) {
        guard !host.optOut() else { return }

        forwardOnMain(KitSelector.handleAction, [identifier, userInfo], messageType: .unknown)
    }

    public func handleAction(
        withIdentifier identifier: String?,
        forRemoteNotification userInfo: [AnyHashable: Any]?,
        withResponseInfo responseInfo: [AnyHashable: Any]?
    ) {
        guard !host.optOut() else { return }

        forwardOnMain(KitSelector.handleActionWithResponseInfo, [identifier, userInfo, responseInfo], messageType: .unknown)
    }

    public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]?) {
        guard !host.optOut(), let userInfo else { return }

        // The && short-circuits keep the original call order: neither the system version nor the
        // application is read while notification tracking is off.
        let trackNotifications = host.trackNotifications()
        let isPreIOS10 = trackNotifications && PushTrackingLogic.isPreIOS10(systemVersion: UIDevice.current.systemVersion)
        // Messaging a nil application returned 0, which is UIApplicationStateActive.
        let applicationIsActive = isPreIOS10
            && (MPApplication_PRIVATE.sharedUIApplication()?.applicationState ?? .active) == .active

        let action = PushTrackingLogic.remoteNotificationAction(
            trackNotifications: trackNotifications,
            isPreIOS10: isPreIOS10,
            applicationIsActive: applicationIsActive,
            userInfo: userInfo
        )
        apply(action, userInfo: userInfo, actionIdentifier: nil)

        forwardOnMain(KitSelector.receivedUserNotification, [userInfo], messageType: .pushNotification, userInfo: userInfo)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) {
        guard !host.optOut() else { return }

        let userInfo = notification.request.content.userInfo
        let action = PushTrackingLogic.willPresentAction(trackNotifications: host.trackNotifications(), userInfo: userInfo)
        apply(action, userInfo: userInfo, actionIdentifier: nil)

        DispatchQueue.main.async { [host] in
            host.forwardUserNotificationCenter(center, willPresent: notification)
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) {
        guard !host.optOut() else { return }

        let userInfo = response.notification.request.content.userInfo
        let action = PushTrackingLogic.notificationResponseAction(
            trackNotifications: host.trackNotifications(),
            actionIdentifier: response.actionIdentifier,
            dismissActionIdentifier: UNNotificationDismissActionIdentifier
        )
        apply(action, userInfo: userInfo, actionIdentifier: response.actionIdentifier)

        DispatchQueue.main.async { [host] in
            host.forwardUserNotificationCenter(center, didReceive: response)
        }
    }

    private func apply(_ action: PushTrackingAction, userInfo: [AnyHashable: Any], actionIdentifier: String?) {
        switch action {
        case .logOpened:
            host.logNotificationOpened(userInfo: userInfo, actionIdentifier: actionIdentifier)
        case .logReceived:
            host.logNotificationReceived(userInfo: userInfo)
        case .none:
            break
        }
    }
    #endif

    public func `continue`(
        _ userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard !host.optOut() else { return false }

        let logger = host.logger
        // URL(string: "") is nil, where the Objective-C original's empty NSURL was not.
        if let url = userActivity.webpageURL ?? (NSURL(string: "") as URL?) {
            host.setLaunchInfo(MPLaunchInfo(URL: url, options: nil, logger: logger))
        }

        // A plain Swift closure would reach the kits as a boxed Swift value rather than a block.
        let block: @convention(block) ([UIUserActivityRestoring]?) -> Void = restorationHandler
        forwardOnMain(KitSelector.continueUserActivity, [userActivity, block], messageType: .unknown)

        return host.registeredKitResponds(to: KitSelector.continueUserActivity)
    }

    public func open(_ url: URL, options: [String: Any]?) {
        guard !host.optOut() else { return }

        host.setLaunchInfo(MPLaunchInfo(URL: url, options: options, logger: host.logger))

        forwardOnMain(KitSelector.openURL, [url, options], messageType: .unknown)
    }

    /// Builds the queue parameters on the calling thread, a nil becoming NSNull, and forwards them from
    /// the main queue.
    private func forwardOnMain(
        _ selector: Selector,
        _ parameters: [Any?],
        messageType: MPMessageTypeSwift,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        let queueParameters = MPForwardQueueParameters()
        parameters.forEach(queueParameters.addParameter)

        DispatchQueue.main.async { [host] in
            host.forwardSDKCall(selector, parameters: queueParameters, messageType: messageType, userInfo: userInfo)
        }
    }
}
