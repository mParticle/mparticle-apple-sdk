//
//  MParticleUserActivityTests.swift
//  mParticle-Apple-SDK
//
//  Created by Nick Dimitrakas on 11/3/25.
//

import XCTest
import ObjectiveC.runtime
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

#if os(iOS)
final class MParticleUserActivityTests: MParticleTestBase {
    
    func test_continueUserActivity_returnsFalse_andDoesNotCallHandler_whenProxiedDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        let activity = NSUserActivity(activityType: "com.example.test")
        
        let result = mparticle.continue(activity) { _ in }

        XCTAssertFalse(result)
        XCTAssertFalse(appNotificationHandler.continueUserActivityCalled)
    }

    func test_continueUserActivity_returnsFalse_whenHandlerReturnsFalse() {
        let activity = NSUserActivity(activityType: "com.example.test")
        appNotificationHandler.continueUserActivityReturnValue = false

        let result = mparticle.continue(activity) { _ in }
        
        XCTAssertTrue(appNotificationHandler.continueUserActivityCalled)
        XCTAssertNotNil(appNotificationHandler.continueUserActivityRestorationHandlerParam)
        XCTAssertEqual(appNotificationHandler.continueUserActivityUserActivityParam, activity)
        XCTAssertFalse(result)
    }
}
#endif
