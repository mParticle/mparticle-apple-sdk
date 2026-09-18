import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Singular

final class MPKitSingularTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 119
        let actualKitCode = MPKitSingular.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 119")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. A raise is an Objective-C exception Swift cannot catch, so a regression here
    // fails the run by terminating it rather than by a failed assertion.

    private let nonStringValues: [Any] = [NSNull(), 42, true, [Any](), [String: Any]()]

    func testLaunchWithNonStringApiKeyReportsRequirementsNotMet() {
        // apiKey is a file-scope global, so launch successfully first: this must assert the
        // per-configuration check, not the leftover global.
        MPKitSingular().didFinishLaunching(withConfiguration: [
            "apiKey": "test_api_key",
            "secret": "test_secret"
        ])

        for value in nonStringValues {
            let kit = MPKitSingular()
            let status = kit.didFinishLaunching(withConfiguration: ["apiKey": value, "secret": "test_secret"])

            XCTAssertEqual(status.returnCode, .requirementsNotMet,
                           "apiKey of \(type(of: value)) should not start the kit")
        }
    }

    func testLaunchWithMissingApiKeyReportsRequirementsNotMet() {
        MPKitSingular().didFinishLaunching(withConfiguration: [
            "apiKey": "test_api_key",
            "secret": "test_secret"
        ])

        let status = MPKitSingular().didFinishLaunching(withConfiguration: ["secret": "test_secret"])

        XCTAssertEqual(status.returnCode, .requirementsNotMet)
    }

    func testLaunchWithNonDictionaryConfigurationReportsRequirementsNotMet() {
        // Declared nonnull NSDictionary *, but the container hands over whatever the config parsed to.
        let kit = MPKitSingular()
        let selector = Selector(("didFinishLaunchingWithConfiguration:"))

        for configuration in [NSNull(), NSNumber(value: 1), "settings", [] as NSArray] as [Any] {
            let status = kit.perform(selector, with: configuration)?
                .takeUnretainedValue() as? MPKitExecStatus

            XCTAssertEqual(status?.returnCode, .requirementsNotMet,
                           "configuration of \(type(of: configuration)) should not start the kit")
            XCTAssertEqual(kit.configuration as NSDictionary, [:] as NSDictionary)
        }
    }

    func testMalformedSecretAndDeepLinkTimeoutDoNotBlockLaunch() {
        // ddlTimeout is read with intValue, which a container does not respond to.
        for value in nonStringValues {
            let kit = MPKitSingular()
            let status = kit.didFinishLaunching(withConfiguration: [
                "apiKey": "test_api_key",
                "secret": value,
                "ddlTimeout": value
            ])

            XCTAssertEqual(status.returnCode, .success,
                           "secret/ddlTimeout of \(type(of: value)) should not block the launch")
        }
    }
}
