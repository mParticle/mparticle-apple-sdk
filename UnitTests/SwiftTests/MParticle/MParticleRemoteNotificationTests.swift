//
//  MParticleRemoteNotificationTests.swift
//  mParticle-Apple-SDK
//
//  Created by Nick Dimitrakas on 11/3/25.
//

import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

#if os(iOS)
final class MParticleRemoteNotificationTests: MParticleTestBase {
    
    func testDidReceiveRemoteNotification_doesNothing_whenProxiedAppDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        mparticle.didReceiveRemoteNotification([:])

        XCTAssertFalse(appNotificationHandler.didReceiveRemoteNotificationCalled)
        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func testDidReceiveRemoteNotification_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.didReceiveRemoteNotification(keyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didReceiveRemoteNotificationCalled)
    }
    
    
    
    func testDidReceiveRemoteNotification_forwardsToHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.didReceiveRemoteNotification(keyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didReceiveRemoteNotificationCalled)
        XCTAssertEqual(appNotificationHandler.didReceiveRemoteNotificationParam?[keyValueDict.keys.first!] as? String, keyValueDict.values.first)
    }
    
    func testDidFailToRegisterForRemoteNotificationsWithError_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
    }

    func testDidFailToRegisterForRemoteNotificationsWithError_doesNothing_whenProxiedDelegateSet() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
    }
    
    func testDidFailToRegisterForRemoteNotificationsWithError_forwardsToHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
        XCTAssertEqual(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorParam as NSError?, error)
    }

    func testDidRegisterForRemoteNotificationsWithDeviceToken_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
    }

    func testDidRegisterForRemoteNotificationsWithDeviceToken_doesNothing_whenProxiedDelegateExists() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
    }
    
    func testDidRegisterForRemoteNotificationsWithDeviceToken_callsHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
        XCTAssertEqual(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenParam, token)
    }

    func testHandleActionWithIdentifierForRemoteNotification_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
    }

    func testHandleActionWithIdentifierForRemoteNotification_doesNothing_whenProxiedDelegateExists() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
    }
    
    func testHandleActionWithIdentifierForRemoteNotification_callsHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)
        
        XCTAssertTrue(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationIdentifierParam, testName)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationUserInfoParam?[keyValueDict.keys.first!] as? String, keyValueDict.values.first)
    }
    
    func testHandleActionWithIdentifierForRemoteNotificationWithResponseInfo_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict, withResponseInfo: responseKeyValueDict)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
    }

    func testHandleActionWithIdentifierForRemoteNotificationWithResponseInfo_doesNothing_whenProxiedDelegateExists() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict, withResponseInfo: responseKeyValueDict)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
    }
    
    func testHandleActionWithIdentifierForRemoteNotificationWithResponseInfo_callsHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict, withResponseInfo: responseKeyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam, testName)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam?[keyValueDict.keys.first!] as? String, keyValueDict.values.first)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam?[responseKeyValueDict.keys.first!] as? String, responseKeyValueDict.values.first)
    }
}
#endif

