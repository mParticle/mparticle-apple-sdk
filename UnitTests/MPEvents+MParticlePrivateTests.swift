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
    
    var event1: MPEvent!
    var event1Copy: MPEvent!
    var event2: MPEvent!
    
    func customLogger(_ message: String) {
        receivedMessage = message
    }
    
    override func setUp() {
        super.setUp()
        mparticle = MParticle()
        mparticle.logLevel = .verbose
        mparticle.customLogger = customLogger
        sut = MPEvent()
        
        // Default setup for event1 and event2
        event1 = MPEvent(name: "Event1", type: .other)
        event1Copy = MPEvent(name: "Event1", type: .other)
        event2 = MPEvent(name: "Event2", type: .other)
        
        event1.duration = 100
        event1.category = "Category"
        event1.customAttributes = ["key": "value"]
        
        event1Copy.duration = 100
        event1Copy.category = "Category"
        event1Copy.customAttributes = ["key": "value"]
        
        event2.duration = 100
        event2.category = "Category2"
        event2.customAttributes = ["key": "value"]
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
    
    // MARK: - NSObject
    
    func testIsEqual_withSameValues_returnsTrue() {
        XCTAssertTrue(event1.isEqual(event1Copy))
    }
    
    func testIsEqual_withDifferentName_returnsFalse() {
        XCTAssertFalse(event1.isEqual(event2))
    }
    
    func testIsEqual_withDifferentDuration_returnsFalse() {
        event1Copy.duration = 200
        
        XCTAssertFalse(event1.isEqual(event1Copy))
    }
    
    func testIsEqual_withCategoryMismatch_returnsFalse() {
        event1.category = "Category1"
        event1Copy.category = "Category2"
        
        XCTAssertFalse(event1.isEqual(event1Copy))
    }
    
    func testIsEqual_withNilCategoryOnOneSide_returnsFalse() {
        event1.category = nil
        event1Copy.category = "Category"
        
        XCTAssertFalse(event1.isEqual(event1Copy))
    }
    
    func testHash_isConsistentForSameValues() {
        XCTAssertEqual(event1.hash, event1Copy.hash)
    }
    
    func testHash_changesWhenNameChanges() {
        XCTAssertNotEqual(event1.hash, event2.hash)
    }
    
    // MARK: - Copying
    
//    func testCopy_createsDeepCopy() {
//        let event1 = MPEvent(name: "Original", type: .other)!
//        event1.duration = 123
//        event1.startTime = Date(timeIntervalSince1970: 1000)
//        event1.endTime = Date(timeIntervalSince1970: 2000)
//        event1.category = "Category"
//        
//        let event2 = event1.copy() as! MPEvent
//        
//        // Values are copied
//        XCTAssertEqual(event1.name, event2.name)
//        XCTAssertEqual(event1.duration, event2.duration)
//        XCTAssertEqual(event1.startTime, event2.startTime)
//        XCTAssertEqual(event1.endTime, event2.endTime)
//        XCTAssertEqual(event1.category, event2.category)
//        
//        // Objects are not the same instance
//        XCTAssertFalse(event1 === event2)
//    }
    
}
