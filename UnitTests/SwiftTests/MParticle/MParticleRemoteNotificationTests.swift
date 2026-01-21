import XCTest
import mParticle_Apple_SDK_NoLocation

#if os(iOS)
final class MParticleRemoteNotificationTests: MParticleTestBase {
    
    func test_didReceiveRemoteNotification_doesNotCallHandler_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.didReceiveRemoteNotification(keyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didReceiveRemoteNotificationCalled)
    }
    
    func test_didReceiveRemoteNotification_callsHandler_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.didReceiveRemoteNotification(keyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didReceiveRemoteNotificationCalled)
        XCTAssertEqual(
            appNotificationHandler.didReceiveRemoteNotificationParam?[keyValueDict.keys.first!] as? String,
            keyValueDict.values.first
        )
    }
    
    func test_didFailToRegisterForRemoteNotifications_doesNotCallHandler_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
    }
    
    func test_didFailToRegisterForRemoteNotifications_callsHandler_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
        XCTAssertEqual(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorParam as NSError?, error)
    }

    func test_didRegisterForRemoteNotifications_doesNotCallHandler_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
    }
    
    func test_didRegisterForRemoteNotifications_callsHandler_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
        XCTAssertEqual(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenParam, token)
    }

    func test_handleActionForRemoteNotification_doesNotCallHandler_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
    }
    
    func test_handleActionForRemoteNotification_callsHandler_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)
        
        XCTAssertTrue(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationIdentifierParam, testName)
        XCTAssertEqual(
            appNotificationHandler
                .handleActionWithIdentifierForRemoteNotificationUserInfoParam?[keyValueDict.keys.first!] as? String,
            keyValueDict.values.first
        )
    }
    
    func test_handleActionForRemoteNotificationWithResponseInfo_doesNotCallHandler_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.handleAction(
            withIdentifier: testName,
            forRemoteNotification: keyValueDict,
            withResponseInfo: responseKeyValueDict
        )

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
    }
    
    func test_handleActionForRemoteNotificationWithResponseInfo_callsHandler_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.handleAction(
            withIdentifier: testName,
            forRemoteNotification: keyValueDict,
            withResponseInfo: responseKeyValueDict
        )
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
        XCTAssertEqual(
            appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam,
            testName
        )
        XCTAssertEqual(
            appNotificationHandler
                .handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam?[keyValueDict.keys
                .first!] as? String,
            keyValueDict.values.first
        )
        XCTAssertEqual(
            appNotificationHandler
                .handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam?[responseKeyValueDict.keys
                .first!] as? String,
            responseKeyValueDict.values.first
        )
    }
}
#endif
