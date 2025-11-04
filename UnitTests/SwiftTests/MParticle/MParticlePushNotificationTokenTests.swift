//
//  MParticlePushNotificationTokenTests.swift
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
final class MParticlePushNotificationTokenTests: MParticleTestBase {
    
    func testPushNotificationToken_returnsDeviceToken_whenNotAppExtension() {
        notificationController.deviceTokenReturnValue = token
        
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        let token = mparticle.pushNotificationToken
        
        XCTAssertEqual(token, self.token)
        XCTAssertTrue(notificationController.deviceTokenCalled)
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func testPushNotificationToken_returnsNil_whenAppExtension() {
        notificationController.deviceTokenReturnValue = token

        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        let token = mparticle.pushNotificationToken
        
        XCTAssertNil(token)
        XCTAssertFalse(notificationController.deviceTokenCalled)
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func testSetPushNotificationToken_setsToken_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.pushNotificationToken = token
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(notificationController.setDeviceTokenCalled)
        XCTAssertEqual(notificationController.setDeviceTokenParam, token)
    }
    
    func testSetPushNotificationToken_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.pushNotificationToken = token
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(notificationController.setDeviceTokenCalled)
    }
}
#endif
