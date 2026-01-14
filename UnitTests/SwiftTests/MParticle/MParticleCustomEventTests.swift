//
//  MParticleCustomEventTests.swift
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

final class MParticleCustomEventTests: MParticleTestBase {
    
    func test_logCustomEvent_logsError_whenEventIsNil() {
        mparticle.logCustomEvent(nil)
        assertReceivedMessage("Cannot log nil event!")
    }
    
    func test_logCustomEvent_blocksEvent_whenFilterReturnsNil() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.logCustomEvent(event)
        
        // Verify event timing ended
        XCTAssertNil(event.endTime)
        
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
    
    func test_logCustomEvent_forwardsTransformedEvent_whenFilterReturnsEvent() {
        dataPlanFilter.transformEventReturnValue = transformedEvent
        
        mparticle.logCustomEvent(event)
        
        // Verify event timing ended
        XCTAssertNil(event.endTime)
        
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
}
