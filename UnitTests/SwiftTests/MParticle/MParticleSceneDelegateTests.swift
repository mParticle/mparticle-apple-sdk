#if os(iOS)
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif
import XCTest

// MARK: - SceneDelegateHandler Tests

final class SceneDelegateHandlerTests: XCTestCase {
    
    // MARK: - Properties
    var handler: SceneDelegateHandler!
    var mockOpenURLHandler: OpenURLHandlerProtocolMock!
    var logger: MPLog!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        logger = MPLog(logLevel: .verbose)
        mockOpenURLHandler = OpenURLHandlerProtocolMock()
        handler = SceneDelegateHandler(logger: logger, appNotificationHandler: mockOpenURLHandler)
    }
    
    override func tearDown() {
        handler = nil
        mockOpenURLHandler = nil
        logger = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_createsHandler() {
        XCTAssertNotNil(handler)
    }
    
    // MARK: - handleUserActivity Tests
    
    func test_handleUserActivity_callsAppNotificationHandler() {
        // Arrange
        let userActivity = NSUserActivity(activityType: "com.test.activity")
        userActivity.title = "Test Activity"
        
        // Act
        handler.handleUserActivity(userActivity)
        
        // Assert
        XCTAssertTrue(mockOpenURLHandler.continueUserActivityCalled)
        XCTAssertEqual(mockOpenURLHandler.continueUserActivityUserActivityParam, userActivity)
    }
    
    func test_handleUserActivity_withWebBrowsingActivity_callsHandler() {
        // Arrange
        let webActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        webActivity.webpageURL = URL(string: "https://example.com/deep/link")
        
        // Act
        handler.handleUserActivity(webActivity)
        
        // Assert
        XCTAssertTrue(mockOpenURLHandler.continueUserActivityCalled)
        XCTAssertEqual(mockOpenURLHandler.continueUserActivityUserActivityParam?.activityType, NSUserActivityTypeBrowsingWeb)
        XCTAssertEqual(mockOpenURLHandler.continueUserActivityUserActivityParam?.webpageURL?.absoluteString, "https://example.com/deep/link")
    }
    
    func test_handleUserActivity_restorationHandlerIsSafeToCall() {
        // Arrange
        let userActivity = NSUserActivity(activityType: "com.test.activity")
        
        // Act
        handler.handleUserActivity(userActivity)
        
        // Assert - calling the restoration handler should not crash
        let restorationHandler = mockOpenURLHandler.continueUserActivityRestorationHandlerParam
        XCTAssertNotNil(restorationHandler)
        XCTAssertNoThrow(restorationHandler?(nil))
        XCTAssertNoThrow(restorationHandler?([]))
    }
}

// MARK: - MParticle Scene Delegate Integration Tests

final class MParticleSceneDelegateIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    var mparticle: MParticle!
    var sceneMock: OpenURLHandlerProtocolMock!
    var testUserActivity: NSUserActivity!
    
    override func setUp() {
        super.setUp()
        mparticle = MParticle()
        testUserActivity = NSUserActivity(activityType: "com.test.activity")
        testUserActivity.title = "Test Activity"
        testUserActivity.userInfo = ["key": "value"]
        
        // Set up mock on the scene delegate handler
        sceneMock = OpenURLHandlerProtocolMock()
        let sceneHandler = SceneDelegateHandler(logger: MPLog(logLevel: .verbose), appNotificationHandler: sceneMock)
        mparticle.sceneDelegateHandler = sceneHandler
    }
    
    override func tearDown() {
        mparticle = nil
        sceneMock = nil
        testUserActivity = nil
        super.tearDown()
    }
    
    // MARK: - handleUserActivity via MParticle Tests
    
    func test_handleUserActivity_invokesSceneDelegateHandler() {
        // Act
        mparticle.handleUserActivity(testUserActivity)
        
        // Assert
        XCTAssertTrue(sceneMock.continueUserActivityCalled)
        XCTAssertEqual(sceneMock.continueUserActivityUserActivityParam, testUserActivity)
        XCTAssertNotNil(sceneMock.continueUserActivityRestorationHandlerParam)
    }
}

// MARK: - MPSceneDelegate Tests

@available(iOS 13.0, *)
final class MPSceneDelegateTests: XCTestCase {
    
    var sceneDelegate: MPSceneDelegate!
    
    override func setUp() {
        super.setUp()
        sceneDelegate = MPSceneDelegate()
    }
    
    override func tearDown() {
        sceneDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func test_init_createsInstance() {
        XCTAssertNotNil(sceneDelegate)
    }
    
    func test_conformsToUIWindowSceneDelegate() {
        XCTAssertTrue(sceneDelegate is UIWindowSceneDelegate)
    }
    
    // MARK: - Method Existence Tests
    // Verify the key delegate methods exist (actual functionality tested via integration tests)
    
    func test_respondsToSceneWillConnectTo() {
        let selector = #selector(UIWindowSceneDelegate.scene(_:willConnectTo:options:))
        XCTAssertTrue(sceneDelegate.responds(to: selector))
    }
    
    func test_respondsToSceneOpenURLContexts() {
        let selector = #selector(UIWindowSceneDelegate.scene(_:openURLContexts:))
        XCTAssertTrue(sceneDelegate.responds(to: selector))
    }
    
    func test_respondsToSceneContinueUserActivity() {
        let selector = #selector(UIWindowSceneDelegate.scene(_:continue:))
        XCTAssertTrue(sceneDelegate.responds(to: selector))
    }
}
#endif
