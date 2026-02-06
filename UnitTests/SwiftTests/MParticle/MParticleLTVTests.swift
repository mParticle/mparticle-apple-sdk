import XCTest
import mParticle_Apple_SDK

final class MParticleLTVTests: MParticleTestBase {
    
    func test_logLTVIncrease_createsTransactionEvent_andCallsBackend_whenEventInfoProvided() {
        let amount = 42.0
        let name = "name"
        let info: [String: Any] = ["source": "in_app", "currency": "USD"]
        
        mparticle.logLTVIncrease(amount, eventName: name, eventInfo: info)
        
        // Assert event was passed through
        let loggedEvent = backendController.logEventEventParam!
        XCTAssertNotNil(loggedEvent)
        XCTAssertEqual(loggedEvent.name, name)
        XCTAssertEqual(loggedEvent.type, .transaction)
        
        // Custom attributes should include amount and method name
        let attrs = loggedEvent.customAttributes!
        XCTAssertEqual(attrs["$Amount"] as? Double, amount)
        XCTAssertEqual(attrs["$MethodName"] as? String, "LogLTVIncrease")
        
        // Check that the eventInfo entries were added
        XCTAssertEqual(attrs["source"] as? String, "in_app")
        XCTAssertEqual(attrs["currency"] as? String, "USD")
        XCTAssertEqual(attrs.count, 4)
        
        // Backend completion handler should be stored
        XCTAssertTrue(backendController.logEventCalled)
        let completion = backendController.logEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(loggedEvent, .success)
    }
    
    func test_logLTVIncrease_createsTransactionEvent_withDefaultAttributes_whenEventInfoNil() {
        let amount = 12.5
        let name = "name"
        
        mparticle.logLTVIncrease(amount, eventName: name)
        
        // Assert event was passed through
        let loggedEvent = backendController.logEventEventParam!
        XCTAssertNotNil(loggedEvent)
        XCTAssertEqual(loggedEvent.name, name)
        XCTAssertEqual(loggedEvent.type, .transaction)
        
        // Custom attributes should only be amount and method name
        let attrs = loggedEvent.customAttributes!
        XCTAssertEqual(attrs["$Amount"] as? Double, amount)
        XCTAssertEqual(attrs["$MethodName"] as? String, "LogLTVIncrease")
        XCTAssertEqual(attrs.count, 2)
        
        // Backend completion handler should be stored
        XCTAssertTrue(backendController.logEventCalled)
        let completion = backendController.logEventCompletionHandler!
        XCTAssertNotNil(completion)
        completion(loggedEvent, .success)
    }
    
    func test_logLTVIncreaseCallback_blocksEvent_whenFilterReturnsNil() {
        dataPlanFilter.transformEventReturnValue = nil
        
        mparticle.logLTVIncreaseCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        assertReceivedMessage("Blocked LTV increase event from kits", event: event)
    }
    
    func test_logLTVIncreaseCallback_forwardsTransformedEvent_whenFilterReturnsEvent() {
        dataPlanFilter.transformEventReturnValue = transformedEvent
        
        mparticle.logLTVIncreaseCallback(event, execStatus: .success)
        
        // Verify filter transformed event
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "logLTVIncrease:event:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
    }
}
