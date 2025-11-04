//
//  MParticleSessionTests.swift
//  mParticle-Apple-SDK
//
//  Created by Nick Dimitrakas on 11/3/25.
//

import Foundation

import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

final class MParticleSessionTests: MParticleTestBase {
    
    func test_beginSession_doesNotCreateTempSession_whenTempSessionExists() {
        backendController.session = nil
        backendController.tempSessionReturnValue = MParticleSession()
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func test_beginSession_doesNotCreateTempSession_whenSessionExists() {
        backendController.session = MPSession()
        backendController.tempSessionReturnValue = nil
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func test_beginSession_createsAndBeginsSession_whenNoSessionExists() {
        backendController.session = nil
        backendController.tempSessionReturnValue = nil
        mparticle.beginSession()
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(backendController.createTempSessionCalled)
        XCTAssertTrue(backendController.beginSessionCalled)
        XCTAssertEqual(backendController.beginSessionIsManualParam, true)
        XCTAssertNotNil(backendController.beginSessionDateParam)
    }
    
    func test_endSession_doesNothing_whenNoActiveSession() {
        backendController.session = nil
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertFalse(backendController.endSessionWithIsManualCalled)
    }
    
    func test_endSession_endsActiveSession_whenSessionExists() {
        backendController.session = MPSession()
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertTrue(backendController.endSessionWithIsManualCalled)
        XCTAssertEqual(backendController.endSessionIsManualParam, true)
    }
    
    func test_sessionDidBegin_forwardsCall_toKitContainer() {
        kitContainer.forwardSDKCallExpectation = XCTestExpectation()
        mparticle.sessionDidBegin(MPSession())
        
        wait(for: [kitContainer.forwardSDKCallExpectation!], timeout: 1.0)
        
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "beginSession")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .sessionStart)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func test_sessionDidEnd_forwardsCall_toKitContainer() {
        kitContainer.forwardSDKCallExpectation = XCTestExpectation()
        mparticle.sessionDidEnd(MPSession())
        
        wait(for: [kitContainer.forwardSDKCallExpectation!], timeout: 1.0)
        
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "endSession")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .sessionEnd)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
}
