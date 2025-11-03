import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MParticleTestsSwift: MParticleTestBase {
    
    func testBeginTimedEventCompletionHandlerDataFilterNotSet() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        assertReceivedMessage("Began timed event", event: event)
    }
    
    func testBeginTimedEventCompletionHandlerDataFilterSetDataFilterReturnNil() {
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        assertReceivedMessage("Blocked timed event begin from kits", event: event)
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
        
        assertReceivedMessage("Blocked timed event end from kits", event: event)
    }
    
    func testLogScreenCallbackDataFilterNotSet() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logScreenCallback(event, execStatus: .success)
        
        assertReceivedMessage("Logged screen event", event: event)
    }
    
    func testLogScreenCallbackDataFilterSetDataFilterReturnNil() {
        mparticle.logScreenCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventForScreenEventScreenEventParam, event)
        
        assertReceivedMessage("Blocked screen event from kits", event: event)
        
    }
    
    func testLogErrorCallbackSuccess() {
        mparticle.logErrorCallback([:], execStatus: .success, message: "error")
        
        assertReceivedMessage("Logged error with message: error")
    }
    
    func testLogErrorCallbackFail() {
        mparticle.logErrorCallback([:], execStatus: .fail, message: "error")
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogExceptionCallbackSuccess() {
        mparticle.logExceptionCallback(exception, execStatus: .success, message: "exception", topmostContext: nil)
        
        assertReceivedMessage("Logged exception name: exception, reason: Test, topmost context: (null)")
    }
    
    func testLogExceptionCallbackFail() {
        mparticle.logExceptionCallback(exception, execStatus: .fail, message: "exception", topmostContext: nil)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCrashCallbackSuccess() {
        mparticle.logCrashCallback(.success, message: "Message")
        assertReceivedMessage("Logged crash with message: Message")
    }
    
    func testLogCommerceEventCallbackSuccess() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCommerceEventCallbackFail() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .fail)
        
        assertReceivedMessage("Failed to log commerce event", event: commerceEvent)
    }
    
    func testLogNetworkPerformanceCallbackSuccess() {
        mparticle.logNetworkPerformanceCallback(.success)
        
        assertReceivedMessage("Logged network performance measurement")
    }
    
    func testLogNetworkPerformanceCallbackFail() {
        mparticle.logNetworkPerformanceCallback(.fail)
        
        XCTAssertNil(receivedMessage)
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
        assertReceivedMessage("Blocked base event from kits", event: baseEvent)
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
        assertReceivedMessage("Cannot log nil event!")
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
        assertReceivedMessage("Blocked custom event from kits", event: event)
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
        
        assertReceivedMessage("Blocked screen event from kits", event: event)
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
        
        assertReceivedMessage("Logged screen event", event: event)
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
        
        assertReceivedMessage("Screen name is required.")
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
        
        assertReceivedMessage("Logged screen event", event: event)
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
        
        assertReceivedMessage("Logged screen event", event: mockMPNavEvent)
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

        assertReceivedMessage("Cannot log nil batch!")
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
        XCTAssertEqual(kit.logBatchParam?["events"] as? [[String: Int]],
                       LogKitBatchData.parsedSingleEvent.values.first as? [[String : Int]])
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
        assertReceivedMessage("Blocked commerce event from kits", event: commerceEvent)
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
        
        assertReceivedMessage("Blocked LTV increase event from kits", event: event)
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
        
        assertReceivedMessage("Left breadcrumb", event: event)
    }
    
    func testLeaveBreadcrumbCallback_withDataFilterSet_andDataFilterReturnNil() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        assertReceivedMessage("Blocked breadcrumb event from kits", event: event)
    }
    
    func testLeaveBreadcrumbCallback_execStatusFail_noLoggedMessages() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .fail)
        
        XCTAssertNil(receivedMessage)
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
        assertReceivedMessage("Left breadcrumb", event: event)
        
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
