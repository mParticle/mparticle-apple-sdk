//
//  MParticleCommerceEventTests.swift
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

@available(*, deprecated, message: "Used only for testing deprecated APIs")
final class MParticleCommerceEventTests: MParticleTestBase {
    
    func test_logCommerceEvent_assignsTimestampIfMissing() {
        commerceEvent.setTimestamp(nil)
        
        mparticle.logCommerceEvent(commerceEvent)
        
        XCTAssertNotNil(commerceEvent.timestamp)
        XCTAssertTrue(backendController.logCommerceEventCalled)
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
    }
    
    func test_logCommerceEvent_blocksEvent_whenFilterReturnsNil() {
        dataPlanFilter.transformEventForCommerceEventParam = nil
        
        mparticle.logCommerceEvent(commerceEvent)
        
        // Verify event timestamp added
        XCTAssertNotNil(commerceEvent.timestamp)
        
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
    
    func test_logCommerceEvent_forwardsTransformedEvent_whenFilterReturnsEvent() {
        dataPlanFilter.transformEventForCommerceEventReturnValue = transformedCommerceEvent
        
        mparticle.logCommerceEvent(commerceEvent)
        
        // Verify event timestamp added
        XCTAssertNotNil(commerceEvent.timestamp)
        
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
    
    func test_logCommerceEventCallback_doesNotLogMessage_onSuccess() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_logCommerceEventCallback_logsError_onFailure() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .fail)
        
        assertReceivedMessage("Failed to log commerce event", event: commerceEvent)
    }
}
