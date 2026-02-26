import XCTest

final class MPKitCleverTapTests: XCTestCase {

    func testKitCode() throws {
        let kitCode = NSClassFromString("MPKitCleverTap") as AnyObject
        XCTAssertNotNil(kitCode, "MPKitCleverTap class should be loadable")
    }
}
