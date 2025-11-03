//
//  MParticleErrorTests.swift
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

final class MParticleErrorTests: MParticleTestBase {
    
    func testLogErrorCallbackSuccess() {
        mparticle.logErrorCallback([:], execStatus: .success, message: "error")
        
        assertReceivedMessage("Logged error with message: error")
    }
    
    func testLogErrorCallbackFail() {
        mparticle.logErrorCallback([:], execStatus: .fail, message: "error")
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogExceptionCallbackSuccess() {
        mparticle.logExceptionCallback(exception, execStatus: .success, message: "exception", topmostContext: nil)
        
        assertReceivedMessage("Logged exception name: exception, reason: Test, topmost context: (null)")
    }
    
    func testLogExceptionCallbackFail() {
        mparticle.logExceptionCallback(exception, execStatus: .fail, message: "exception", topmostContext: nil)
        
        XCTAssertNil(receivedMessage)
    }
    
    func testLogCrashCallbackSuccess() {
        mparticle.logCrashCallback(.success, message: "Message")
        assertReceivedMessage("Logged crash with message: Message")
    }
    
    func testLogNetworkPerformanceCallbackSuccess() {
        mparticle.logNetworkPerformanceCallback(.success)
        
        assertReceivedMessage("Logged network performance measurement")
    }
    
    func testLogNetworkPerformanceCallbackFail() {
        mparticle.logNetworkPerformanceCallback(.fail)
        
        XCTAssertNil(receivedMessage)
    }
}
