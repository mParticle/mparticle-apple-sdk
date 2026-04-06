import XCTest
import mParticle_Apple_SDK

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
        XCTAssertTrue(backendController.beginTimedEventCalled)
        XCTAssertEqual(backendController.beginTimedEventEventParam, event)
        XCTAssertNotNil(backendController.beginTimedEventCompletionHandler)
        backendController.beginTimedEventCompletionHandler?(event, .success)
        XCTAssertNotNil(receivedMessage)
    }
    
    func test_endTimedEvent_invokesDependencies_andExecutesCompletionHandler() {
        dataPlanFilter.transformEventReturnValue = transformedEvent

        mparticle.endTimedEvent(event)

        XCTAssertNil(event.duration)
        XCTAssertNil(event.endTime)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)

        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)
        backendController.logEventCompletionHandler?(event, .success)
    }
    
    func test_endTimedEvent_blocksEvent_whenTransformEventReturnsNil() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.endTimedEvent(event)
        
        XCTAssertNil(event.duration)
        XCTAssertNil(event.endTime)

        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        
        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)
        backendController.logEventCompletionHandler?(event, .success)
    }
    
    func test_endTimedEvent_forwardsOriginalEvent_whenDataPlanFilterIsNil() {
        dataPlanFilter = nil
        mparticle.dataPlanFilter = dataPlanFilter
        
        mparticle.endTimedEvent(event)
        
        XCTAssertNil(event.duration)
        XCTAssertNil(event.endTime)
        
        XCTAssertTrue(backendController.logEventCalled)
        XCTAssertTrue(backendController.logEventEventParam === event)
        XCTAssertNotNil(backendController.logEventCompletionHandler)
        backendController.logEventCompletionHandler?(event, .success)
    }
}
