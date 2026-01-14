//
//  MParticleRuntimeValuesTests.swift
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

final class MParticleRuntimeValuesTests: MParticleTestBase {
    
    func test_setOptOutCompletion_logsMessage_onSuccess() {
        mparticle.setOptOutCompletion(.success, optOut: true)
        assertReceivedMessage("Set Opt Out: 1")
    }
    
    func test_setOptOutCompletion_logsError_onFailure() {
        mparticle.setOptOutCompletion(.fail, optOut: true)
        assertReceivedMessage("Set Opt Out Failed: 1")
    }
    
    func test_identity_returnsSameInstance() {
        let identity = mparticle.identity
        XCTAssertTrue(identity === mparticle.identity)
    }
    
    func test_rokt_returnsSameInstance() {
        let rokt = mparticle.rokt
        XCTAssertTrue(rokt === mparticle.rokt)
    }
    
    func test_sessionTimeout_returnsValue_fromBackendController() {
        mparticle.backendController.sessionTimeout = 100
        XCTAssertEqual(mparticle.sessionTimeout, 100)
    }
    
    func test_uniqueIdentifier_returnsValue_fromStateMachine() {
        state.consumerInfo.uniqueIdentifier = "test"
        XCTAssertEqual(mparticle.uniqueIdentifier, "test")
    }
    
    func test_setUploadInterval_updatesBackend_whenValueGreaterThanOne() {
        mparticle.setUploadInterval(3)
        XCTAssertEqual(backendController.uploadInterval, 3)
    }
    
    func test_setUploadInterval_doesNotUpdateBackend_whenValueLessThanOne() {
        mparticle.setUploadInterval(0.1)
        XCTAssertEqual(backendController.uploadInterval, 0.0)
    }
    
    func test_uploadInterval_returnsValue_fromBackendController() {
        backendController.uploadInterval = 100
        XCTAssertEqual(mparticle.uploadInterval, 100)
    }
    
    func test_userAttributes_fetchesFromBackend_forUserId() {
        backendController.userAttributesReturnValue = ["key": "value"]
        let dictionary = mparticle.userAttributes(forUserId: 1)
        XCTAssertEqual(dictionary?["key"] as? String, "value")
        XCTAssertTrue(backendController.userAttributesCalled)
        XCTAssertEqual(backendController.userAttributesUserIdParam, 1)
    }
    
    func test_optOut_updatesState_andNotifiesBackend() {
        XCTAssertFalse(state.optOut)
        
        mparticle.optOut = true
        
        XCTAssertTrue(state.optOut)
        XCTAssertTrue(backendController.setOptOutCalled)
        XCTAssertEqual(backendController.setOptOutOptOutStatusParam, true)
        XCTAssertNotNil(backendController.setOptOutCompletionHandler)
        backendController.setOptOutCompletionHandler?(true, .success)
    }
}
