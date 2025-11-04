//
//  MParticleTimedEventTests.swift
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

final class MParticleTimedEventTests: MParticleTestBase {
    
    func test_beginTimedEventCompletionHandler_logsMessage_whenDataFilterIsNil() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        assertReceivedMessage("Began timed event", event: event)
    }
    
    func test_beginTimedEventCompletionHandler_blocksEvent_whenFilterReturnsNil() {
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        assertReceivedMessage("Blocked timed event begin from kits", event: event)
    }
    
    func test_beginTimedEvent_invokesDependencies_andExecutesCompletionHandler() {
        mparticle.beginTimedEvent(event)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "beginTimedEvent:")
        XCTAssertEqual(listenerController.onAPICalledParameter1, event)
        XCTAssertTrue(backendController.beginTimedEventCalled)
        XCTAssertEqual(backendController.beginTimedEventEventParam, event)
        XCTAssertNotNil(backendController.beginTimedEventCompletionHandler)
        backendController.beginTimedEventCompletionHandler?(event, .success)
        XCTAssertNotNil(receivedMessage)
    }
    
    func test_endTimedEvent_invokesDependencies_andExecutesCompletionHandler() {
        dataPlanFilter.transformEventReturnValue = transformedEvent

        mparticle.endTimedEvent(event)

        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)

        XCTAssertNil(event.duration)
        XCTAssertNil(event.endTime)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "endTimedEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)

        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)

        backendController.logEventCompletionHandler?(event, .success)

        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        XCTAssertTrue(executor.executeOnMainAsync)

        XCTAssertEqual(kitContainer.forwardSDKCalls.count, 2)

        let expectedSelectors = ["endTimedEvent:", "logEvent:"]
        let actualSelectors = kitContainer.forwardSDKCalls.map { $0.selector.description }
        XCTAssertEqual(actualSelectors, expectedSelectors)

        for call in kitContainer.forwardSDKCalls {
            XCTAssertTrue(call.event === transformedEvent)
            XCTAssertNil(call.parameters)
            XCTAssertEqual(call.messageType, .event)
            XCTAssertNil(call.userInfo)
        }

        XCTAssertNil(receivedMessage)
    }
    
    func test_endTimedEvent_blocksEvent_whenTransformEventReturnsNil() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.endTimedEvent(event)

        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        
        XCTAssertNil(event.duration)
        XCTAssertNil(event.endTime)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "endTimedEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)

        backendController.logEventCompletionHandler?(event, .success)

        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)

        XCTAssertFalse(executor.executeOnMainAsync)
        XCTAssertFalse(kitContainer.forwardSDKCallCalled)
        XCTAssertTrue(kitContainer.forwardSDKCalls.isEmpty)

        assertReceivedMessage("Blocked timed event end from kits", event: event)
    }
    
    func test_endTimedEvent_forwardsOriginalEvent_whenDataPlanFilterIsNil() {
        dataPlanFilter = nil
        mparticle.dataPlanFilter = dataPlanFilter
        
        mparticle.endTimedEvent(event)

        wait(for: [listenerController.onAPICalledExpectation!], timeout: 0.1)
        
        XCTAssertNil(event.duration)
        XCTAssertNil(event.endTime)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "endTimedEvent:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === event)
        
        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)

        backendController.logEventCompletionHandler?(event, .success)

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

        XCTAssertNil(receivedMessage)
    }

}
