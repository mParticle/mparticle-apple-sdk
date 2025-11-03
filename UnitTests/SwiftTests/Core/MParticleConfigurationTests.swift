//
//  MParticleConfigurationTests.swift
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

final class MParticleConfigurationTests: MParticleTestBase {
    
    func testStartWithKeyCallbackFirstRun() {
        XCTAssertFalse(mparticle.initialized)
        
        mparticle.start(withKeyCallback: true, options: options, userDefaults: userDefaults)
        
        XCTAssertTrue(mparticle.initialized)
        XCTAssertNil(mparticle.settingsProvider.configSettings)
        
        XCTAssertNotNil(userDefaults.setMPObjectValueParam)
        XCTAssertEqual(userDefaults.setMPObjectKeyParam, "firstrun")
        XCTAssertEqual(userDefaults.setMPObjectUserIdParam, 0)
        XCTAssertTrue(userDefaults.synchronizeCalled)
    }
    
    func testStartWithKeyCallbackNotFirstRunWithIdentityRequest() {
        let user = mparticle.identity.currentUser
        options.identifyRequest = MPIdentityApiRequest(user: user!)
        
        mparticle.start(withKeyCallback: false, options: options, userDefaults: userDefaults as MPUserDefaultsProtocol)
        
        XCTAssertTrue(mparticle.initialized)
        XCTAssertNil(mparticle.settingsProvider.configSettings)
        
        XCTAssertFalse(userDefaults.setMPObjectCalled)
        XCTAssertFalse(userDefaults.synchronizeCalled)
    }
    
    func testConfigureDefaultConfigurationExistOptionParametersAreNotSet() {
        mparticle.backendController = MPBackendController_PRIVATE()
        mparticle.configure(with: options)
        XCTAssertEqual(mparticle.backendController.sessionTimeout, 0.0)
        XCTAssertEqual(mparticle.backendController.uploadInterval, 60.0)
        XCTAssertEqual(mparticle.customUserAgent, nil)
        XCTAssertEqual(mparticle.collectUserAgent, true)
        XCTAssertEqual(mparticle.trackNotifications, true)
    }
    
    func testConfigureWhenDefaultConfigurationExists() {
        let settings: NSMutableDictionary = [
            "session_timeout": NSNumber(value: 2.0),
            "upload_interval": NSNumber(value: 3.0),
            "custom_user_agent": "custom_user_agent",
            "collect_user_agent": false,
            "track_notifications": false,
            "enable_location_tracking": true,
            "location_tracking_accuracy": 100.0,
            "location_tracking_distance_filter": 10.0,
        ]
        settingsProvider.configSettings = settings
        mparticle.settingsProvider = settingsProvider
        mparticle.backendController = MPBackendController_PRIVATE()
        mparticle.configure(with: options)
        
        XCTAssertEqual(mparticle.backendController.sessionTimeout, 2.0)
        XCTAssertEqual(mparticle.backendController.uploadInterval, 3.0)
        XCTAssertEqual(mparticle.customUserAgent, "custom_user_agent")
        XCTAssertEqual(mparticle.collectUserAgent, false)
        XCTAssertEqual(mparticle.trackNotifications, false)
    }
    
    func testConfigureWithOptionsNoSettings() {
        mparticle.configure(with: .init())
        XCTAssertEqual(backendController.sessionTimeout, 0.0)
        XCTAssertEqual(backendController.uploadInterval, 0.0)
        XCTAssertNil(mparticle.customUserAgent)
        XCTAssertTrue(mparticle.collectUserAgent)
        XCTAssertTrue(mparticle.trackNotifications)
#if os(iOS)
#if !MPARTICLE_LOCATION_DISABLE
        XCTAssertNil(listenerController.onAPICalledApiName)
#endif
#endif
    }
    
    func testConfigureWithOptionsWithSettingsAndOptionNotSet() {
        settingsProvider.configSettings = [
            "session_timeout": 100,
            "upload_interval": 50,
            "custom_user_agent": "agent",
            "collect_user_agent": false,
            "track_notifications": false,
            "enable_location_tracking": true,
        ]
        options.isSessionTimeoutSet = false
        options.isUploadIntervalSet = false
        options.isCollectUserAgentSet = false
        options.isCollectUserAgentSet = false
        options.isTrackNotificationsSet = false
        mparticle.configure(with: .init())
        XCTAssertEqual(backendController.sessionTimeout, 100.0)
        XCTAssertEqual(backendController.uploadInterval, 50.0)
        XCTAssertEqual(mparticle.customUserAgent, "agent")
        XCTAssertFalse(mparticle.collectUserAgent)
        XCTAssertFalse(mparticle.trackNotifications)
        
#if os(iOS)
#if !MPARTICLE_LOCATION_DISABLE
        XCTAssertEqual(listenerController.onAPICalledApiName?.description,
                       "beginLocationTracking:minDistance:authorizationRequest:")
#endif
#endif
    }
    
    func testResetForSwitchingWorkspaces() {
        let expectation = XCTestExpectation()
        
        mparticle.reset {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(kitContainer.flushSerializedKitsCalled)
        XCTAssertTrue(kitContainer.removeAllSideloadedKitsCalled)
        XCTAssertEqual(persistenceController.resetDatabaseCalled, true)
        XCTAssertTrue(backendController.unproxyOriginalAppDelegateCalled)
    }
}
