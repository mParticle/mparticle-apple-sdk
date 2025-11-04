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
    
    func test_logEvent_callsLogCustomEvent() {
        mparticle.logEvent(event)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCustomEvent:")
    }
    
    func test_logEvent_callsLogCommerceEvent() {
        mparticle.logEvent(commerceEvent)
        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logCommerceEvent:")
    }
    
    func test_logEvent_blocksEvent_whenFilterReturnsNil() {
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
    
    func test_logEvent_forwardsTransformedEvent_whenFilterReturnsEvent() {
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
    
    func test_logEventCallback_doesNotLogMessage_whenDataFilterIsNil() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        mparticle.logEventCallback(event, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_logEventCallback_blocksEvent_whenFilterReturnsNil() {
        mparticle.logEventCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        
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
}
