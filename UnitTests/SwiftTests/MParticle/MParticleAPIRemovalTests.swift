import XCTest
@testable import mParticle_Apple_SDK_NoLocation

/// Tests to verify that deprecated/removed APIs are no longer accessible in SDK 9.0
final class MParticleAPIRemovalTests: XCTestCase {

    // MARK: - AppDelegateProxy Removal Tests

    func test_MParticleOptions_proxyAppDelegate_propertyRemoved() {
        let options = MParticleOptions(key: "test", secret: "test")
        XCTAssertFalse(
            options.responds(to: NSSelectorFromString("proxyAppDelegate")),
            "proxyAppDelegate getter should be removed in 9.0"
        )
        XCTAssertFalse(
            options.responds(to: NSSelectorFromString("setProxyAppDelegate:")),
            "proxyAppDelegate setter should be removed in 9.0"
        )
    }

    func test_MParticle_proxiedAppDelegate_propertyRemoved() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("proxiedAppDelegate")),
            "proxiedAppDelegate should be removed in 9.0"
        )
    }

    func test_MPAppDelegateProxy_classRemoved() {
        let proxyClass: AnyClass? = NSClassFromString("MPAppDelegateProxy")
        XCTAssertNil(proxyClass, "MPAppDelegateProxy class should be removed in 9.0")
    }

    func test_MPSurrogateAppDelegate_classRemoved() {
        let surrogateClass: AnyClass? = NSClassFromString("MPSurrogateAppDelegate")
        XCTAssertNil(surrogateClass, "MPSurrogateAppDelegate class should be removed in 9.0")
    }

    // MARK: - Push Notification Forwarding Methods Exist (iOS only)

    #if os(iOS)
    func test_didRegisterForRemoteNotifications_methodExists() {
        let mp = MParticle.sharedInstance()
        XCTAssertTrue(
            mp.responds(to: NSSelectorFromString("didRegisterForRemoteNotificationsWithDeviceToken:")),
            "didRegisterForRemoteNotificationsWithDeviceToken: should exist for manual forwarding"
        )
    }

    func test_didFailToRegisterForRemoteNotifications_methodExists() {
        let mp = MParticle.sharedInstance()
        XCTAssertTrue(
            mp.responds(to: NSSelectorFromString("didFailToRegisterForRemoteNotificationsWithError:")),
            "didFailToRegisterForRemoteNotificationsWithError: should exist for manual forwarding"
        )
    }

    func test_didReceiveRemoteNotification_methodExists() {
        let mp = MParticle.sharedInstance()
        XCTAssertTrue(
            mp.responds(to: NSSelectorFromString("didReceiveRemoteNotification:")),
            "didReceiveRemoteNotification: should exist for manual forwarding"
        )
    }
    #endif

    // MARK: - Location Tracking Removal Tests

    func test_beginLocationTracking_minDistance_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("beginLocationTracking:minDistance:")),
            "beginLocationTracking:minDistance: should be removed in 9.0"
        )
    }

    func test_beginLocationTracking_minDistance_authorizationRequest_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("beginLocationTracking:minDistance:authorizationRequest:")),
            "beginLocationTracking:minDistance:authorizationRequest: should be removed in 9.0"
        )
    }

    func test_endLocationTracking_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("endLocationTracking")),
            "endLocationTracking should be removed in 9.0"
        )
    }

    func test_location_property_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("location")),
            "location getter should be removed in 9.0"
        )
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("setLocation:")),
            "location setter should be removed in 9.0"
        )
    }

    func test_backgroundLocationTracking_property_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("backgroundLocationTracking")),
            "backgroundLocationTracking should be removed in 9.0"
        )
    }

    func test_MPLocationManager_classRemoved() {
        let locationManagerClass: AnyClass? = NSClassFromString("MPLocationManager")
        XCTAssertNil(locationManagerClass, "MPLocationManager class should be removed in 9.0")
    }

    // MARK: - MPListenerController Removal Tests

    func test_MPListenerController_classRemoved() {
        let listenerControllerClass: AnyClass? = NSClassFromString("MPListenerController")
        XCTAssertNil(listenerControllerClass, "MPListenerController class should be removed in 9.0")
    }

    // MARK: - URL/User Activity Method Removal Tests

    func test_openURL_sourceApplication_annotation_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("openURL:sourceApplication:annotation:")),
            "openURL:sourceApplication:annotation: should be removed in 9.0"
        )
    }

    func test_openURL_options_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("openURL:options:")),
            "openURL:options: should be removed in 9.0"
        )
    }

    func test_continueUserActivity_restorationHandler_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("continueUserActivity:restorationHandler:")),
            "continueUserActivity:restorationHandler: should be removed in 9.0"
        )
    }

    // MARK: - New URL/User Activity Methods Exist

    #if os(iOS)
    @available(iOS 13.0, *)
    func test_handleURLContext_methodExists() {
        let mp = MParticle.sharedInstance()
        XCTAssertTrue(
            mp.responds(to: NSSelectorFromString("handleURLContext:")),
            "handleURLContext: should exist in 9.0"
        )
    }
    #endif

    func test_handleUserActivity_methodExists() {
        let mp = MParticle.sharedInstance()
        XCTAssertTrue(
            mp.responds(to: NSSelectorFromString("handleUserActivity:")),
            "handleUserActivity: should exist in 9.0"
        )
    }

    // MARK: - MParticle Deprecated Property Removal

    func test_MParticle_consoleLogging_removed() {
        let mp = MParticle.sharedInstance()
        XCTAssertFalse(
            mp.responds(to: NSSelectorFromString("consoleLogging")),
            "consoleLogging should be removed - use logLevel on MParticleOptions"
        )
    }
}
