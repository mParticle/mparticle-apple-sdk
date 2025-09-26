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
    
    // MARK: - NSCopying
    
    func testCopyWithZone_createsDeepCopy() {
        event1.addCustomFlag("flagValue", withKey: "flagKey")
        let event2 = event1.copy() as! MPEvent
        XCTAssertEqual(event1, event2)
        
        // Objects are not the same instance
        XCTAssertFalse(event1 === event2)
    }
    
    // MARK: - Public accessors
    
    func testSetCategory_withValidCategory_setsCategory() {
        sut.category = "validCategory"
        XCTAssertEqual(sut.category, "validCategory")
    }
    
    func testSetCategory_withTooLongCategory_discardsAndLogs() {
        let logger = MParticle.sharedInstance().getLogger()!
        logger.logLevel = .verbose
        logger.customLogger = { message in
           self.receivedMessage = message
        }
       
        let tooLongCategory = String(repeating: "X", count: 4097)
        sut.category = tooLongCategory
       
        XCTAssertEqual(receivedMessage, "mParticle -> The category length is too long. Discarding category.")
        XCTAssertNil(sut.category)
    }
    
    func testDictionaryRepresentation_whenDurationInfoCategoryAreNil_numberOfItemsZero() {
        sut.duration = nil
        sut.customAttributes = nil
        sut.category = nil
        
        let dict = sut.dictionaryRepresentation
        
        XCTAssertNil(dict["attrs"]) // kMPAttributesKey
    }

    func testDictionaryRepresentation_withMinimalEvent() {
        let dict = event1.dictionaryRepresentation
        
        XCTAssertEqual(dict["n"] as? String, "Event1") // kMPEventNameKey
        XCTAssertEqual(dict["et"] as? String, "Other") // kMPEventTypeKey
        XCTAssertNotNil(dict["en"]) // kMPEventCounterKey
        XCTAssertNotNil(dict["est"])  // kMPEventStartTimestamp
        XCTAssertEqual(dict["el"] as? Int, 100) // kMPEventLength
    }
    
    func testDictionaryRepresentation_withDurationAndCategoryAndAttributes() {
        let dict = event1.dictionaryRepresentation
        let attributes = dict["attrs"] as! [String: Any]
        
        XCTAssertEqual(dict["el"] as? Int, 100)
        XCTAssertEqual(attributes["key"] as? String, "value")
        XCTAssertEqual(attributes["$Category"] as? String, "Category")
        XCTAssertEqual(attributes["EventLength"] as? Int, 100)
    }
    
    func testDictionaryRepresentation_withCustomFlags_includesFlags() {
        event1.addCustomFlag("flagValue", withKey: "flagKey")
        
        let dict = event1.dictionaryRepresentation
        let flags = dict["flags"] as! [String: Any]
        
        XCTAssertEqual(flags["flagKey"] as? [String], ["flagValue"])
    }
    
    func testDictionaryRepresentation_setsLengthZeroWhenDurationIsNil() {
        event1.duration = nil
        
        let dict = event1.dictionaryRepresentation
        
        XCTAssertEqual(dict["el"] as? Int, 0) // kMPEventLength
    }

    func testDictionaryRepresentation_usesStartTimeWhenPresent() {
        let start = Date(timeIntervalSince1970: 0)
        event1.startTime = start
        
        let dict = event1.dictionaryRepresentation
        let ts = dict["est"] as? Int // kMPEventStartTimestamp
        
        // Convert start back to ms for comparison
        let expected = Int(start.timeIntervalSince1970)
        XCTAssertEqual(ts, expected)
    }
    
    func testInfoAndSetInfo_mapsToCustomAttributes() {
        sut.info = ["a": "1"]
        XCTAssertEqual(sut.info?["a"] as? String, "1")
        XCTAssertEqual(sut.customAttributes?["a"] as? String, "1")
    }
    
    func testSetName_withEmptyName_discardsAndLogs() {
        let logger = MParticle.sharedInstance().getLogger()!
        logger.logLevel = .verbose
        logger.customLogger = { message in
            self.receivedMessage = message
        }
        
        sut.name = ""
        XCTAssertEqual(receivedMessage, "mParticle -> 'name' cannot be nil or empty.")
    }
    
    func testSetName_withTooLongName_discardsAndLogs() {
        let logger = MParticle.sharedInstance().getLogger()!
        logger.logLevel = .verbose
        logger.customLogger = { message in
            self.receivedMessage = message
        }
        
        sut.name = String(repeating: "N", count: 257)
        XCTAssertEqual(receivedMessage, "mParticle -> The event name is too long.")
    }
    
    
    // MARK: - Public category methods
    
    func testBeginTiming_whenEndTimeIsNotNil() {
        sut.endTime = Date(timeIntervalSince1970: 0)
        sut.beginTiming()
        
        // make sure duration is nil
        XCTAssertNotNil(sut.startTime)
        XCTAssertNil(sut.duration)
        XCTAssertNil(sut.endTime)
    }
    
    func testBreadcrumbDictionaryRepresentation_withAttributes() {
        event1.customAttributes = ["key": "value"]
        
        let dict = event1.breadcrumbDictionaryRepresentation()!
        XCTAssertEqual(dict["l"] as? String, "Event1") // kMPLeaveBreadcrumbsKey
        XCTAssertLessThanOrEqual(dict["est"] as! Int, Int(Date().timeIntervalSince1970 * 1000)) // kMPEventStartTimestamp
        let attrs = dict["attrs"] as! [String: Any]
        XCTAssertEqual(attrs["key"] as? String, "value")
    }
    
    func testEndTiming_whenStartTimeIsNil() {
        sut.startTime = Date(timeIntervalSince1970: 0)
        
        sut.endTiming()
        
        XCTAssertNotNil(sut.endTime)
        XCTAssertNotNil(sut.duration)
    }
    
    func testEndTiming_withoutStartTime_clearsEndTimeAndDuration() {
        sut.startTime = nil
        
        sut.endTiming()
        
        XCTAssertNil(sut.endTime)
        XCTAssertNil(sut.duration)
    }
}
