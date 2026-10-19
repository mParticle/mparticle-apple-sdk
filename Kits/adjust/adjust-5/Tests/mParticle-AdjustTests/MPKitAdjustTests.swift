import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Adjust

final class MPKitAdjustTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 68
        let actualKitCode = MPKitAdjust.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 68")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. Nothing here launches with a usable app token: that starts the real Adjust SDK,
    // once per process.

    private let unusableAppTokens: [Any] = [NSNull(), 42, true, [Any](), [String: Any](), ""]

    func testLaunchWithoutAStringAppTokenReportsRequirementsNotMet() {
        for value in unusableAppTokens {
            let kit = MPKitAdjust()

            let status = kit.didFinishLaunching(withConfiguration: ["appToken": value])

            XCTAssertEqual(status.returnCode, .requirementsNotMet,
                           "appToken of \(type(of: value)) should not launch the kit")
            XCTAssertFalse(kit.started)
        }
    }

    func testLaunchWithoutAnAppTokenReportsRequirementsNotMet() {
        let status = MPKitAdjust().didFinishLaunching(withConfiguration: [:])

        XCTAssertEqual(status.returnCode, .requirementsNotMet)
    }
}
