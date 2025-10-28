import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MPAppNotificationHandlerMock: MPAppNotificationHandlerProtocol {
    func didUpdate(_ userActivity: NSUserActivity) {
        
    }
    
    var didReceiveRemoteNotificationCalled = false
    var didReceiveRemoteNotificationParam: [AnyHashable: Any]?

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any]) {
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
    var handleActionWithIdentifierForRemoteNotificationUserInfoParam: [AnyHashable : Any]?
    
    func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any]?) {
        handleActionWithIdentifierForRemoteNotificationCalled = true
        handleActionWithIdentifierForRemoteNotificationIdentifierParam = identifier
        handleActionWithIdentifierForRemoteNotificationUserInfoParam = userInfo
    }
    
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled = false
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam: String?
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam: [AnyHashable : Any]?
    var handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam: [AnyHashable : Any]?
    
    func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any]?, withResponseInfo responseInfo: [AnyHashable : Any]?) {
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled = true
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam = identifier
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam = userInfo
        handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam = responseInfo
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) {
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) {
        
    }
    
    func `continue`(_ userActivity: NSUserActivity, restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        return false
    }
    
    func open(_ url: URL, options: [String : Any]? = nil) {
        
    }
    
    func open(_ url: URL, sourceApplication: String?, annotation: Any?) {
        
    }
}
