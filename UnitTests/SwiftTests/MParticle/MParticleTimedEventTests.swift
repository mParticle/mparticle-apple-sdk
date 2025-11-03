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
}
