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
    
    func testBeginTimedEventCompletionHandlerDataFilterNotSet() {
        mparticle.dataPlanFilter = nil
        XCTAssertNil(mparticle.dataPlanFilter)
        
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        assertReceivedMessage("Began timed event", event: event)
    }
    
    func testBeginTimedEventCompletionHandlerDataFilterSetDataFilterReturnNil() {
        mparticle.beginTimedEventCompletionHandler(event, execStatus: .success)
        XCTAssertTrue(dataPlanFilter.transformEventCalled)
        XCTAssertEqual(dataPlanFilter.transformEventEventParam, event)
        assertReceivedMessage("Blocked timed event begin from kits", event: event)
    }
}
