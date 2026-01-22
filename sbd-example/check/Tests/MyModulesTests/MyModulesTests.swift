import XCTest
@testable import B
@testable import BObjC
@testable import A

final class MyModulesTests: XCTestCase {
    
    func testModuleB() {
        // Test pure Swift module B
        let engine = PricingEngine()
        let price = engine.price(for: "test")
        XCTAssertEqual(price, 40) // "test".count * 10 = 4 * 10 = 40
    }
    
    func testModuleBObjC() {
        // Test Swift bridge module BObjC
        let engine = BPricingEngineObjC()
        let price = engine.price(forUserId: "test")
        XCTAssertEqual(price.intValue, 40)
        
        let formatted = engine.formattedPrice(forUserId: "test")
        XCTAssertTrue(formatted.contains("40"))
    }
    
    func testModuleA() {
        // Test Objective-C module A
        let thing = AThing()
        // Method demo() prints to console, but we can check that object is created
        XCTAssertNotNil(thing)
    }
}
