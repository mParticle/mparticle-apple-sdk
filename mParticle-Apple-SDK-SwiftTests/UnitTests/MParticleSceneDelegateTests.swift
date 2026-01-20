import XCTest
@testable import mParticle_Apple_SDK_NoLocation

final class SceneDelegateHandlerTests: XCTestCase {

    // MARK: - Properties

    var sut: SceneDelegateHandler!
    var openURLHandler: OpenURLHandlerProtocolMock!
    var testURL = URL(string: "myapp://test/path?param=value")!
    var testUserActivity: NSUserActivity {
        let userActivity = NSUserActivity(activityType: "com.test.activity")
        userActivity.title = "Test Activity"
        userActivity.userInfo = ["key": "value"]
        return userActivity
    }

    override func setUp() {
        super.setUp()

        openURLHandler = OpenURLHandlerProtocolMock()
        sut = SceneDelegateHandler(logger: MPLog(logLevel: .verbose), appNotificationHandler: openURLHandler)
    }

    // MARK: - handleUserActivity Tests    

    func test_handleUserActivity_callsContinueUserActivity() {
        // Act
        sut.handleUserActivity(testUserActivity)

        // Assert - handleUserActivity directly calls the app notification handler
        XCTAssertTrue(openURLHandler.continueUserActivityCalled)
        XCTAssertEqual(openURLHandler.continueUserActivityUserActivityParam?.title, testUserActivity.title)
        XCTAssertEqual(openURLHandler.continueUserActivityUserActivityParam?.userInfo?["key"] as? String, "value")
        XCTAssertNotNil(openURLHandler.continueUserActivityRestorationHandlerParam)
        XCTAssertNoThrow(openURLHandler.continueUserActivityRestorationHandlerParam?(nil))
        XCTAssertNoThrow(openURLHandler.continueUserActivityRestorationHandlerParam?([]))
    }
}
