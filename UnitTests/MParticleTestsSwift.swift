import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class MParticleTestsSwift: XCTestCase {
    var receivedMessage: String?
    var sut: MParticle!
    
    func customLogger(_ message: String) {
        receivedMessage = message
    }
    
    override func setUp() {
        super.setUp()
        
        sut = MParticle.sharedInstance()
        sut.logLevel = .verbose
        sut.customLogger = customLogger
    }
    
    override func tearDown() {
        super.tearDown()
        receivedMessage = nil
    }
    
    func testSetOptOutCompletion_success() {
        sut.setOptOutCompletion(.success, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out: 1")
    }
    
    func testSetOptOutCompletion_falure() {
        sut.setOptOutCompletion(.fail, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out Failed: 1")
    }
    
    func testIdentifyNoDispatchCallback_noError_defferedKitAvailable() {
        sut.deferredKitConfiguration_PRIVATE = [[String: String]]();
        let expectedApiResult = MPIdentityApiResult()
        let options = MParticleOptions()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, error in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertNil(error)
            
            expectation.fulfill()
        }
        sut.identifyNoDispatchCallback(expectedApiResult, error: nil, options: options)
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertNil(receivedMessage)
        XCTAssertNil(sut.deferredKitConfiguration_PRIVATE)
    }
    
    func testIdentifyNoDispatchCallback_withError_defferedKitAvailable() {
        sut.deferredKitConfiguration_PRIVATE = [[String: String]]();
        let expectedApiResult = MPIdentityApiResult()
        let expectedError = NSError(domain: "", code: 0)
        let options = MParticleOptions()
        let expectation = XCTestExpectation()
        options.onIdentifyComplete = { apiResult, error in
            XCTAssertTrue(expectedApiResult === apiResult)
            XCTAssertTrue(expectedError == expectedError)
            
            expectation.fulfill()
        }
        sut.identifyNoDispatchCallback(expectedApiResult, error: expectedError, options: options)
        
        wait(for: [expectation], timeout: 0.1)
        XCTAssertEqual(receivedMessage, "mParticle -> Identify request failed with error: Error Domain= Code=0 \"(null)\"")
        XCTAssertNil(sut.deferredKitConfiguration_PRIVATE)
    }
    
    func testConfigure_defaultConfigurationExist_optionParametersAreNotSet() {
        let options = MParticleOptions()
        sut.configure(with: options)
        XCTAssertEqual(sut.backendController.sessionTimeout, 0.0)
        XCTAssertEqual(sut.backendController.uploadInterval, 0.0)
        XCTAssertEqual(sut.customUserAgent, nil)
        XCTAssertEqual(sut.collectUserAgent, true)
        XCTAssertEqual(sut.trackNotifications, true)
    }
}
