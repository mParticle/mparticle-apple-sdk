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
    
    func testSetOptOutCompletion_success() {
        sut.setOptOutCompletion(.success, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out: 1")
    }
    
    func testSetOptOutCompletion_falure() {
        sut.setOptOutCompletion(.fail, optOut: true)
        XCTAssertEqual(receivedMessage, "mParticle -> Set Opt Out Failed: 1")
    }
}
