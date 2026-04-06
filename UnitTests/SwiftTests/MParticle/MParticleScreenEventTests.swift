import XCTest
import mParticle_Apple_SDK

final class MParticleScreenEventTests: MParticleTestBase {
    
    func test_logScreenEvent_blocksEvent_whenFilterReturnsNil() {
        mparticle.logScreenEvent(event)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        XCTAssertTrue(backendController.logScreenCalled)
        XCTAssertTrue(backendController.logScreenEventParam === event)
        XCTAssertNotNil(backendController.logScreenCompletionHandler)
        
        backendController.logScreenCompletionHandler?(event, .success)
        
        assertReceivedMessage("Blocked screen event from kits", event: event)
    }
    
    func test_logScreenEvent_executesFullFlow_whenFilterReturnsEvent() {
        dataPlanFilter.transformEventForScreenEventReturnValue = event
        
        mparticle.logScreenEvent(event)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
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
    
    func test_logScreen_logsError_andReturns_whenScreenNameIsEmpty() {
        mparticle.logScreen("", eventInfo: event.customAttributes)
        
        assertReceivedMessage("Screen name is required.")
        XCTAssertFalse(backendController.eventWithNameCalled)
        XCTAssertFalse(executor.executeOnMessageQueueAsync)
        XCTAssertFalse(backendController.logScreenCalled)
    }
    
    func test_logScreen_callsLogScreenEvent_whenEventExists() {
        backendController.eventWithNameReturnValue = event
        dataPlanFilter.transformEventForScreenEventReturnValue = event
        
        mparticle.logScreen(event.name, eventInfo: event.customAttributes)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, testName)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
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
    
    func test_logScreen_createsNavigationEvent_whenNoExistingEventFound() {
        backendController.eventWithNameReturnValue = nil
        let mockMPNavEvent = MPEvent(name: testName, type: .navigation)!
        mockMPNavEvent.customAttributes = keyValueDict
        mockMPNavEvent.shouldUploadEvent = true
        
        dataPlanFilter.transformEventForScreenEventReturnValue = mockMPNavEvent
        
        mparticle.logScreen(testName, eventInfo: keyValueDict, shouldUploadEvent: true)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, testName)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
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
    
    func test_logScreenCallback_logsMessage_whenDataFilterIsNil() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logScreenCallback(event, execStatus: .success)
        
        assertReceivedMessage("Logged screen event", event: event)
    }
    
    func test_logScreenCallback_blocksEvent_whenFilterReturnsNil() {
        mparticle.logScreenCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventForScreenEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventForScreenEventScreenEventParam, event)
        
        assertReceivedMessage("Blocked screen event from kits", event: event)
        
    }
}
