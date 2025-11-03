//
//  MParticleBreadcrumbTests.swift
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

final class MParticleBreadcrumbTests: MParticleTestBase {
    
    func testLeaveBreadcrumbCallback_withDataFilterNotSet_forwardsTransformedEvent() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.leaveBreadcrumbCallback(event, execStatus: .success)
        
        // Verify executor usage
        XCTAssertTrue(executor.executeOnMainAsync)
        
        // Verify kit container forwarded transformed event
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "leaveBreadcrumb:")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .breadcrumb)
        XCTAssertNotNil(kitContainer.forwardSDKCallEventParam)
        
        assertReceivedMessage("Left breadcrumb", event: event)
    }
    
    func testLeaveBreadcrumbCallback_withDataFilterSet_andDataFilterReturnNil() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        assertReceivedMessage("Blocked breadcrumb event from kits", event: event)
    }
    
    func testLeaveBreadcrumbCallback_execStatusFail_noLoggedMessages() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .fail)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_backendControllerReceiveCorrectName() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_backendControllerReturnsNilEvent_newEventCreated() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.name, event.name)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.type, .other)
        XCTAssertNotNil(backendController.leaveBreadcrumbEventParam?.timestamp)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam!.customAttributes! as NSObject, event.customAttributes! as NSObject)
        XCTAssertNotNil(backendController.leaveBreadcrumbCompletionHandler)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_backendControllerReturnsEvent_eventModified() {
        backendController.eventSet?.add(event as Any)
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.name, event.name)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.type, .other)
        XCTAssertNotNil(backendController.leaveBreadcrumbEventParam?.timestamp)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam!.customAttributes! as NSObject, event.customAttributes! as NSObject)
        XCTAssertNotNil(backendController.leaveBreadcrumbCompletionHandler)
    }
    
    func testLeaveBreadcrumb_eventNamePassed_CallbackCallsCallbackFunction() {
        mparticle.dataPlanFilter = nil
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        backendController.leaveBreadcrumbCompletionHandler?(event, .success)
        assertReceivedMessage("Left breadcrumb", event: event)
        
    }
}
