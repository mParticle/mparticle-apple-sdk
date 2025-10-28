import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MPAppNotificationHandlerMock: MPAppNotificationHandlerProtocol {
    func didUpdate(_ userActivity: NSUserActivity) {
        
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: (any Error)?) {
        
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        
    }
    
    func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any]?) {
        
    }
    
    func handleAction(withIdentifier identifier: String?, forRemoteNotification userInfo: [AnyHashable : Any]?, withResponseInfo responseInfo: [AnyHashable : Any]?) {
        
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
    
    var didReceiveRemoteNotificationCalled = false
    var didReceiveRemoteNotificationParam: [AnyHashable: Any]?

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any]) {
        didReceiveRemoteNotificationCalled = true
        didReceiveRemoteNotificationParam = userInfo
    }

    var didFailToRegisterForRemoteNotificationsCalled = false
    var didFailToRegisterForRemoteNotificationsParam: Error?

    func didFailToRegisterForRemoteNotifications(withError error: Error!) {
        didFailToRegisterForRemoteNotificationsCalled = true
        didFailToRegisterForRemoteNotificationsParam = error
    }
}
