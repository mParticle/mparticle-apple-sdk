import XCTest
@testable import mParticle_Apple_SDK_NoLocation
import mParticle_Apple_SDK_Swift

final class MParticleSceneDelegateTests: XCTestCase {
    
    // MARK: - Properties

    var mparticle: MParticle!
    var sceneMock: OpenURLHandlerProtocolMock!
    var testURL: URL!
    var testUserActivity: NSUserActivity!
    
    override func setUp() {
        super.setUp()
        mparticle = MParticle()
        testURL = URL(string: "myapp://test/path?param=value")!
        testUserActivity = NSUserActivity(activityType: "com.test.activity")
        testUserActivity.title = "Test Activity"
        testUserActivity.userInfo = ["key": "value"]
        
        // The implementation calls [MParticle sharedInstance], so we need to set the mock on the shared instance
        sceneMock = OpenURLHandlerProtocolMock()
        let sceneHandler = SceneDelegateHandler(logger: MPLog(logLevel: .verbose), appNotificationHandler: sceneMock)
        mparticle.sceneDelegateHandler = sceneHandler
    }
        
    // MARK: - handleUserActivity Tests    

    func test_handleUserActivity_invokesAppNotificationHandler() {
        // Act
        mparticle.handleUserActivity(testUserActivity)
        
        // Assert - handleUserActivity directly calls the app notification handler
        XCTAssertTrue(sceneMock.continueUserActivityCalled)
        XCTAssertEqual(sceneMock.continueUserActivityUserActivityParam, testUserActivity)
        XCTAssertNotNil(sceneMock.continueUserActivityRestorationHandlerParam)
    }
    
    func test_handleUserActivity_withWebBrowsingActivity() {
        // Arrange
        let webActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        webActivity.title = "Web Page"
        webActivity.webpageURL = URL(string: "https://example.com/page")
        
        // Act
        mparticle.handleUserActivity(webActivity)
        
        // Assert - Direct call to app notification handler
        XCTAssertTrue(sceneMock.continueUserActivityCalled)
        XCTAssertEqual(sceneMock.continueUserActivityUserActivityParam, webActivity)
    }
    
    func test_handleUserActivity_restorationHandlerIsEmpty() {
        // Act
        mparticle.handleUserActivity(testUserActivity)
        
        // Assert
        XCTAssertTrue(sceneMock.continueUserActivityCalled)
        
        // Verify the restoration handler is provided and safe to call
        let restorationHandler = sceneMock.continueUserActivityRestorationHandlerParam
        XCTAssertNotNil(restorationHandler)
        
        // Test that calling the restoration handler doesn't crash
        XCTAssertNoThrow(restorationHandler?(nil))
        XCTAssertNoThrow(restorationHandler?([]))
    }
}
