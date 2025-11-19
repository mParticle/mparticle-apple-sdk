
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif
import XCTest

final class MParticleSceneDelegateTests: MParticleTestBase {
    
    // MARK: - Properties
    
    var testURL: URL!
    var testUserActivity: NSUserActivity!
    
    override func setUp() {
        super.setUp()
        testURL = URL(string: "myapp://test/path?param=value")!
        testUserActivity = NSUserActivity(activityType: "com.test.activity")
        testUserActivity.title = "Test Activity"
        testUserActivity.userInfo = ["key": "value"]
        
        // The implementation calls [MParticle sharedInstance], so we need to set the mock on the shared instance
        MParticle.sharedInstance().appNotificationHandler = appNotificationHandler
        
        // Reset mock state for each test
        appNotificationHandler.continueUserActivityCalled = false
        appNotificationHandler.continueUserActivityUserActivityParam = nil
        appNotificationHandler.continueUserActivityRestorationHandlerParam = nil
        appNotificationHandler.openURLWithOptionsCalled = false
        appNotificationHandler.openURLWithOptionsURLParam = nil
        appNotificationHandler.openURLWithOptionsOptionsParam = nil
    }
        
    // MARK: - handleUserActivity Tests
    
    func test_handleUserActivity_invokesAppNotificationHandler() {
        // Act
        mparticle.handleUserActivity(testUserActivity)
        
        // Assert - handleUserActivity directly calls the app notification handler
        XCTAssertTrue(appNotificationHandler.continueUserActivityCalled)
        XCTAssertEqual(appNotificationHandler.continueUserActivityUserActivityParam, testUserActivity)
        XCTAssertNotNil(appNotificationHandler.continueUserActivityRestorationHandlerParam)
    }
    
    func test_handleUserActivity_withWebBrowsingActivity() {
        // Arrange
        let webActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        webActivity.title = "Web Page"
        webActivity.webpageURL = URL(string: "https://example.com/page")
        
        // Act
        mparticle.handleUserActivity(webActivity)
        
        // Assert - Direct call to app notification handler
        XCTAssertTrue(appNotificationHandler.continueUserActivityCalled)
        XCTAssertEqual(appNotificationHandler.continueUserActivityUserActivityParam, webActivity)
    }
    
    func test_handleUserActivity_restorationHandlerIsEmpty() {
        // Act
        mparticle.handleUserActivity(testUserActivity)
        
        // Assert
        XCTAssertTrue(appNotificationHandler.continueUserActivityCalled)
        
        // Verify the restoration handler is provided and safe to call
        let restorationHandler = appNotificationHandler.continueUserActivityRestorationHandlerParam
        XCTAssertNotNil(restorationHandler)
        
        // Test that calling the restoration handler doesn't crash
        XCTAssertNoThrow(restorationHandler?(nil))
        XCTAssertNoThrow(restorationHandler?([]))
    }
}
