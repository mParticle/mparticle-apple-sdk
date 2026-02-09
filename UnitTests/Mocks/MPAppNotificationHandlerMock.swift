import XCTest
import mParticle_Apple_SDK

class MPAppNotificationHandlerMock: MPAppNotificationHandlerProtocol {
    
#if os(iOS)
    var didReceiveRemoteNotificationCalled = false
    var didReceiveRemoteNotificationParam: [AnyHashable: Any]?

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        didReceiveRemoteNotificationCalled = true
        didReceiveRemoteNotificationParam = userInfo
    }
    
    var didFailToRegisterForRemoteNotificationsWithErrorCalled = false
    var didFailToRegisterForRemoteNotificationsWithErrorParam: Error?
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: (any Error)?) {
        didFailToRegisterForRemoteNotificationsWithErrorCalled = true
        didFailToRegisterForRemoteNotificationsWithErrorParam = error
    }
    
    var didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled = false
    var didFailToRegisterForRemoteNotificationsWithDeviceTokenParam: Data?
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled = true
        didFailToRegisterForRemoteNotificationsWithDeviceTokenParam = deviceToken
    }
    
    var handleActionWithIdentifierForRemoteNotificationCalled = false
    var handleActionWithIdentifierForRemoteNotificationIdentifierParam: String?
    var handleActionWithIdentifierForRemoteNotificationUserInfoParam: [AnyHashable: Any]?
    
    func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable: Any]?) {
        handleActionWithIdentifierForRemoteNotificationCalled = true
        handleActionWithIdentifierForRemoteNotificationIdentifierParam = identifier
        handleActionWithIdentifierForRemoteNotificationUserInfoParam = userInfo
    }
    
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled = false
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam: String?
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam: [AnyHashable: Any]?
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam: [AnyHashable: Any]?
    
    func handleAction(
        withIdentifier identifier: String?,
        forRemoteNotification userInfo: [AnyHashable: Any]?,
        withResponseInfo responseInfo: [AnyHashable: Any]?
    ) {
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled = true
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam = identifier
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam = userInfo
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam = responseInfo
    }
    
    func didUpdate(_ userActivity: NSUserActivity) {
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) {
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) {
        
    }
    
#endif
    
    var openURLWithSourceApplicationAndAnnotationCalled = false
    var openURLWithSourceApplicationAndAnnotationURLParam: URL?
    var openURLWithSourceApplicationAndAnnotationSourceApplicationParam: String?
    var openURLWithSourceApplicationAndAnnotationAnnotationParam: Any?
    
    func open(_ url: URL, sourceApplication: String?, annotation: Any?) {
        openURLWithSourceApplicationAndAnnotationCalled = true
        openURLWithSourceApplicationAndAnnotationURLParam = url
        openURLWithSourceApplicationAndAnnotationSourceApplicationParam = sourceApplication
        openURLWithSourceApplicationAndAnnotationAnnotationParam = annotation
    }
    
    var openURLWithOptionsCalled = false
    var openURLWithOptionsURLParam: URL?
    var openURLWithOptionsOptionsParam: [String: Any]?
    
    func open(_ url: URL, options: [String: Any]?) {
        openURLWithOptionsCalled = true
        openURLWithOptionsURLParam = url
        openURLWithOptionsOptionsParam = options
    }
    
    var continueUserActivityCalled = false
    var continueUserActivityUserActivityParam: NSUserActivity?
    var continueUserActivityRestorationHandlerParam: (([UIUserActivityRestoring]?) -> Void)?
    var continueUserActivityReturnValue: Bool = false
    
    func `continue`(_ userActivity: NSUserActivity,
                    restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        continueUserActivityCalled = true
        continueUserActivityUserActivityParam = userActivity
        continueUserActivityRestorationHandlerParam = restorationHandler
        return continueUserActivityReturnValue
    }
}
