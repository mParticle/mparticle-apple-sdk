import XCTest
import mParticle_Apple_SDK

class mParticle_Swift_SDKTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testMPEventInit() {
        var event = MPEvent.init(name: "Dinosaur Run", type: .other)
        
        XCTAssertNotNil(event)
        XCTAssertEqual(event!.typeName(), "Other", "Type name should have been 'other.'")
        
        let typeNames = ["Reserved - Not Used", "Navigation", "Location", "Search", "Transaction", "UserContent", "UserPreference", "Social", "Other"]
        
        var type = UInt(1)
        while type < UInt(MPEventType.other.rawValue) {
            event!.type = MPEventType(rawValue: type)!
            XCTAssertEqual(event!.typeName(), typeNames[Int(type)], "Type name does not correspond to type enum.")
            type += 1
        }
        
        let eventInfo: [String : Any] = ["speed": 25,
                                         "modality":"sprinting"]
        
        event!.customAttributes = eventInfo
        event!.category = "Olympic Games"
        
        let copyEvent = event?.copy() as! MPEvent
        XCTAssertEqual(copyEvent, event, "Copied event object should not have been different.")
        
        copyEvent.type = .navigation
        XCTAssertNotEqual(copyEvent, event, "Copied event object should have been different.")
        
        copyEvent.type = event!.type
        copyEvent.name = "Run Dinosaur"
        XCTAssertNotEqual(copyEvent, event, "Copied event object should have been different.")
        
        copyEvent.name = event!.name
        copyEvent.customAttributes = nil
        XCTAssertNotEqual(copyEvent, event, "Copied event object should have been different.")
        
        copyEvent.customAttributes = event!.customAttributes
        copyEvent.duration = 1
        XCTAssertNotEqual(copyEvent, event, "Copied event object should have been different.")

        copyEvent.duration = event!.duration
        copyEvent.category = nil
        XCTAssertNotEqual(copyEvent, event, "Copied event object should have been different.")
        
        event = MPEvent.init()
        XCTAssertNotNil(event)
    }
}
