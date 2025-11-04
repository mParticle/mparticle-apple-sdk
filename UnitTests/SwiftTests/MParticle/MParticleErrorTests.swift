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
    
    func test_logErrorCallback_logsMessage_whenSuccess() {
        mparticle.logErrorCallback([:], execStatus: .success, message: "error")
        
        assertReceivedMessage("Logged error with message: error")
    }
    
    func test_logErrorCallback_doesNotLog_whenFail() {
        mparticle.logErrorCallback([:], execStatus: .fail, message: "error")
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_logExceptionCallback_logsDetails_whenSuccess() {
        mparticle.logExceptionCallback(exception, execStatus: .success, message: "exception", topmostContext: nil)
        
        assertReceivedMessage("Logged exception name: exception, reason: Test, topmost context: (null)")
    }
    
    func test_logExceptionCallback_doesNotLog_whenFail() {
        mparticle.logExceptionCallback(exception, execStatus: .fail, message: "exception", topmostContext: nil)
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_logCrashCallback_logsMessage_whenSuccess() {
        mparticle.logCrashCallback(.success, message: "Message")
        assertReceivedMessage("Logged crash with message: Message")
    }
    
    func test_logNetworkPerformanceCallback_logsMessage_whenSuccess() {
        mparticle.logNetworkPerformanceCallback(.success)
        
        assertReceivedMessage("Logged network performance measurement")
    }
    
    func test_logNetworkPerformanceCallback_doesNotLog_whenFail() {
        mparticle.logNetworkPerformanceCallback(.fail)
        
        XCTAssertNil(receivedMessage)
    }
}
