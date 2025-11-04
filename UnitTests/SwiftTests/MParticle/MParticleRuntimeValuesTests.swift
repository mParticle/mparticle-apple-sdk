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
    
    func testSetSharedInstance() {
        MParticle.setSharedInstance(mparticle)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "setSharedInstance:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 === mparticle)
    }
    
    func testSetOptOutCompletionSuccess() {
        mparticle.setOptOutCompletion(.success, optOut: true)
        assertReceivedMessage("Set Opt Out: 1")
    }
    
    func testSetOptOutCompletionFailure() {
        mparticle.setOptOutCompletion(.fail, optOut: true)
        assertReceivedMessage("Set Opt Out Failed: 1")
    }
    
    func testIndentityReturnsTheSameObject() {
        let identity = mparticle.identity
        XCTAssertTrue(identity === mparticle.identity)
    }
    
    func testRoktReturnsTheSameObject() {
        let rokt = mparticle.rokt
        XCTAssertTrue(rokt === mparticle.rokt)
    }
    
    func testSessionTimeoutReturnsValueFromBackendController() {
        mparticle.backendController.sessionTimeout = 100
        XCTAssertEqual(mparticle.sessionTimeout, 100)
    }
    
    func testUniqueIdentifierRwturnedFromStateMachine() {
        state.consumerInfo.uniqueIdentifier = "test"
        XCTAssertEqual(mparticle.uniqueIdentifier, "test")
    }
    
    func testSetUploadIntervalChangeValueInBackendControllerWhenIntervalGreaterThenOne() {
        mparticle.setUploadInterval(3)
        XCTAssertEqual(backendController.uploadInterval, 3)
    }
    
    func testSetUploadIntervalNotChangeValueInBackendControllerWhenIntervalLessThenOne() {
        mparticle.setUploadInterval(0.1)
        XCTAssertEqual(backendController.uploadInterval, 0.0)
    }
    
    func testUploadIntervalGetFromBackendController() {
        backendController.uploadInterval = 100
        XCTAssertEqual(mparticle.uploadInterval, 100)
    }
    
    func testUserAttributesForUserIdRequestDataFromBackendController() {
        backendController.userAttributesReturnValue = ["key": "value"]
        let dictionary = mparticle.userAttributes(forUserId: 1)
        XCTAssertEqual(dictionary?["key"] as? String, "value")
        XCTAssertTrue(backendController.userAttributesCalled)
        XCTAssertEqual(backendController.userAttributesUserIdParam, 1)
    }
    
    func testSetOptOutOptOutValueIsDifferentItShouldBeChangedAndDeliveredToBackendController() {
        XCTAssertFalse(state.optOut)
        mparticle.optOut = true
        XCTAssertTrue(state.optOut)
        XCTAssertTrue(backendController.setOptOutCalled)
        XCTAssertEqual(backendController.setOptOutOptOutStatusParam, true)
        XCTAssertNotNil(backendController.setOptOutCompletionHandler)
        backendController.setOptOutCompletionHandler?(true, .success)
    }
}
