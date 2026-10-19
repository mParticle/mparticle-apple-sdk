import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_CleverTap

final class MPKitCleverTapTests: XCTestCase {

    func testKitCode() throws {
        let kitCode = NSClassFromString("MPKitCleverTap") as AnyObject
        XCTAssertNotNil(kitCode, "MPKitCleverTap class should be loadable")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. Nothing here starts the kit with usable credentials: that sets the real CleverTap
    // SDK's credentials, once per process.

    private let nonStringValues: [Any] = [NSNull(), 42, true, [Any](), [String: Any]()]

    func testLaunchWithNonStringCredentialsReportsRequirementsNotMet() {
        for value in nonStringValues {
            for key in ["AccountID", "AccountToken"] {
                var configuration: [AnyHashable: Any] = ["AccountID": "id", "AccountToken": "token"]
                configuration[key] = value

                let status = MPKitCleverTap().didFinishLaunching(withConfiguration: configuration)

                XCTAssertEqual(status.returnCode, .requirementsNotMet,
                               "\(key) of \(type(of: value)) should not start the kit")
            }
        }
    }

    func testNonStringSettingsAreTreatedAsUnset() {
        let selector = Selector(("configurationStringForKey:"))
        let keys = ["Region", "userIdField"]

        for value in nonStringValues {
            let kit = MPKitCleverTap()
            kit.configuration = Dictionary(uniqueKeysWithValues: keys.map { ($0, value) })

            for key in keys {
                XCTAssertNil(kit.perform(selector, with: key),
                             "\(key) of \(type(of: value)) should be ignored")
            }
        }

        let kit = MPKitCleverTap()
        kit.configuration = ["Region": "eu1", "userIdField": "mpid"]

        XCTAssertEqual(kit.perform(selector, with: "Region")?.takeUnretainedValue() as? String, "eu1")
        XCTAssertEqual(kit.perform(selector, with: "userIdField")?.takeUnretainedValue() as? String, "mpid")
    }

    func testStartWithoutStringCredentialsLeavesTheKitStopped() {
        let configurations: [[AnyHashable: Any]] = [
            [:],
            ["AccountID": 42, "AccountToken": "token"],
            ["AccountID": "id", "AccountToken": ""]
        ]

        for configuration in configurations {
            let kit = MPKitCleverTap()
            kit.configuration = configuration

            kit.start()

            XCTAssertFalse(kit.started, "-start with configuration \(configuration) should not start the kit")
        }
    }
}
