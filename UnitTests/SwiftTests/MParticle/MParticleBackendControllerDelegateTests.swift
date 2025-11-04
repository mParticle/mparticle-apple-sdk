//
//  MParticleBackendControllerDelegateTests.swift
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

final class MParticleBackendControllerDelegateTests: MParticleTestBase {
    
    func test_forwardLogInstall_forwardsCall_onMainQueue() {
        mparticle.forwardLogInstall()
        XCTAssertEqual(executor.executeOnMainAsync, true)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "forwardLogInstall")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
    
    func test_forwardLogUpdate_forwardsCall_onMainQueue() {
        mparticle.forwardLogUpdate()
        XCTAssertEqual(executor.executeOnMainAsync, true)
        XCTAssertTrue(kitContainer.forwardSDKCallCalled)
        XCTAssertEqual(kitContainer.forwardSDKCallSelectorParam?.description, "forwardLogUpdate")
        XCTAssertEqual(kitContainer.forwardSDKCallMessageTypeParam, .unknown)
        XCTAssertNil(kitContainer.forwardSDKCallEventParam)
        XCTAssertNil(kitContainer.forwardSDKCallParametersParam)
        XCTAssertNil(kitContainer.forwardSDKCallUserInfoParam)
    }
}
