import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class MParticleTestsSwift: XCTestCase {
    var receivedMessage: String?
    var mparticle: MParticle!
    var listenerController: MPListenerControllerMock!
    
    func customLogger(_ message: String) {
        receivedMessage = message
    }
    
    override func setUp() {
        super.setUp()
        
        mparticle = MParticle()
        mparticle.logLevel = .verbose
        mparticle.customLogger = customLogger
        listenerController = MPListenerControllerMock()
        listenerController.onAPICalledExpectation = XCTestExpectation()
        mparticle.listenerController = listenerController
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
        let backendController = MPBackendControllerMock()
        let state = MPStateMachineMock()
        mparticle.backendController = backendController
        mparticle.stateMachine = state
        XCTAssertFalse(state.optOut)
        mparticle.optOut = true
        XCTAssertTrue(state.optOut)
        XCTAssertTrue(backendController.setOptOutCalled)
        XCTAssertEqual(backendController.setOptOutOptOutStatusParam, true)
        XCTAssertNotNil(backendController.setOptOutCompletionHandler)
        backendController.setOptOutCompletionHandler?(true, .success)
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
        
        wait(for: [expectation], timeout: 1.0)
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
        
        mparticle.start(withKeyCallback: false, options: options, userDefaults: userDefaults as! MPUserDefaultsProtocol)
        
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
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === expectedEvent)
        XCTAssertEqual(receivedMessage, """
            mParticle -> Blocked timed event begin from kits: Event:{
              Name: <<Event With No Name>>
              Type: Other\n  Duration: 0
            }
            """
        )
    }
       
    func testLogEventCallbackDataFilterNotSet() {
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logEventCallback(MPEvent(), execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogEventCallbackDataFilterSetDataFilterReturnNil() {
        let dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter
        let expectedEvent = MPEvent()
        mparticle.logEventCallback(expectedEvent, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === expectedEvent)

        XCTAssertEqual(receivedMessage, """
            mParticle -> Blocked timed event end from kits: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
    }

    func testLogScreenCallbackDataFilterNotSet() {
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logScreenCallback(MPEvent(), execStatus: .success)
        
        XCTAssertEqual(receivedMessage, """
            mParticle -> Logged screen event: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
    }
    
    func testLogScreenCallbackDataFilterSetDataFilterReturnNil() {
        let dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter
        let expectedEvent = MPEvent()
        mparticle.logScreenCallback(expectedEvent, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventScreenEventParam === expectedEvent)

        XCTAssertEqual(receivedMessage, """
            mParticle -> Blocked screen event from kits: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
    }

    func testLeaveBreadcrumbCallbackDataFilterNotSet() {
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.leaveBreadcrumbCallback(MPEvent(), execStatus: .success)
        
        XCTAssertEqual(receivedMessage, """
            mParticle -> Left breadcrumb: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
    }
    
    func testLeaveBreadcrumbCallbackDataFilterSetDataFilterReturnNil() {
        let dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter
        let expectedEvent = MPEvent()
        mparticle.leaveBreadcrumbCallback(expectedEvent, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === expectedEvent)

        XCTAssertEqual(receivedMessage, """
            mParticle -> Blocked breadcrumb event from kits: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
    }

    func testLogErrorCallbackSuccess() {
        mparticle.logErrorCallback([:], execStatus: .success, message: "error")
        
        XCTAssertEqual(receivedMessage, """
            mParticle -> Logged error with message: error
            """
        )
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
            """
        )
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
        let commerceEvent = MPCommerceEvent()
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCommerceEventCallbackFail() {
        let commerceEvent = MPCommerceEvent()
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .fail)
        
        XCTAssertEqual(receivedMessage, """
            mParticle -> Failed to log commerce event: MPCommerceEvent {
            }
            
            """
        )
    }
    
    func testLogLTVIncreaseCallbackDataFilterNotSet() {
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logLTVIncreaseCallback(MPEvent(), execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }

    func testLogLTVIncreaseCallbackDataFilterSetDataFilterReturnNil() {
        let dataPlanFilter = MPDataPlanFilterMock()
        mparticle.dataPlanFilter = dataPlanFilter
        let expectedEvent = MPEvent()
        mparticle.logLTVIncreaseCallback(expectedEvent, execStatus: .success)
    
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === expectedEvent)
    
        XCTAssertEqual(receivedMessage, """
            mParticle -> Blocked LTV increase event from kits: Event:{
              Name: <<Event With No Name>>
              Type: Other
              Duration: 0
            }
            """
        )
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
        let expectedEvent = MPEvent()
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        mparticle.beginTimedEvent(expectedEvent)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "beginTimedEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedEvent)
        XCTAssertTrue(backendController.beginTimedEventCalled)
        XCTAssertTrue(backendController.beginTimedEventEventParam === expectedEvent)
        XCTAssertNotNil(backendController.beginTimedEventCompletionHandler)
        backendController.beginTimedEventCompletionHandler?(expectedEvent, .success)
        XCTAssertNotNil(receivedMessage)
    }
    
    func testEndTimedEventListenerControllerCalled() {
        let expectedEvent = MPEvent()
        mparticle.endTimedEvent(expectedEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "endTimedEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedEvent)
    }
    
    func testLogEventWithBaseEventListenerControllerCalled() {
        let expectedEvent = MPBaseEvent()
        mparticle.logEvent(expectedEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedEvent)
    }
    
    func testLogCustomEventListenerControllerCalled() {
        let expectedEvent = MPEvent()
        mparticle.logEvent(expectedEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedEvent)
    }
    
    func testLogScreenEventListenerControllerCalled() {
        let expectedEvent = MPEvent()
        mparticle.logScreenEvent(expectedEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logScreenEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedEvent)
    }
    
    func testLeaveBreadcrumbListenerControllerCalled() {
        mparticle.leaveBreadcrumb("expectedEvent", eventInfo: [:])
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "leaveBreadcrumb:eventInfo:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? String, "expectedEvent")
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? [String: String], [:])
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
        let expectedEvent = MPCommerceEvent()
        mparticle.logCommerceEvent(expectedEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === expectedEvent)
    }
    
    
    func testLogLTVIncreaseListenerControllerCalled() {
        mparticle.logLTVIncrease(2.0, eventName: "name", eventInfo: [:])
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logLTVIncrease:eventName:eventInfo:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? Double, 2.0)
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? String, "name")
        XCTAssertEqual(listenerController.onAPICalledParameter3 as? [String: String], [:])
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
        let expectedWebView = WKWebView()
        mparticle.initializeWKWebView(expectedWebView, bridgeName: "name")
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "initializeWKWebView:bridgeName:")
        XCTAssertNotNil(listenerController.onAPICalledParameter1)
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? String, "name")
    }
    
    func testLogNotificationOpenedWithUserInfoAndActionIdentifierListenerControllerCalled() {
        mparticle.logNotificationOpened(userInfo: [:], andActionIdentifier: "identifier")
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logNotificationOpenedWithUserInfo:andActionIdentifier:")
        XCTAssertEqual(listenerController.onAPICalledParameter1 as? [String:String], [:])
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
        XCTAssertEqual(listenerController.onAPICalledParameter2 as? [String:String], [:])
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
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "beginLocationTracking:minDistance:authorizationRequest:")
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
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logNetworkPerformance:httpMethod:startTime:duration:bytesSent:bytesReceived:")
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
        let kitContainer = MPKitContainerMock()
        kitContainer.forwardSDKCallExpectation = XCTestExpectation()
        mparticle.setKitContainer(kitContainer)
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
        let kitContainer = MPKitContainerMock()
        kitContainer.forwardSDKCallExpectation = XCTestExpectation()
        mparticle.setKitContainer(kitContainer)
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
        
        let kitContainer = MPKitContainerMock()
        
        let persistenceController = MPPersistenceControllerMock()
        
        let backendController = MPBackendControllerMock()
        
        mparticle.setKitContainer(kitContainer)
        mparticle.persistenceController = persistenceController
        mparticle.backendController = backendController
        
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
        let backendController = MPBackendControllerMock()
        backendController.session = nil
        backendController.tempSessionReturnValue = MParticleSession()
        mparticle.backendController = backendController
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func testBeginSessionSessionAvailableSessionTempSessionShouldNotBeCreated() {
        let backendController = MPBackendControllerMock()
        backendController.session = MPSession()
        backendController.tempSessionReturnValue = nil
        mparticle.backendController = backendController
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func testBeginSessionSessionUnavailable() {
        let backendController = MPBackendControllerMock()
        backendController.session = nil
        backendController.tempSessionReturnValue = nil
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        mparticle.backendController = backendController
        mparticle.beginSession()
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(backendController.createTempSessionCalled)
        XCTAssertTrue(backendController.beginSessionCalled)
        XCTAssertEqual(backendController.beginSessionIsManualParam, true)
        XCTAssertNotNil(backendController.beginSessionDateParam)
    }
    
    func testEndSessionNoSession() {
        let backendController = MPBackendControllerMock()
        backendController.session = nil
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        mparticle.backendController = backendController
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertFalse(backendController.endSessionWithIsManualCalled)
    }
    
    func testEndSessionWithSession() {
        let backendController = MPBackendControllerMock()
        backendController.session = MPSession()
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        mparticle.backendController = backendController
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertTrue(backendController.endSessionWithIsManualCalled)
        XCTAssertEqual(backendController.endSessionIsManualParam, true)
    }
    
    func testForwardLogInstall() {
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        let kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)
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
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        let kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)
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
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        mparticle.backendController.sessionTimeout = 100
        XCTAssertEqual(mparticle.sessionTimeout, 100)
    }
    
    func testUniqueIdentifierRwturnedFromStateMachine() {
        let stateMachine = MPStateMachineMock()
        stateMachine.consumerInfo.uniqueIdentifier = "test"
        mparticle.stateMachine = stateMachine
        XCTAssertEqual(mparticle.uniqueIdentifier, "test")
    }
    
    func testSetUploadIntervalChangeValueInBackendControllerWhenIntervalGreaterThenOne() {
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        mparticle.setUploadInterval(3)
        XCTAssertEqual(backendController.uploadInterval, 3)
    }
    
    func testSetUploadIntervalNotChangeValueInBackendControllerWhenIntervalLessThenOne() {
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        mparticle.setUploadInterval(0.1)
        XCTAssertEqual(backendController.uploadInterval, 0.0)
    }
    
    func testUploadIntervalGetFromBackendController() {
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        backendController.uploadInterval = 100
        XCTAssertEqual(mparticle.uploadInterval, 100)
    }
    
    func testUserAttributesForUserIdRequestDataFromBackendController() {
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        backendController.userAttributesReturnValue = ["key": "value"]
        let dictionary = mparticle.userAttributes(forUserId: 1)
        XCTAssertEqual(dictionary?["key"] as? String, "value")
        XCTAssertTrue(backendController.userAttributesCalled)
        XCTAssertEqual(backendController.userAttributesUserIdParam, 1)
    }
    
    func testConfigureWithOptionsNoSettings() {
        let backendController = MPBackendControllerMock()
        let settingsProvider = SettingsProviderMock()
        mparticle.settingsProvider = settingsProvider
        mparticle.backendController = backendController
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
        let backendController = MPBackendControllerMock()
        let settingsProvider = SettingsProviderMock()
        mparticle.settingsProvider = settingsProvider
        settingsProvider.configSettings = [
            "session_timeout": 100,
            "upload_interval": 50,
            "custom_user_agent": "agent",
            "collect_user_agent": false,
            "track_notifications": false,
            "enable_location_tracking": true
        ]
        mparticle.backendController = backendController
        let options = MParticleOptions()
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
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "beginLocationTracking:minDistance:authorizationRequest:")
#endif
#endif
    }
    
    // MARK: - logEvent
    func testLogEventCalledLogCustomEvent() {
        let event = MPEvent(name: "test", type: .other)!
        mparticle.logEvent(event)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
    }
    
    func testLogEventCalledLogCommerceEvent() {
        let commerceEvent = MPCommerceEvent(action: .purchase)!
        mparticle.logEvent(commerceEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
    }
    
    func testLogEventWithFilterReturningNil_blocksEvent() {
        let event = MPBaseEvent(eventType: .other)!
        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        let dataPlanFilter = MPDataPlanFilterMock()
        dataPlanFilter.transformEventForBaseEventReturnValue = nil
        mparticle.dataPlanFilter = dataPlanFilter
        
        mparticle.logEvent(event)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logBaseEventCalled)
        XCTAssertTrue(backendController.logBaseEventEventParam === event)
        let completion = backendController.logBaseEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(event, .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        // Verify filter transform event
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventParam === event)
        
        // Logger should record the blocked event message
        XCTAssertEqual(receivedMessage, "mParticle -> Blocked base event from kits: \(event)")
    }
    
    func testLogBaseEventWithFilterReturningEvent_forwardsTransformedEvent() {
        let event = MPBaseEvent(eventType: .other)!
        let transformedEvent = MPBaseEvent(eventType: .addToCart)!
        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        let dataPlanFilter = MPDataPlanFilterMock()
        dataPlanFilter.transformEventForBaseEventReturnValue = transformedEvent
        mparticle.dataPlanFilter = dataPlanFilter
        
        let kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)
        
        mparticle.logEvent(event)
        
        // Verify listener was called
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        // Verify backend was called
        XCTAssertTrue(backendController.logBaseEventCalled)
        XCTAssertTrue(backendController.logBaseEventEventParam === event)
        let completion = backendController.logBaseEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(event, .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify filter transformed event
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventForBaseEventParam === event)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logBaseEvent:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertTrue(kitContainer.forwardSDKCallEventParam === transformedEvent)
    }
    
    
    // MARK: - logCustomEvent
    
    func testLogCustomEventWithNilEvent_logsError() {
        mparticle.logCustomEvent(nil)
        XCTAssertEqual(receivedMessage, "mParticle -> Cannot log nil event!")
    }
    
    func testLogCustomEventWithFilterReturningNil_blocksEvent() {
        let event = MPEvent(name: "blocked", type: .other)!
        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        let dataPlanFilter = MPDataPlanFilterMock()
        dataPlanFilter.transformEventReturnValue = nil
        mparticle.dataPlanFilter = dataPlanFilter
        
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
        let event = MPEvent(name: "original", type: .other)!
        let transformedEvent = MPEvent(name: "transformed", type: .other)!
        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        let dataPlanFilter = MPDataPlanFilterMock()
        dataPlanFilter.transformEventReturnValue = transformedEvent
        mparticle.dataPlanFilter = dataPlanFilter
        
        let kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)
        
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
    
    // MARK: - logCommerceEvent
    
    func testLogCommerceEventWithNilCommerceEvent_logsError() {
        mparticle.logCommerceEvent(nil)
        XCTAssertEqual(receivedMessage, "mParticle -> Cannot log nil commerce event!")
    }
    
    func testLogCommerceEvent_assignsTimestampWhenNil() {
        let commerceEvent = MPCommerceEvent(action: .purchase)!
        commerceEvent.setTimestamp(nil)

        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        mparticle.logCommerceEvent(commerceEvent)
        
        XCTAssertNotNil(commerceEvent.timestamp)
        XCTAssertTrue(backendController.logCommerceEventCalled)
        XCTAssertTrue(listenerController.onAPICalledParameter1 === commerceEvent)
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
    }

    
    func testLogCommerceEventWithFilterReturningNil_blocksEvent() {
        let commerceEvent = MPCommerceEvent(eventType: .other)!
        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        let dataPlanFilter = MPDataPlanFilterMock()
        dataPlanFilter.transformEventForCommerceEventParam = nil
        mparticle.dataPlanFilter = dataPlanFilter
        
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
        let commerceEvent = MPCommerceEvent(eventType: .other)!
        let transformedCommerceEvent = MPCommerceEvent(eventType: .viewDetail)!
        
        let executor = ExecutorMock()
        mparticle.setExecutor(executor)
        
        let backendController = MPBackendControllerMock()
        mparticle.backendController = backendController
        
        let dataPlanFilter = MPDataPlanFilterMock()
        dataPlanFilter.transformEventForCommerceEventReturnValue = transformedCommerceEvent
        mparticle.dataPlanFilter = dataPlanFilter
        
        let kitContainer = MPKitContainerMock()
        mparticle.setKitContainer(kitContainer)
        
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

}
