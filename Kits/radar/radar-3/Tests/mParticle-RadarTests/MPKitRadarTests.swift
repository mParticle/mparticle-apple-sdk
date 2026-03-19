import XCTest

final class MPKitRadarTests: XCTestCase {

    func testKitCode() throws {
        let kitCode = NSClassFromString("MPKitRadar") as AnyObject
        XCTAssertNotNil(kitCode, "MPKitRadar class should be loadable")
    }
}
