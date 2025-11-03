import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

enum LogKitBatchData {
    static let invalidJSON = #"{"invalid": "json""#
    static let singleEvent = #"{"events":[{"id":1}]}"#
    static let multiEvent = #"{"events":[{"id":1},{"id":2}]}"#
    static let parsedSingleEvent: [String: Any] = [
        "events": [
            ["id": 1]
        ]
    ]
}

class MParticleTestsSwift: XCTestCase {
    var receivedMessage: String?
    var mparticle: MParticle!
    var listenerController: MPListenerControllerMock!
    var kitContainer: MPKitContainerMock!
    var executor: ExecutorMock!
    var backendController: MPBackendControllerMock!
    var state: MPStateMachineMock!
    var notificationController: MPNotificationControllerMock!
    var appEnvironmentProvier: AppEnvironmentProviderMock!
    var appNotificationHandler: MPAppNotificationHandlerMock!
    var persistenceController: MPPersistenceControllerMock!
    var settingsProvider: SettingsProviderMock!
    var options: MParticleOptions!
    var userDefaults: MPUserDefaultsMock!
    var dataPlanFilter: MPDataPlanFilterMock!
    var kit: MPKitMock!
    
    let testName: String = "test"
    let keyValueDict: [String: String] = ["key": "value"]
    let responseKeyValueDict: [String: String] = ["responseKey": "responseValue"]
    
    let token = "abcd1234".data(using: .utf8)!
    
    let error = NSError(domain: "test", code: 1)
    
    let url = URL(string: "https://example.com")!
    
    lazy var event: MPEvent = {
        let event = MPEvent(name: testName, type: .other)!
        event.customAttributes = keyValueDict
        return event
    }()
    
    lazy var transformedEvent: MPEvent = {
        let event = MPEvent(name: testName, type: .addToCart)!
        event.customAttributes = keyValueDict
        return event
    }()
    
    lazy var baseEvent: MPBaseEvent = {
        return MPBaseEvent(eventType: .other)!
    }()
    
    lazy var transformedBaseEvent: MPBaseEvent = {
        return MPBaseEvent(eventType: .addToCart)!
    }()
    
    lazy var commerceEvent: MPCommerceEvent = {
        let event = MPCommerceEvent(action: .addToCart)!
        return event
    }()
    
    lazy var transformedCommerceEvent: MPCommerceEvent = {
        let event = MPCommerceEvent(action: .addToCart)!
        return event
    }()
    
    func customLogger(_ message: String) {
        receivedMessage = message
    }
    
    override func setUp() {
        super.setUp()
        mparticle = MParticle.sharedInstance()
        mparticle = MParticle()
        mparticle.logLevel = .verbose
        mparticle.customLogger = customLogger
        listenerController = MPListenerControllerMock()
        listenerController.onAPICalledExpectation = XCTestExpectation()
        mparticle.listenerController = listenerController
        
        kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)
        
        executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        state = MPStateMachineMock()
        mparticle.stateMachine = state
        
        notificationController = MPNotificationControllerMock()
        mparticle.notificationController = notificationController
        
        appEnvironmentProvier = AppEnvironmentProviderMock()
        mparticle.appEnvironmentProvider = appEnvironmentProvier
        
        appNotificationHandler = MPAppNotificationHandlerMock()
        mparticle.appNotificationHandler = appNotificationHandler
        
        persistenceController = MPPersistenceControllerMock()
        mparticle.persistenceController = persistenceController
        
        settingsProvider = SettingsProviderMock()
        mparticle.settingsProvider = settingsProvider
        
        dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter
        
        options = MParticleOptions()
        
        userDefaults = MPUserDefaultsMock()
        
        kit = MPKitMock()
    }

    override func tearDown() {
        super.tearDown()
        receivedMessage = nil
        mparticle.dataPlanFilter = nil
    }
    
    func testSetOptOutCompletionSuccess() {
        mparticle.setOptOutCompletion(.success, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out: 1")
    }
    
    func testSetOptOutCompletionFailure() {
        mparticle.setOptOutCompletion(.fail, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out Failed: 1")
    }
    
    func testSetOptOutOptOutValueIsDifferentItShouldBeChangedAndDeliveredToBackendController() {
        XCTAssertFalse(state.optOut)
        mparticle.optOut = true
        XCTAssertTrue(state.optOut)
        XCTAssertTrue(backendController.setOptOutCalled)
        XCTAssertEqual(backendController.setOptOutOptOutStatusParam, true)
        XCTAssertNotNil(backendController.setOptOutCompletionHandler)
        backendController.setOptOutCompletionHandler?(true, .success)
    }
    
    func testIdentifyNoDispatchCallbackNoErrorDefferedKitAvailable() {
        mparticle.deferredKitConfiguration_PRIVATE = [[String: String]]()
        let expectedApiResult = MPIdentityApiResult()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, error in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        mparticle.identifyNoDispatchCallback(expectedApiResult, error: nil, options: options)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedMessage)
        XCTAssertNil(mparticle.deferredKitConfiguration_PRIVATE)
    }
    
    func testIdentifyNoDispatchCallbackWithErrorDefferedKitAvailable() {
        mparticle.deferredKitConfiguration_PRIVATE = [[String: String]]()
        let expectedApiResult = MPIdentityApiResult()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, _ in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertTrue(self.error == self.error)
            
            expectation.fulfill()
        }
        mparticle.identifyNoDispatchCallback(expectedApiResult, error: error, options: options)
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(receivedMessage, "mParticle -> Identify request failed with error: Error Domain=test Code=1 \"(null)\"")
        XCTAssertNil(mparticle.deferredKitConfiguration_PRIVATE)
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
    
    func testBeginTimedEventCompletionHandlerDataFilterNotSet() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        XCTAssertEqual(receivedMessage, """
        mParticle -> Began timed event: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testBeginTimedEventCompletionHandlerDataFilterSetDataFilterReturnNil() {
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        XCTAssertEqual(receivedMessage, """
        mParticle -> Blocked timed event begin from kits: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLogEventCallbackDataFilterNotSet() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logEventCallback(event, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogEventCallbackDataFilterSetDataFilterReturnNil() {
        mparticle.logEventCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Blocked timed event end from kits: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLogScreenCallbackDataFilterNotSet() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logScreenCallback(event, execStatus: .success)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Logged screen event: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLogScreenCallbackDataFilterSetDataFilterReturnNil() {
        mparticle.logScreenCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventForScreenEventScreenEventParam, event)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Blocked screen event from kits: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLogErrorCallbackSuccess() {
        mparticle.logErrorCallback([:], execStatus: .success, message: "error")
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Logged error with message: error
        """)
    }
    
    func testLogErrorCallbackFail() {
        mparticle.logErrorCallback([:], execStatus: .fail, message: "error")
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogExceptionCallbackSuccess() {
        let exception = NSException(name: NSExceptionName("Test"), reason: "Test", userInfo: nil)
        mparticle.logExceptionCallback(exception, execStatus: .success, message: "exception", topmostContext: nil)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Logged exception name: exception, reason: Test, topmost context: (null)
        """)
    }
    
    func testLogExceptionCallbackFail() {
        let exception = NSException(name: NSExceptionName("Test"), reason: "Test", userInfo: nil)
        mparticle.logExceptionCallback(exception, execStatus: .fail, message: "exception", topmostContext: nil)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCrashCallbackSuccess() {
        mparticle.logCrashCallback(.success, message: "Message")
        XCTAssertEqual(receivedMessage, "mParticle -> Logged crash with message: Message")
    }
    
    func testLogCommerceEventCallbackSuccess() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCommerceEventCallbackFail() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .fail)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Failed to log commerce event: MPCommerceEvent {
         Action Attributes:{
            an:add_to_cart
          }
        MPTransactionAttributes {
        }
        }

        """)
    }
    
    func testLogNetworkPerformanceCallbackSuccess() {
        mparticle.logNetworkPerformanceCallback(.success)
        
        XCTAssertEqual(receivedMessage, "mParticle -> Logged network performance measurement")
    }
    
    func testLogNetworkPerformanceCallbackFail() {
        mparticle.logNetworkPerformanceCallback(.fail)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testSetSharedInstance() {
        MParticle.setSharedInstance(mparticle)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "setSharedInstance:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === mparticle)
    }
    
    func testStartWithOptionsListenerControllerCalled() {
        let options = MParticleOptions(key: "key", secret: "secret")
        mparticle.start(with: options)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "startWithOptions:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === options)
    }
    
    func testBeginTimedEventDependenciesReceiveCorrectParametersAndHandlerExecutedWithoutErrors() {
        mparticle.beginTimedEvent(event)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "beginTimedEvent:")
        XCTAssertEqual(listenerController.onAPICalledParameter1, event)
        XCTAssertTrue(backendController.beginTimedEventCalled)
        XCTAssertEqual(backendController.beginTimedEventEventParam, event)
        XCTAssertNotNil(backendController.beginTimedEventCompletionHandler)
        backendController.beginTimedEventCompletionHandler?(event, .success)
        XCTAssertNotNil(receivedMessage)
    }
    
    func testEndTimedEventListenerControllerCalled() {
        mparticle.endTimedEvent(event)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "endTimedEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
    }
    
    func testLogEventWithBaseEventListenerControllerCalled() {
        mparticle.logEvent(baseEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === baseEvent)
    }
    
    func testLogCustomEventListenerControllerCalled() {
        mparticle.logEvent(event)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
    }
    
    func testLogScreenEventListenerControllerCalled() {
        mparticle.logScreenEvent(event)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logScreenEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
    }
    
    func testLogErrorListenerControllerCalled() {
        mparticle.logError("message", eventInfo: [:])
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logError:eventInfo:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "message")
    }
    
    func testLogExceptionListenerControllerCalled() {
        let expectedException = NSException(name: NSExceptionName("test"), reason: "test")
        mparticle.logException(expectedException, topmostContext: nil)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logException:topmostContext:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedException)
    }
    
    func testLogCrashListenerControllerCalled() {
        mparticle.logCrash("message", stackTrace: "stackTrace", plCrashReport: "report")
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCrash:stackTrace:plCrashReport:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "message")
    }
    
    func testLogCommerceEventListenerControllerCalled() {
        mparticle.logCommerceEvent(commerceEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === commerceEvent)
    }
    
    func testSetIntegrationAttributesListenerControllerCalled() {
        mparticle.setIntegrationAttributes(["test": "test"], forKit: NSNumber(value: 1))
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "setIntegrationAttributes:forKit:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? [String: String], ["test": "test"])
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? Int, 1)
    }
    
    func testClearIntegrationAttributesListenerControllerCalled() {
        mparticle.clearIntegrationAttributes(forKit: 1)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "clearIntegrationAttributesForKit:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Int, 1)
    }
    
    func testOnKitsInitializedListenerControllerCalled() {
        mparticle.onKitsInitialized {}
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "onKitsInitialized:")
        XCTAssertNotNil(listenerController.onAPICalledParameter1)
    }
    
    func testExecuteKitsInitializedBlocks() {
        mparticle.executeKitsInitializedBlocks()
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "executeKitsInitializedBlocks")
        XCTAssertNil(listenerController.onAPICalledParameter1)
    }
    
    func testIsKitActiveListenerControllerCalled() {
        mparticle.isKitActive(1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "isKitActive:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Int, 1)
    }
    
    func testKitInstanceListenerControllerCalled() {
        mparticle.kitInstance(1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "kitInstance:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Int, 1)
    }
    
    func testKitInstanceCompletionHandlerListenerControllerCalled() {
        mparticle.kitInstance(1) { _ in }
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "kitInstance:completionHandler:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Int, 1)
    }
    
#if os(iOS)
    func testBackgroundLocationTrackingListenerControllerCalled() {
        mparticle.backgroundLocationTracking = true
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "setBackgroundLocationTracking:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Bool, true)
        
        _ = mparticle.backgroundLocationTracking
        XCTAssertEqual(listenerController.onAPICalledApiNames[1].description, "backgroundLocationTracking")
    }
    
    func testWebviewBridgeValueWithCustomerBridgeNameListenerControllerCalled() {
        mparticle.initializeWKWebView(WKWebView(), bridgeName: "name")
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "initializeWKWebView:bridgeName:")
        XCTAssertNotNil(listenerController.onAPICalledParameter1)
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? String, "name")
    }
    
    func testLogNotificationOpenedWithUserInfoAndActionIdentifierListenerControllerCalled() {
        mparticle.logNotificationOpened(userInfo: [:], andActionIdentifier: "identifier")
        XCTAssertEqual(listenerController.onAPICalledApiName?.description,
                       "logNotificationOpenedWithUserInfo:andActionIdentifier:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? [String: String], [:])
    }
    
    func testUserContentControllerDidReceiveScriptMessageListenerControllerCalled() {
        mparticle.userContentController(WKUserContentController(), didReceive: WKScriptMessage())
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "userContentController:didReceiveScriptMessage:")
        XCTAssertNotNil(listenerController.onAPICalledParameter1)
        XCTAssertNotNil(listenerController.onAPICalledParameter2)
    }
    
    func testHandleWebviewCommandListenerControllerCalled() {
        mparticle.handleWebviewCommand("command", dictionary: [:])
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "handleWebviewCommand:dictionary:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "command")
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? [String: String], [:])
    }
    
#if !MPARTICLE_LOCATION_DISABLE
    func testLocationListenerControllerCalled() {
        _ = mparticle.location
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "location")
    }
    
    func testSetLocationListenerControllerCalled() {
        let expectedLocation = CLLocation(latitude: 1, longitude: 2)
        mparticle.location = expectedLocation
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "setLocation:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? CLLocation, expectedLocation)
    }
    
    func testBeginLocationTrackingListenerControllerCalled() {
        mparticle.beginLocationTracking(CLLocationAccuracy.nan, minDistance: CLLocationDistance.nan)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description,
                       "beginLocationTracking:minDistance:authorizationRequest:")
        XCTAssertNotNil(listenerController.onAPICalledParameter1)
        XCTAssertNotNil(listenerController.onAPICalledParameter2)
    }
    
    func testEndLocationTrackingListenerControllerCalled() {
        mparticle.endLocationTracking()
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "endLocationTracking")
    }
#endif
#endif
    func testNetworkPermissionListenerControllerCalled() {
        mparticle.logNetworkPerformance("", httpMethod: "", startTime: 0.0, duration: 1.0, bytesSent: 100, bytesReceived: 200)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description,
                       "logNetworkPerformance:httpMethod:startTime:duration:bytesSent:bytesReceived:")
        XCTAssertNotNil(listenerController.onAPICalledParameter1)
    }
    
    func testIncrementSessionAttributeListenerControllerCalled() {
        mparticle.incrementSessionAttribute("key", byValue: 1)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "incrementSessionAttribute:byValue:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "key")
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? Int, 1)
    }
    
    func testSetSessionAttributeListenerControllerCalled() {
        mparticle.setSessionAttribute("key", value: "value")
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "setSessionAttribute:value:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "key")
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? String, "value")
    }
    
    func testUploadListenerControllerCalled() {
        mparticle.upload()
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 1.0)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "upload")
    }
    
    func testIsValidBridgeNameListenerControllerCalled() {
        mparticle.isValidBridgeName("name")
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "isValidBridgeName:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "name")
    }
    
    func testWebviewBridgeValueWithCustomerBridgeNameListenerControllerReturnValue() {
        mparticle.webviewBridgeValue(withCustomerBridgeName: "value")
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "webviewBridgeValueWithCustomerBridgeName:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "value")
    }
    
    func testSessionDidBegin() {
        kitContainer.forwardSDKCallExpectation = XCTestExpectation()
        mparticle.sessionDidBegin(MPSession())
        
        wait(for: [kitContainer.forwardSDKCallExpectation!], timeout: 1.0)
        
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "beginSession")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .sessionStart)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testSessionDidEnd() {
        kitContainer.forwardSDKCallExpectation = XCTestExpectation()
        mparticle.sessionDidEnd(MPSession())
        
        wait(for: [kitContainer.forwardSDKCallExpectation!], timeout: 1.0)
        
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "endSession")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .sessionEnd)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
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
    
    func testBeginSessionTempSessionAvailableSessionTempSessionShouldNotBeCreated() {
        backendController.session = nil
        backendController.tempSessionReturnValue = MParticleSession()
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func testBeginSessionSessionAvailableSessionTempSessionShouldNotBeCreated() {
        backendController.session = MPSession()
        backendController.tempSessionReturnValue = nil
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func testBeginSessionSessionUnavailable() {
        backendController.session = nil
        backendController.tempSessionReturnValue = nil
        mparticle.beginSession()
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(backendController.createTempSessionCalled)
        XCTAssertTrue(backendController.beginSessionCalled)
        XCTAssertEqual(backendController.beginSessionIsManualParam, true)
        XCTAssertNotNil(backendController.beginSessionDateParam)
    }
    
    func testEndSessionNoSession() {
        backendController.session = nil
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertFalse(backendController.endSessionWithIsManualCalled)
    }
    
    func testEndSessionWithSession() {
        backendController.session = MPSession()
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertTrue(backendController.endSessionWithIsManualCalled)
        XCTAssertEqual(backendController.endSessionIsManualParam, true)
    }
    
    func testForwardLogInstall() {
        mparticle.forwardLogInstall()
        XCTAssertEqual(executor.executeOnMainAsync, true)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "forwardLogInstall")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testForwardLogUpdate() {
        mparticle.forwardLogUpdate()
        XCTAssertEqual(executor.executeOnMainAsync, true)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "forwardLogUpdate")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testIndentityReturnsTheSameObject() {
        let identity = mparticle.identity
        XCTAssertTrue(identity === mparticle.identity)
    }
    
    func testRoktReturnsTheSameObject() {
        let rokt = mparticle.rokt
        XCTAssertTrue(rokt === mparticle.rokt)
    }
    
    func testSessionTimeoutReturnsValueFromBackendController() {
        mparticle.backendController.sessionTimeout = 100
        XCTAssertEqual(mparticle.sessionTimeout, 100)
    }
    
    func testUniqueIdentifierRwturnedFromStateMachine() {
        state.consumerInfo.uniqueIdentifier = "test"
        XCTAssertEqual(mparticle.uniqueIdentifier, "test")
    }
    
    func testSetUploadIntervalChangeValueInBackendControllerWhenIntervalGreaterThenOne() {
        mparticle.setUploadInterval(3)
        XCTAssertEqual(backendController.uploadInterval, 3)
    }
    
    func testSetUploadIntervalNotChangeValueInBackendControllerWhenIntervalLessThenOne() {
        mparticle.setUploadInterval(0.1)
        XCTAssertEqual(backendController.uploadInterval, 0.0)
    }
    
    func testUploadIntervalGetFromBackendController() {
        backendController.uploadInterval = 100
        XCTAssertEqual(mparticle.uploadInterval, 100)
    }
    
    func testUserAttributesForUserIdRequestDataFromBackendController() {
        backendController.userAttributesReturnValue = ["key": "value"]
        let dictionary = mparticle.userAttributes(forUserId: 1)
        XCTAssertEqual(dictionary?["key"] as? String, "value")
        XCTAssertTrue(backendController.userAttributesCalled)
        XCTAssertEqual(backendController.userAttributesUserIdParam, 1)
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
    
    // MARK: - logEvent
    
    func testLogEventCalledLogCustomEvent() {
        mparticle.logEvent(event)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
    }
    
    func testLogEventCalledLogCommerceEvent() {
        mparticle.logEvent(commerceEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
    }
    
    func testLogEventWithFilterReturningNil_blocksEvent() {
        dataPlanFilter.transformEventForBaseEventReturnValue = nil
        
        mparticle.logEvent(baseEvent)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === baseEvent)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logBaseEventCalled)
        XCTAssertTrue(backendController.logBaseEventEventParam === baseEvent)
        let completion = backendController.logBaseEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(baseEvent, .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Verify filter transform event
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventParam === baseEvent)
        
        // Logger should record the blocked event message
        XCTAssertEqual(receivedMessage, "mParticle -> Blocked base event from kits: \(baseEvent)")
    }
    
    func testLogBaseEventWithFilterReturningEvent_forwardsTransformedEvent() {
        dataPlanFilter.transformEventForBaseEventReturnValue = transformedBaseEvent
        
        mparticle.logEvent(baseEvent)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === baseEvent)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logBaseEventCalled)
        XCTAssertTrue(backendController.logBaseEventEventParam === baseEvent)
        let completion = backendController.logBaseEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(baseEvent, .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify filter transformed event
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventParam === baseEvent)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBaseEvent:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertTrue(kitContainer.forwardSDKCallEventParam === transformedBaseEvent)
    }
    
    // MARK: - logCustomEvent
    
    func testLogCustomEventWithNilEvent_logsError() {
        mparticle.logCustomEvent(nil)
        XCTAssertEqual(receivedMessage, "mParticle -> Cannot log nil event!")
    }
    
    func testLogCustomEventWithFilterReturningNil_blocksEvent() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.logCustomEvent(event)
        
        // Verify event timing ended
        XCTAssertNil(event.endTime)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Verify filter transform event
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        // Logger should record the blocked event message
        XCTAssertEqual(receivedMessage, "mParticle -> Blocked custom event from kits: \(event)")
    }
    
    func testLogCustomEventWithFilterReturningEvent_forwardsTransformedEvent() {
        dataPlanFilter.transformEventReturnValue = transformedEvent
        
        mparticle.logCustomEvent(event)
        
        // Verify event timing ended
        XCTAssertNil(event.endTime)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify filter transformed event
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logEvent:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .event)
        XCTAssertTrue(kitContainer.forwardSDKCallEventParam === transformedEvent)
    }
    
    // MARK: - logScreen
    
    func testLogScreenEvent_dataPlanFilterReturnsNil_blocksEvent() {
        mparticle.logScreenEvent(event)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logScreenEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        XCTAssertTrue(backendController.logScreenCalled)
        XCTAssertTrue(backendController.logScreenEventParam === event)
        XCTAssertNotNil(backendController.logScreenCompletionHandler)
        
        backendController.logScreenCompletionHandler?(event, .success)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Blocked screen event from kits: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLogScreenEvent_tracesFullExecutionFlow() {
        dataPlanFilter.transformEventForScreenEventReturnValue = event
        
        mparticle.logScreenEvent(event)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logScreenEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        XCTAssertTrue(backendController.logScreenCalled)
        XCTAssertTrue(backendController.logScreenEventParam === event)
        XCTAssertNotNil(backendController.logScreenCompletionHandler)
        
        backendController.logScreenCompletionHandler?(event, .success)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Logged screen event: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventScreenEventParam === event)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logScreen:")
        XCTAssertTrue(kitContainer.forwardSDKCallEventParam === event)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .screenView)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testLogScreenWrapper_withNilScreenName_logsErrorAndReturns() {
        mparticle.logScreen("", eventInfo: event.customAttributes)
        
        XCTAssertEqual(receivedMessage, "mParticle -> Screen name is required.")
        XCTAssertFalse(backendController.eventWithNameCalled)
        XCTAssertFalse(executor.executeOnMessageQueueAsync)
        XCTAssertFalse(listenerController.onAPICalledCalled)
        XCTAssertFalse(backendController.logScreenCalled)
    }
    
    func testLogScreenWrapper_callsLogScreen() {
        backendController.eventWithNameReturnValue = event
        dataPlanFilter.transformEventForScreenEventReturnValue = event
        
        mparticle.logScreen(event.name, eventInfo: event.customAttributes)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, testName)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logScreenEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        XCTAssertTrue(backendController.logScreenCalled)
        XCTAssertNotNil(backendController.logScreenCompletionHandler)
        backendController.logScreenCompletionHandler!(event, .success)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Logged screen event: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventScreenEventParam === event)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logScreen:")
        XCTAssertTrue(kitContainer.forwardSDKCallEventParam === event)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .screenView)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testLogScreen_withNoExistingEvent_createsNewEventOfTypeNavigation() {
        backendController.eventWithNameReturnValue = nil
        let mockMPNavEvent = MPEvent(name: testName, type: .navigation)!
        mockMPNavEvent.customAttributes = keyValueDict
        mockMPNavEvent.shouldUploadEvent = true
        
        dataPlanFilter.transformEventForScreenEventReturnValue = mockMPNavEvent
        
        mparticle.logScreen(testName, eventInfo: keyValueDict, shouldUploadEvent: true)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, testName)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logScreenEvent:")
        XCTAssertEqual(listenerController.onAPICalledParameter1, mockMPNavEvent)
        XCTAssertTrue(backendController.logScreenCalled)
        XCTAssertNotNil(backendController.logScreenCompletionHandler)
        backendController.logScreenCompletionHandler!(mockMPNavEvent, .success)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Logged screen event: Event:{
          Name: test
          Type: Navigation
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventScreenEventParam === mockMPNavEvent)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logScreen:")
        XCTAssertTrue(kitContainer.forwardSDKCallEventParam === mockMPNavEvent)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .screenView)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    // MARK: - logKitBatch
    
    func testLogKitBatch_withNilBatch_doesNotExecuteOrForward() {
        mparticle.logKitBatch(nil)

        XCTAssertEqual(receivedMessage, "mParticle -> Cannot log nil batch!")
        XCTAssertFalse(executor.executeOnMessageQueueAsync)
        XCTAssertFalse(kitContainer.hasKitBatchingKitsCalled)
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertFalse(persistenceController.saveCalled)
    }
    
    func testLogKitBatch_noBatchingKits_andKitsInitialized_doesNothing() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = false

        mparticle.logKitBatch(LogKitBatchData.singleEvent)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertFalse(persistenceController.saveCalled)
    }

    func testLogKitBatch_kitsNotInitialized_defersWorkUntilInitialization() {
        kitContainer.kitsInitialized = false
        kitContainer.hasKitBatchingKitsReturnValue = true

        mparticle.logKitBatch(LogKitBatchData.singleEvent)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Should queue deferred block, not execute immediately
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertFalse(persistenceController.saveCalled)

        // Simulate kits becoming initialized
        kitContainer.kitsInitialized = true
        mparticle.executeKitsInitializedBlocks()

        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "executeKitsInitializedBlocks")
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 1)
        XCTAssertNotNil(kitContainer.forwardSDKCallKitHandlerParam)
    }

    func testLogKitBatch_withBatchingKits_forwardsParsedBatch_andPersistsForwardRecords() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = true

        mparticle.logKitBatch(LogKitBatchData.multiEvent)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 1)
        XCTAssertNotNil(kitContainer.forwardSDKCallKitHandlerParam)
    }
    
    func testLogKitBatch_invokesKitHandler_andPersistsForwardRecords() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = true

        let forwardRecord = MPForwardRecord()
        kit.logBatchReturnValue = [forwardRecord]

        mparticle.logKitBatch(LogKitBatchData.singleEvent)

        guard let kitHandler = kitContainer.forwardSDKCallKitHandlerParam else {
            XCTFail("Expected kitHandler closure to be captured")
            return
        }

        // Simulate invoking the handler
        let config = MPKitConfiguration()
        kitHandler(kit, LogKitBatchData.parsedSingleEvent, config)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 1)
        XCTAssertTrue(kit.logBatchCalled)
        XCTAssertEqual(kit.logBatchParam?["events"] as? [[String: Int]], [["id": 1]])
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(persistenceController.saveCalled)
        XCTAssertTrue(persistenceController.saveForwardRecordParam === forwardRecord)
    }

    func testLogKitBatch_invalidJSON_stillForwardsWithNilBatch() {
        kitContainer.kitsInitialized = true
        kitContainer.hasKitBatchingKitsReturnValue = true

        mparticle.logKitBatch(LogKitBatchData.invalidJSON)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBatch:")
        XCTAssertEqual(kitContainer.forwardSDKCallBatchParam?.count, 0)
        XCTAssertNotNil(kitContainer.forwardSDKCallKitHandlerParam)
    }
    
    // MARK: - logCommerceEvent
    
    func testLogCommerceEvent_assignsTimestampWhenNil() {
        commerceEvent.setTimestamp(nil)
        
        mparticle.logCommerceEvent(commerceEvent)
        
        XCTAssertNotNil(commerceEvent.timestamp)
        XCTAssertTrue(backendController.logCommerceEventCalled)
        XCTAssertTrue(listenerController.onAPICalledParameter1 === commerceEvent)
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
    }
    
    func testLogCommerceEventWithFilterReturningNil_blocksEvent() {
        dataPlanFilter.transformEventForCommerceEventParam = nil
        
        mparticle.logCommerceEvent(commerceEvent)
        
        // Verify event timestamp added
        XCTAssertNotNil(commerceEvent.timestamp)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === commerceEvent)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logCommerceEventCalled)
        XCTAssertTrue(backendController.logCommerceEventParam === commerceEvent)
        let completion = backendController.logCommerceEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(commerceEvent, .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Verify filter transform event
        XCTAssertTrue(dataPlanFilter.transformEventForCommerceEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForCommerceEventParam === commerceEvent)
        
        // Logger should record the blocked event message
        XCTAssertEqual(receivedMessage, "mParticle -> Blocked commerce event from kits: \(commerceEvent)")
    }
    
    func testLogCommerceEventWithFilterReturningEvent_forwardsTransformedEvent() {
        dataPlanFilter.transformEventForCommerceEventReturnValue = transformedCommerceEvent
        
        mparticle.logCommerceEvent(commerceEvent)
        
        // Verify event timestamp added
        XCTAssertNotNil(commerceEvent.timestamp)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === commerceEvent)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logCommerceEventCalled)
        XCTAssertTrue(backendController.logCommerceEventParam === commerceEvent)
        let completion = backendController.logCommerceEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(commerceEvent, .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Verify filter transformed event
        XCTAssertTrue(dataPlanFilter.transformEventForCommerceEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForCommerceEventParam === commerceEvent)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardCommerceEventCallCalled)
        XCTAssertTrue(kitContainer.forwardCommerceEventCallCommerceEventParam === transformedCommerceEvent)
    }
    
    // MARK: - logLTVIncrease
    
    func testLogLTVIncrease_withNameAndInfo_createsEventAndCallsBackend() {
        let amount = 42.0
        let name = "name"
        let info: [String: Any] = ["source": "in_app", "currency": "USD"]
        
        mparticle.logLTVIncrease(amount, eventName: name, eventInfo: info)
        
        // Assert event was passed through
        let loggedEvent = backendController.logEventEventParam!
        XCTAssertNotNil(loggedEvent)
        XCTAssertEqual(loggedEvent.name, name)
        XCTAssertEqual(loggedEvent.type, .transaction)
        
        // Custom attributes should include amount and method name
        let attrs = loggedEvent.customAttributes!
        XCTAssertEqual(attrs["$Amount"] as? Double, amount)
        XCTAssertEqual(attrs["$MethodName"] as? String, "LogLTVIncrease")
        
        // Check that the eventInfo entries were added
        XCTAssertEqual(attrs["source"] as? String, "in_app")
        XCTAssertEqual(attrs["currency"] as? String, "USD")
        XCTAssertEqual(attrs.count, 4)
        
        // Listener controller should be notified
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logLTVIncrease:eventName:eventInfo:")
        
        // Backend completion handler should be stored
        XCTAssertTrue(backendController.logEventCalled)
        let completion = backendController.logEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(loggedEvent, .success)
    }
    
    func testLogLTVIncrease_withoutEventInfo_defaultsToNilInfo() {
        let amount = 12.5
        let name = "name"
        
        mparticle.logLTVIncrease(amount, eventName: name)
        
        // Assert event was passed through
        let loggedEvent = backendController.logEventEventParam!
        XCTAssertNotNil(loggedEvent)
        XCTAssertEqual(loggedEvent.name, name)
        XCTAssertEqual(loggedEvent.type, .transaction)
        
        // Custom attributes should only be amount and method name
        let attrs = loggedEvent.customAttributes!
        XCTAssertEqual(attrs["$Amount"] as? Double, amount)
        XCTAssertEqual(attrs["$MethodName"] as? String, "LogLTVIncrease")
        XCTAssertEqual(attrs.count, 2)
        
        // Listener controller should be notified
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logLTVIncrease:eventName:eventInfo:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Double, amount)
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? String, name)
        XCTAssertNil(listenerController.onAPICalledParameter3)
        
        // Backend completion handler should be stored
        XCTAssertTrue(backendController.logEventCalled)
        let completion = backendController.logEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(loggedEvent, .success)
    }
    
    func testLogLTVIncreaseCallback_withSuccessExecStatus_noDataPlanFilter_forwardsEvent() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.logLTVIncreaseCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        XCTAssertEqual(receivedMessage, "mParticle -> Blocked LTV increase event from kits: \(event)")
    }
    
    func testLogLTVIncreaseCallback_withSuccessExecStatus_filterReturnsTransformedEvent_forwardsTransformedEvent() {
        dataPlanFilter.transformEventReturnValue = transformedEvent
        
        mparticle.logLTVIncreaseCallback(event, execStatus: .success)
        
        // Verify filter transformed event
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logLTVIncrease:event:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
    }
    
    // MARK: Error, Exception, and Crash Handling
    
    func testLeaveBreadcrumbCallback_withDataFilterNotSet_forwardsTransformedEvent() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.leaveBreadcrumbCallback(event, execStatus: .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "leaveBreadcrumb:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .breadcrumb)
        XCTAssertNotNil(kitContainer.forwardSDKCallEventParam)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Left breadcrumb: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLeaveBreadcrumbCallback_withDataFilterSet_andDataFilterReturnNil() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        XCTAssertEqual(receivedMessage, """
        mParticle -> Blocked breadcrumb event from kits: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    func testLeaveBreadcrumbCallback_execStatusFail_noLoggedMessages() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .fail)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLeaveBreadcrumbListenerControllerCalled() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "leaveBreadcrumb:eventInfo:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, event.name)
        XCTAssertEqual(listenerController.onAPICalledParameter2, event.customAttributes as NSObject?)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_backendControllerReceiveCorrectName() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_backendControllerReturnsNilEvent_newEventCreated() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.name, event.name)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.type, .other)
        XCTAssertNotNil(backendController.leaveBreadcrumbEventParam?.timestamp)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam!.customAttributes! as NSObject, event.customAttributes! as NSObject)
        XCTAssertNotNil(backendController.leaveBreadcrumbCompletionHandler)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_backendControllerReturnsEvent_eventModified() {
        backendController.eventSet?.add(event as Any)
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.name, event.name)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.type, .other)
        XCTAssertNotNil(backendController.leaveBreadcrumbEventParam?.timestamp)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam!.customAttributes! as NSObject, event.customAttributes! as NSObject)
        XCTAssertNotNil(backendController.leaveBreadcrumbCompletionHandler)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_CallbackCallsCallbackFunction() {
        mparticle.dataPlanFilter = nil
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        backendController.leaveBreadcrumbCompletionHandler?(event, .success)
        XCTAssertEqual(receivedMessage, """
        mParticle -> Left breadcrumb: Event:{
          Name: test
          Type: Other
          Attributes: {
            key = value;
        }
          Duration: 0
        }
        """)
    }
    
    // MARK: - Application Notification Tests
#if os(iOS)
    func testPushNotificationToken_returnsDeviceToken_whenNotAppExtension() {
        notificationController.deviceTokenReturnValue = token
        
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        let token = mparticle.pushNotificationToken
        
        XCTAssertEqual(token, self.token)
        XCTAssertTrue(notificationController.deviceTokenCalled)
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func testPushNotificationToken_returnsNil_whenAppExtension() {
        notificationController.deviceTokenReturnValue = token

        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        let token = mparticle.pushNotificationToken
        
        XCTAssertNil(token)
        XCTAssertFalse(notificationController.deviceTokenCalled)
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func testSetPushNotificationToken_setsToken_whenNotAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.pushNotificationToken = token
        
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(notificationController.setDeviceTokenCalled)
        XCTAssertEqual(notificationController.setDeviceTokenParam, token)
    }
    
    func testSetPushNotificationToken_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.pushNotificationToken = token
        
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(notificationController.setDeviceTokenCalled)
    }
    
    func testDidReceiveRemoteNotification_doesNothing_whenProxiedAppDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        mparticle.didReceiveRemoteNotification([:])

        XCTAssertFalse(appNotificationHandler.didReceiveRemoteNotificationCalled)
        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
    }
    
    func testDidReceiveRemoteNotification_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.didReceiveRemoteNotification(keyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didReceiveRemoteNotificationCalled)
    }
    
    
    
    func testDidReceiveRemoteNotification_forwardsToHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.didReceiveRemoteNotification(keyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didReceiveRemoteNotificationCalled)
        XCTAssertEqual(appNotificationHandler.didReceiveRemoteNotificationParam?[keyValueDict.keys.first!] as? String, keyValueDict.values.first)
    }
    
    func testDidFailToRegisterForRemoteNotificationsWithError_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
    }

    func testDidFailToRegisterForRemoteNotificationsWithError_doesNothing_whenProxiedDelegateSet() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
    }
    
    func testDidFailToRegisterForRemoteNotificationsWithError_forwardsToHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.didFailToRegisterForRemoteNotificationsWithError(error)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorCalled)
        XCTAssertEqual(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithErrorParam as NSError?, error)
    }

    func testDidRegisterForRemoteNotificationsWithDeviceToken_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
    }

    func testDidRegisterForRemoteNotificationsWithDeviceToken_doesNothing_whenProxiedDelegateExists() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
    }
    
    func testDidRegisterForRemoteNotificationsWithDeviceToken_callsHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.didRegisterForRemoteNotifications(withDeviceToken: token)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenCalled)
        XCTAssertEqual(appNotificationHandler.didFailToRegisterForRemoteNotificationsWithDeviceTokenParam, token)
    }

    func testHandleActionWithIdentifierForRemoteNotification_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true

        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
    }

    func testHandleActionWithIdentifierForRemoteNotification_doesNothing_whenProxiedDelegateExists() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
    }
    
    func testHandleActionWithIdentifierForRemoteNotification_callsHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict)
        
        XCTAssertTrue(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationCalled)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationIdentifierParam, testName)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationUserInfoParam?[keyValueDict.keys.first!] as? String, keyValueDict.values.first)
    }
    
    func testHandleActionWithIdentifierForRemoteNotificationWithResponseInfo_doesNothing_whenAppExtension() {
        appEnvironmentProvier.isAppExtensionReturnValue = true
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict, withResponseInfo: responseKeyValueDict)

        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
    }

    func testHandleActionWithIdentifierForRemoteNotificationWithResponseInfo_doesNothing_whenProxiedDelegateExists() {
        appEnvironmentProvier.isAppExtensionReturnValue = false

        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict, withResponseInfo: responseKeyValueDict)

        XCTAssertFalse(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertFalse(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
    }
    
    func testHandleActionWithIdentifierForRemoteNotificationWithResponseInfo_callsHandler_whenNotAppExtension_andNoProxiedDelegate() {
        appEnvironmentProvier.isAppExtensionReturnValue = false
        
        mparticle.handleAction(withIdentifier: testName, forRemoteNotification: keyValueDict, withResponseInfo: responseKeyValueDict)
        
        XCTAssertTrue(appEnvironmentProvier.isAppExtensionCalled)
        XCTAssertTrue(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoCalled)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoIdentifierParam, testName)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoUserInfoParam?[keyValueDict.keys.first!] as? String, keyValueDict.values.first)
        XCTAssertEqual(appNotificationHandler.handleActionWithIdentifierForRemoteNotificationWithResponseInfoResponseInfoParam?[responseKeyValueDict.keys.first!] as? String, responseKeyValueDict.values.first)
    }
#endif
    
    func testOpenURLSourceApplication_doesNothing_whenProxiedDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        let url = URL(string: "https://example.com")!
        let sourceApp = "com.example.app"
        let annotation = "annotation"
        mparticle.open(url, sourceApplication: sourceApp, annotation: annotation)
        
        XCTAssertFalse(appNotificationHandler.openURLWithSourceApplicationAndAnnotationCalled)
    }
    
    func testOpenURLSourceApplication_callsHandler_whenNoProxiedDelegate() {
        let sourceApp = "com.example.app"
        let annotation = "annotation"

        mparticle.open(url, sourceApplication: sourceApp, annotation: annotation)

        XCTAssertTrue(appNotificationHandler.openURLWithSourceApplicationAndAnnotationCalled)
        XCTAssertEqual(appNotificationHandler.openURLWithSourceApplicationAndAnnotationURLParam, url)
        XCTAssertEqual(appNotificationHandler.openURLWithSourceApplicationAndAnnotationSourceApplicationParam, sourceApp)
        XCTAssertEqual(appNotificationHandler.openURLWithSourceApplicationAndAnnotationAnnotationParam as! String, annotation)
    }
    
    func testOpenURLOptions_callsHandler_whenNoProxiedDelegate_andIOSVersion9OrHigher() {
        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.app"]
        
        mparticle.open(url, options: options)
        
        XCTAssertTrue(appNotificationHandler.openURLWithOptionsCalled)
        XCTAssertEqual(appNotificationHandler.openURLWithOptionsURLParam, url)
        XCTAssertEqual(appNotificationHandler.openURLWithOptionsOptionsParam?["UIApplicationOpenURLOptionsSourceApplicationKey"] as? String, "com.example.app")
    }
    
    func testOpenURLOptions_doesNothing_whenProxiedDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")
        
        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.app"]
        mparticle.open(url, options: options)

        XCTAssertFalse(appNotificationHandler.openURLWithOptionsCalled)
    }

    func testOpenURLOptions_doesNothing_whenSystemVersionBelow9() {
        let currentDevice = UIDevice.current
        let origSelector = NSSelectorFromString("systemVersion")
        let mockedVersion: @convention(block) () -> String = { "8.4" }
        let imp = imp_implementationWithBlock(mockedVersion)
        class_replaceMethod(object_getClass(currentDevice), origSelector, imp, "@@:")
        
        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": "com.example.app"]
        mparticle.open(url, options: options)
        
        XCTAssertFalse(appNotificationHandler.openURLWithOptionsCalled)
    }
    
    func testContinueUserActivity_returnsFalseAndDoesNotCallHandler_whenProxiedDelegateExists() {
        mparticle.setValue(NSNumber(value: true), forKey: "proxiedAppDelegate")

        let activity = NSUserActivity(activityType: "com.example.test")
        
        let result = mparticle.continue(activity) { _ in }

        XCTAssertFalse(result)
        XCTAssertFalse(appNotificationHandler.continueUserActivityCalled)
    }

    func testContinueUserActivity_returnsFalse_whenHandlerReturnsFalse() {
        let activity = NSUserActivity(activityType: "com.example.test")
        appNotificationHandler.continueUserActivityReturnValue = false

        let result = mparticle.continue(activity) { _ in }
        
        XCTAssertTrue(appNotificationHandler.continueUserActivityCalled)
        XCTAssertNotNil(appNotificationHandler.continueUserActivityRestorationHandlerParam)
        XCTAssertEqual(appNotificationHandler.continueUserActivityUserActivityParam, activity)
        XCTAssertFalse(result)
    }
}
