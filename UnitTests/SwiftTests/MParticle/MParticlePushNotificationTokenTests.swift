import XCTest
import mParticle_Apple_SDK

#if os(iOS)
final class MParticlePushNotificationTokenTests: MParticleTestBase {
    
    func test_pushNotificationToken_returnsDeviceToken_whenNotAppExtension() {
        notificationController.deviceTokenReturnValue = token
        
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        let token = mparticle.pushNotificationToken
        
        XCTAssertEqual(token, self.token)
        XCTAssertTrue(notificationController.deviceTokenCalled)
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func test_pushNotificationToken_returnsNil_whenAppExtension() {
        notificationController.deviceTokenReturnValue = token

        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        let token = mparticle.pushNotificationToken
        
        XCTAssertNil(token)
        XCTAssertFalse(notificationController.deviceTokenCalled)
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func test_setPushNotificationToken_updatesController_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.pushNotificationToken = token
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(notificationController.setDeviceTokenCalled)
        XCTAssertEqual(notificationController.setDeviceTokenParam, token)
    }
    
    func test_setPushNotificationToken_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.pushNotificationToken = token
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(notificationController.setDeviceTokenCalled)
    }
}
#endif
