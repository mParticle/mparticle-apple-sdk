import XCTest

final class MPKitBranchMetricsTests: XCTestCase {

    func testKitCode() throws {
        let kitCode = NSClassFromString("MPKitBranchMetrics") as AnyObject
        XCTAssertNotNil(kitCode, "MPKitBranchMetrics class should be loadable")
    }
}
