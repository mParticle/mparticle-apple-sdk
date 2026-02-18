import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_UrbanAirship

final class MPKitUrbanAirshipTests: XCTestCase {
    
    func testKitCode() {
        let expectedKitCode: NSNumber = 25
        let actualKitCode = MPKitUrbanAirship.kitCode()
        
        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 25")
    }
}
