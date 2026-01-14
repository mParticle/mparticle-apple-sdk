//
//  MParticleEventTests.swift
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

final class MParticleEventTests: MParticleTestBase {
    
    func test_logEvent_blocksEvent_whenFilterReturnsNil() {
        dataPlanFilter.transformEventForBaseEventReturnValue = nil
        
        mparticle.logEvent(baseEvent)
        
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
    
    func test_logEvent_forwardsTransformedEvent_whenFilterReturnsEvent() {
        dataPlanFilter.transformEventForBaseEventReturnValue = transformedBaseEvent
        
        mparticle.logEvent(baseEvent)
        
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
    
    func test_logEventCallback_doesNothing_whenExecStatusIsFail() {
        mparticle.logEventCallback(event, execStatus: .fail)
        
        XCTAssertFalse(dataPlanFilter.transformEventCalled)
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_logEventCallback_invokesKitContainer_whenDataPlanFilterIsNil() {
        dataPlanFilter = nil
        mparticle.dataPlanFilter = dataPlanFilter
        
        mparticle.logEventCallback(event, execStatus: .success)
        
        XCTAssertTrue(executor.executeOnMainAsync)

        XCTAssertEqual(kitContainer.forwardSDKCalls.count, 2)
        let expectedSelectors = ["endTimedEvent:", "logEvent:"]
        let actualSelectors = kitContainer.forwardSDKCalls.map { $0.selector.description }
        XCTAssertEqual(actualSelectors, expectedSelectors)

        for call in kitContainer.forwardSDKCalls {
            XCTAssertTrue(call.event === event)
            XCTAssertNil(call.parameters)
            XCTAssertEqual(call.messageType, .event)
            XCTAssertNil(call.userInfo)
        }
    }
    
    func test_logEventCallback_blocksEvent_whenFilterReturnsNil() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.logEventCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        
        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        
        assertReceivedMessage("Blocked timed event end from kits", event: event)
    }
    
    func test_eventWithName_returnsEvent_whenBackendProvidesEvent() {
        backendController.eventWithNameReturnValue = event
        
        let result = mparticle.event(withName: event.name)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
        XCTAssertTrue(result === event)
    }
    
    func test_eventWithName_returnsNil_whenBackendReturnsNil() {
        backendController.eventWithNameReturnValue = nil
        
        let result = mparticle.event(withName: event.name)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
        XCTAssertNil(result)
    }
    
    func test_logEvent_usesExistingEvent_andUpdatesTypeAndAttributes() {
        backendController.eventWithNameReturnValue = event
        
        mparticle.logEvent(event.name, eventType: event.type, eventInfo: event.customAttributes)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
    }

    func test_logEvent_createsNewEvent_whenNotFound() {
        backendController.eventWithNameReturnValue = nil
        
        mparticle.logEvent(event.name, eventType: event.type, eventInfo: event.customAttributes)
        
        XCTAssertTrue(backendController.eventWithNameCalled)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
    }
}
