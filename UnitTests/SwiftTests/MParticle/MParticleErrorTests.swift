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
    
    var errorMessage = "error"
    
    func test_logErrorCallback_logsMessage_whenSuccess() {
        mparticle.logErrorCallback([:], execStatus: .success, message: errorMessage)
        
        assertReceivedMessage("Logged error with message: \(errorMessage)")
    }
    
    func test_logErrorCallback_doesNotLog_whenFail() {
        mparticle.logErrorCallback([:], execStatus: .fail, message: errorMessage)
        
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
        mparticle.logCrashCallback(.success, message: errorMessage)
        assertReceivedMessage("Logged crash with message: \(errorMessage)")
    }
    
    func test_logNetworkPerformanceCallback_logsMessage_whenSuccess() {
        mparticle.logNetworkPerformanceCallback(.success)
        
        assertReceivedMessage("Logged network performance measurement")
    }
    
    func test_logNetworkPerformanceCallback_doesNotLog_whenFail() {
        mparticle.logNetworkPerformanceCallback(.fail)
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_logError_withoutEventInfo_invokesBackendWithNil() {
        mparticle.logError(errorMessage)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(listenerController.onAPICalledCalled)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logError:eventInfo:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 as! String == errorMessage)
        
        XCTAssertTrue(backendController.logErrorCalled)
        XCTAssertNil(backendController.logErrorExceptionParam)
        XCTAssertNil(backendController.logErrorTopmostContextParam)
        XCTAssertNil(backendController.logErrorEventInfoParam)
        backendController.logErrorCompletionHandler?(errorMessage, .success)
        
        assertReceivedMessage("Logged error with message: \(errorMessage)")
    }
    
    func test_logError_withNilMessage_logsRequirementMessage() {
        errorMessage = ""
        mparticle.logError(errorMessage, eventInfo: keyValueDict)
        assertReceivedMessage("'message' is required for logError:eventInfo:")
    }
    
    func test_logError_withMessage_invokesBackend() {
        mparticle.logError(errorMessage, eventInfo: keyValueDict)
        
        XCTAssertTrue(executor.executeOnMessageQueueAsync)
        XCTAssertTrue(listenerController.onAPICalledCalled)
        XCTAssertEqual(listenerController.onAPICalledApiName?.description, "logError:eventInfo:")
        XCTAssertTrue(listenerController.onAPICalledParameter1 as! String == errorMessage)
        
        XCTAssertTrue(backendController.logErrorCalled)
        XCTAssertNil(backendController.logErrorExceptionParam)
        XCTAssertNil(backendController.logErrorTopmostContextParam)
        XCTAssertTrue(backendController.logErrorEventInfoParam as! [String : String] == keyValueDict)
        backendController.logErrorCompletionHandler?(errorMessage, .success)
        
        assertReceivedMessage("Logged error with message: \(errorMessage)")
    }
}
