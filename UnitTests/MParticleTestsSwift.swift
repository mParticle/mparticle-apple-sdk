import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class MParticleTestsSwift: XCTestCase {
    var receivedMessage: String?
    var mparticle: MParticle!
    
    func customLogger(_ message: String) {
        receivedMessage = message
    }
    
    override func setUp() {
        super.setUp()
        
        mparticle = MParticle.sharedInstance()
        mparticle.logLevel = .verbose
        mparticle.customLogger = customLogger
    }
    
    override func tearDown() {
        super.tearDown()
        receivedMessage = nil
    }
    
    func testSetOptOutCompletionSuccess() {
        mparticle.setOptOutCompletion(.success, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out: 1")
    }
    
    func testSetOptOutCompletionFailure() {
        mparticle.setOptOutCompletion(.fail, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out Failed: 1")
    }
    
    func testIdentifyNoDispatchCallbackNoErrorDefferedKitAvailable() {
        mparticle.deferredKitConfiguration_PRIVATE = [[String: String]]();
        let expectedApiResult = MPIdentityApiResult()
        let options = MParticleOptions()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, error in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        mparticle.identifyNoDispatchCallback(expectedApiResult, error: nil, options: options)
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertNil(receivedMessage)
        XCTAssertNil(mparticle.deferredKitConfiguration_PRIVATE)
    }
    
    func testIdentifyNoDispatchCallbackWithErrorDefferedKitAvailable() {
        mparticle.deferredKitConfiguration_PRIVATE = [[String: String]]();
        let expectedApiResult = MPIdentityApiResult()
        let expectedError = NSError(domain: "", code: 0)
        let options = MParticleOptions()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, error in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertTrue(expectedError == expectedError)
            
            expectation.fulfill()
        }
        mparticle.identifyNoDispatchCallback(expectedApiResult, error: expectedError, options: options)
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(receivedMessage, "mParticle -> Identify request failed with error: Error Domain= Code=0 \"(null)\"")
        XCTAssertNil(mparticle.deferredKitConfiguration_PRIVATE)
    }
    
    func testConfigureDefaultConfigurationExistOptionParametersAreNotSet() {
        let options = MParticleOptions()
        mparticle.backendController = MPBackendController_PRIVATE()
        mparticle.configure(with: options)
        XCTAssertEqual(mparticle.backendController.sessionTimeout, 0.0)
        XCTAssertEqual(mparticle.backendController.uploadInterval, 60.0)
        XCTAssertEqual(mparticle.customUserAgent, nil)
        XCTAssertEqual(mparticle.collectUserAgent, true)
        XCTAssertEqual(mparticle.trackNotifications, true)
    }
    
    func testConfigureWhenDefaultConfigurationExists() {
        let settingsProvider = SettingsProviderMock()
        let settings: NSMutableDictionary = [
            "session_timeout": NSNumber(value: 2.0),
            "upload_interval": NSNumber(value: 3.0),
            "custom_user_agent": "custom_user_agent",
            "collect_user_agent": false,
            "track_notifications": false,
            "enable_location_tracking": true,
            "location_tracking_accuracy": 100.0,
            "location_tracking_distance_filter": 10.0
        ]
        settingsProvider.configSettings = settings
        mparticle.settingsProvider = settingsProvider
        mparticle.backendController = MPBackendController_PRIVATE()
        let options = MParticleOptions()
        mparticle.configure(with: options)
        
        XCTAssertEqual(mparticle.backendController.sessionTimeout, 2.0)
        XCTAssertEqual(mparticle.backendController.uploadInterval, 3.0)
        XCTAssertEqual(mparticle.customUserAgent, "custom_user_agent")
        XCTAssertEqual(mparticle.collectUserAgent, false)
        XCTAssertEqual(mparticle.trackNotifications, false)
    }
    
    func testStartWithKeyCallbackFirstRun() {
        let options = MParticleOptions()
        let userDefaults = MPUserDefaultsMock()
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
        let options = MParticleOptions()
        let user = mparticle.identity.currentUser
        options.identifyRequest = MPIdentityApiRequest(user: user!)

        let userDefaults = MPUserDefaultsMock()
        
        mparticle.start(withKeyCallback: false, options: options, userDefaults: userDefaults)
        
        XCTAssertTrue(mparticle.initialized)
        XCTAssertNil(mparticle.settingsProvider.configSettings)

        XCTAssertFalse(userDefaults.setMPObjectCalled)
        XCTAssertFalse(userDefaults.synchronizeCalled)
    }
    
    func testBeginTimedEventCompletionHandlerDataFilterNotSet() {
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.beginTimedEventCompletionHandler(MPEvent(), execStatus: .success)
        XCTAssertEqual(receivedMessage, """
            mParticle -> Began timed event: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
    }
    
    func testBeginTimedEventCompletionHandlerDataFilterSetDataFilterReturnNil() {
        let dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter
        let expectedEvent = MPEvent()
        
        mparticle.beginTimedEventCompletionHandler(expectedEvent, execStatus: .success)
        XCTAssert(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === expectedEvent)
        XCTAssertEqual(receivedMessage, """
            mParticle -> Blocked timed event begin from kits: Event:{
              Name: <<Event With No Name>>
              Type: Other\n  Duration: 0
            }
            """
        )
    }
}
