import XCTest
import ObjectiveC.runtime
import mParticle_Apple_SDK_NoLocation

#if os(iOS)
final class MParticleUserActivityTests: MParticleTestBase {

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
