import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_UrbanAirship

final class MPKitUrbanAirshipTests: XCTestCase {
    
    func testKitCode() {
        let expectedKitCode: NSNumber = 25
        let actualKitCode = MPKitUrbanAirship.kitCode()
        
        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 25")
    }
    
    func testDidFinishLaunchingWithConfiguration() {
        let kit = MPKitUrbanAirship()
        
        let kitConfiguration: [String: Any] = [
            "applicationKey": "testAppKey",
            "applicationSecret": "testAppSecret",
            "id": 25
        ]
        
        let execStatus = kit.didFinishLaunching(withConfiguration: kitConfiguration)
        
        XCTAssertNotNil(execStatus, "Exec status should not be nil")
        XCTAssertEqual(execStatus.returnCode, MPKitReturnCodeSuccess, "Return code should be success")
        XCTAssertEqual(execStatus.kitCode, 25, "Kit code should match")
    }
}
