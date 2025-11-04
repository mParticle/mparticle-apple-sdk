//
//  MParticleScreenEventTests.swift
//  mParticle-Apple-SDK
//
//  Created by Nick Dimitrakas on 11/3/25.
//

import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

final class MParticleScreenEventTests: MParticleTestBase {
    
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
}
