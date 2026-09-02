import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPExecStatusFormatterTests: XCTestCase {
    func testEachStatusMapsToItsDescription() {
        let expected = [
            0: "Success",
            1: "Fail",
            2: "Missing Parameter",
            3: "Feature Disabled Remotely",
            4: "Feature Enabled Remotely",
            5: "User Opted Out of Tracking",
            6: "Data Already Being Fetched",
            7: "Invalid Data Type",
            8: "Data is Being Uploaded",
            9: "Server is Busy",
            10: "Item Not Found",
            11: "Feature is Disabled in Settings",
            12: "There is no network connectivity"
        ]
        for (status, description) in expected {
            XCTAssertEqual(MPExecStatusFormatter.description(for: status), description)
        }
    }

    func testStatusPastTheLastKnownCaseIsNil() {
        XCTAssertNil(MPExecStatusFormatter.description(for: 13))
        XCTAssertNil(MPExecStatusFormatter.description(for: 999))
    }

    func testNegativeStatusIsNil() {
        XCTAssertNil(MPExecStatusFormatter.description(for: -1))
    }
}
