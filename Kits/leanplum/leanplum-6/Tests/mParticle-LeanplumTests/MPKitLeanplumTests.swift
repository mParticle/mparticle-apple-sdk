import XCTest
import mParticle_Apple_SDK
@testable import mParticle_Leanplum

final class MPKitLeanplumTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 98
        let actualKitCode = MPKitLeanplum.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 98")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. Launching never starts the vendor SDK; -start does, once per process.

    private let nonStringValues: [Any] = [42, true, [Any](), [String: Any]()]

    func testLaunchWithNonStringCredentialsReportsRequirementsNotMet() {
        for value in nonStringValues {
            for key in ["appId", "clientKey"] {
                var configuration: [AnyHashable: Any] = ["appId": "app", "clientKey": "key", "userIdField": "email"]
                configuration[key] = value

                let status = MPKitLeanplum().didFinishLaunching(withConfiguration: configuration)

                XCTAssertEqual(status.returnCode, .requirementsNotMet,
                               "\(key) of \(type(of: value)) should not start the kit")
            }
        }
    }

    func testLaunchWithStringCredentialsSucceeds() {
        let status = MPKitLeanplum().didFinishLaunching(withConfiguration: ["appId": "app",
                                                                            "clientKey": "key",
                                                                            "userIdField": "email"])

        XCTAssertEqual(status.returnCode, .success)
    }
}
