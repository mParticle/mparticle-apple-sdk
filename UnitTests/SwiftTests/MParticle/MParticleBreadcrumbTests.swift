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
    
    func test_leaveBreadcrumbCallback_forwardsEvent_whenDataFilterIsNil() {
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
    
    func test_leaveBreadcrumbCallback_blocksEvent_whenFilterReturnsNil() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .success)
        
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertTrue(dataPlanFilter.transformEventEventParam === event)
        
        assertReceivedMessage("Blocked breadcrumb event from kits", event: event)
    }
    
    func test_leaveBreadcrumbCallback_doesNotLog_whenExecStatusFail() {
        mparticle.leaveBreadcrumbCallback(event, execStatus: .fail)
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_leaveBreadcrumb_passesEventName_toBackendController() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.eventWithNameEventNameParam, event.name)
    }
    
    func test_leaveBreadcrumb_createsNewEvent_whenNoExistingEventFound() {
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.name, event.name)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.type, .other)
        XCTAssertNotNil(backendController.leaveBreadcrumbEventParam?.timestamp)
        XCTAssertEqual(
            backendController.leaveBreadcrumbEventParam!.customAttributes! as NSObject,
            event.customAttributes! as NSObject
        )
        XCTAssertNotNil(backendController.leaveBreadcrumbCompletionHandler)
    }
    
    func test_leaveBreadcrumb_updatesExistingEvent_whenEventAlreadyExists() {
        backendController.eventSet?.add(event as Any)
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.name, event.name)
        XCTAssertEqual(backendController.leaveBreadcrumbEventParam?.type, .other)
        XCTAssertNotNil(backendController.leaveBreadcrumbEventParam?.timestamp)
        XCTAssertEqual(
            backendController.leaveBreadcrumbEventParam!.customAttributes! as NSObject,
            event.customAttributes! as NSObject
        )
        XCTAssertNotNil(backendController.leaveBreadcrumbCompletionHandler)
    }
    
    func test_leaveBreadcrumb_invokesCallback_andLogsMessage() {
        mparticle.dataPlanFilter = nil
        mparticle.leaveBreadcrumb(event.name, eventInfo: event.customAttributes)
        backendController.leaveBreadcrumbCompletionHandler?(event, .success)
        assertReceivedMessage("Left breadcrumb", event: event)
        
    }
}
