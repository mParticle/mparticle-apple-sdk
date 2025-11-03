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
    
    func testStartWithKeyCallbackFirstRun() {
        XCTAssertFalse(mparticle.initialized)
        
        mparticle.start(withKeyCallback: true, options: options, userDefaults: userDefaults)
        
        XCTAssertTrue(mparticle.initialized)
        XCTAssertNil(mparticle.settingsProvider.configSettings)
        
        XCTAssertNotNil(userDefaults.setMPObjectValueParam)
        XCTAssertEqual(userDefaults.setMPObjectKeyParam, "firstrun")
        XCTAssertEqual(userDefaults.setMPObjectUserIdParam, 0)
        XCTAssertTrue(userDefaults.synchronizeCalled)
    }
    
    func testStartWithKeyCallbackNotFirstRunWithIdentityRequest() {
        let user = mparticle.identity.currentUser
        options.identifyRequest = MPIdentityApiRequest(user: user!)
        
        mparticle.start(withKeyCallback: false, options: options, userDefaults: userDefaults as MPUserDefaultsProtocol)
        
        XCTAssertTrue(mparticle.initialized)
        XCTAssertNil(mparticle.settingsProvider.configSettings)
        
        XCTAssertFalse(userDefaults.setMPObjectCalled)
        XCTAssertFalse(userDefaults.synchronizeCalled)
    }
    
    func testBeginSessionTempSessionAvailableSessionTempSessionShouldNotBeCreated() {
        backendController.session = nil
        backendController.tempSessionReturnValue = MParticleSession()
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func testBeginSessionSessionAvailableSessionTempSessionShouldNotBeCreated() {
        backendController.session = MPSession()
        backendController.tempSessionReturnValue = nil
        mparticle.beginSession()
        XCTAssertFalse(backendController.createTempSessionCalled)
    }
    
    func testBeginSessionSessionUnavailable() {
        backendController.session = nil
        backendController.tempSessionReturnValue = nil
        mparticle.beginSession()
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(backendController.createTempSessionCalled)
        XCTAssertTrue(backendController.beginSessionCalled)
        XCTAssertEqual(backendController.beginSessionIsManualParam, true)
        XCTAssertNotNil(backendController.beginSessionDateParam)
    }
    
    func testEndSessionNoSession() {
        backendController.session = nil
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertFalse(backendController.endSessionWithIsManualCalled)
    }
    
    func testEndSessionWithSession() {
        backendController.session = MPSession()
        mparticle.endSession()
        XCTAssertEqual(executor.executeOnMessageQueueAsync, true)
        XCTAssertTrue(backendController.endSessionWithIsManualCalled)
        XCTAssertEqual(backendController.endSessionIsManualParam, true)
    }
    
    func testSessionDidBegin() {
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
    
    func testSessionDidEnd() {
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
    
    func testResetForSwitchingWorkspaces() {
        let expectation = XCTestExpectation()
        
        mparticle.reset {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertTrue(kitContainer.flushSerializedKitsCalled)
        XCTAssertTrue(kitContainer.removeAllSideloadedKitsCalled)
        XCTAssertEqual(persistenceController.resetDatabaseCalled, true)
        XCTAssertTrue(backendController.unproxyOriginalAppDelegateCalled)
    }
    
    func testForwardLogInstall() {
        mparticle.forwardLogInstall()
        XCTAssertEqual(executor.executeOnMainAsync, true)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "forwardLogInstall")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testForwardLogUpdate() {
        mparticle.forwardLogUpdate()
        XCTAssertEqual(executor.executeOnMainAsync, true)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "forwardLogUpdate")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func testBeginTimedEventDependenciesReceiveCorrectParametersAndHandlerExecutedWithoutErrors() {
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
