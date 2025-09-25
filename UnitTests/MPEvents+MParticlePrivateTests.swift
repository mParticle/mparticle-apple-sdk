import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class MPEventsMParticlePrivateTests: XCTestCase {
    var sut: MPEvent!
    var receivedMessage: String?
    var mparticle: MParticle!
    
    func customLogger(_ message: String) {
        receivedMessage = message
    }
    
    override func setUp() {
        super.setUp()
        mparticle = MParticle()
        mparticle.logLevel = .verbose
        mparticle.customLogger = customLogger
        sut = MPEvent()
    }
    
    // MARK: - MPEvent Initialization
    
    func testInit() {
        // MPEvent properties
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.name, "<<Event With No Name>>")
        XCTAssertEqual(sut.duration, 0)
        XCTAssertNil(sut.info)
        XCTAssertNil(sut.category)
        XCTAssertNil(sut.endTime)
        XCTAssertNil(sut.startTime)
        
        
        // MPBaseEvent properties
        XCTAssertNotNil(sut.timestamp)
        XCTAssertEqual(sut.messageType, .event)
        XCTAssertNil(sut.customAttributes)
        XCTAssertNil(sut.customFlags)
        XCTAssertTrue(sut.shouldBeginSession)
        XCTAssertTrue(sut.shouldUploadEvent)
        XCTAssertEqual(sut.type, .other)
        XCTAssertEqual(sut.typeName(), "Other")
    }
    
    func testInit_withEmptyName_returnsNil() {
        let logger = MParticle.sharedInstance().getLogger()!
        logger.logLevel = .verbose
        logger.customLogger = { message in
            self.receivedMessage = message
        }
        
        XCTAssertNil(MPEvent(name: "", type: .other))
        XCTAssertEqual(receivedMessage, "mParticle -> 'name' is required for MPEvent")
    }
    
    func testInitWithTooLongName_returnsNil() {
        let logger = MParticle.sharedInstance().getLogger()!
        logger.logLevel = .verbose
        logger.customLogger = { message in
            self.receivedMessage = message
        }
        
        let tooLongName = String(repeating: "X", count: 257)
        XCTAssertNil(MPEvent(name: tooLongName, type: .other))
        XCTAssertEqual(receivedMessage, "mParticle -> The event name is too long.")
        
    }
    
    // MARK: - Description
        
    func testDescription() {
        sut.name = "Desc Test"
        sut.duration = 10
        sut.customAttributes = ["mode": "debug"]
        sut.addCustomFlag("flag", withKey: "key")
        
        let description = sut.description
        XCTAssertTrue(description.contains("Desc Test"))
        XCTAssertTrue(description.contains("Other"))
        XCTAssertTrue(description.contains("Duration"))
        XCTAssertTrue(description.contains("mode"))
        XCTAssertTrue(sut.customFlags!.count == 1)
        XCTAssertTrue(description.contains("key"))
    }
}
