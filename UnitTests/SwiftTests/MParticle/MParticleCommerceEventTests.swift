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
    
    func testLogCommerceEventCallbackSuccess() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .success)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCommerceEventCallbackFail() {
        mparticle.logCommerceEventCallback(commerceEvent, execStatus: .fail)
        
        assertReceivedMessage("Failed to log commerce event", event: commerceEvent)
    }
}
