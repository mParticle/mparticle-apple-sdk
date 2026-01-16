import Foundation

import XCTest
import mParticle_Apple_SDK_NoLocation

final class MParticleIdentityTests: MParticleTestBase {
    
    func test_identifyNoDispatchCallback_clearsDeferredKit_whenNoError() {
        mparticle.deferredKitConfiguration_PRIVATE = [[String: String]]()
        let expectedApiResult = MPIdentityApiResult()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, error in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        mparticle.identifyNoDispatchCallback(expectedApiResult, error: nil, options: options)
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedMessage)
        XCTAssertNil(mparticle.deferredKitConfiguration_PRIVATE)
    }
    
    func test_identifyNoDispatchCallback_logsError_andClearsDeferredKit_whenErrorPresent() {
        mparticle.deferredKitConfiguration_PRIVATE = [[String: String]]()
        let expectedApiResult = MPIdentityApiResult()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, _ in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertTrue(self.error == self.error)
            
            expectation.fulfill()
        }
        mparticle.identifyNoDispatchCallback(expectedApiResult, error: error, options: options)
        
        wait(for: [expectation], timeout: 0.1)
        assertReceivedMessage("Identify request failed with error: \(error)")
        XCTAssertNil(mparticle.deferredKitConfiguration_PRIVATE)
    }
}
