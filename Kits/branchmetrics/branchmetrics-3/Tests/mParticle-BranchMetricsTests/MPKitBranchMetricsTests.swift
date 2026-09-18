import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_BranchMetrics

final class MPKitBranchMetricsTests: XCTestCase {

    func testKitCode() throws {
        let kitCode = NSClassFromString("MPKitBranchMetrics") as AnyObject
        XCTAssertNotNil(kitCode, "MPKitBranchMetrics class should be loadable")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. A raise is an Objective-C exception Swift cannot catch, so a regression here
    // fails the run by terminating it rather than by a failed assertion.
    // Settings go through -updateConfiguredSettings, not a full launch: a launch that clears the
    // requirements check starts the real vendor SDK and costs minutes.

    private let nonStringValues: [Any] = [NSNull(), 42, true, [Any](), [String: Any]()]

    private let nonScalarValues: [Any] = [NSNull(), [Any](), [String: Any]()]

    private func kitWithConfiguration(_ configuration: [AnyHashable: Any]) -> MPKitBranchMetrics {
        let kit = MPKitBranchMetrics()
        kit.configuration = configuration
        kit.perform(Selector(("updateConfiguredSettings")))
        return kit
    }

    func testLaunchWithNonStringBranchKeyReportsRequirementsNotMet() {
        for value in nonStringValues {
            let kit = MPKitBranchMetrics()
            let status = kit.didFinishLaunching(withConfiguration: ["branchKey": value])

            XCTAssertEqual(status.returnCode, .requirementsNotMet,
                           "branchKey of \(type(of: value)) should not start the kit")
            XCTAssertFalse(kit.started)
        }
    }

    func testLaunchWithEmptyBranchKeyReportsRequirementsNotMet() {
        let kit = MPKitBranchMetrics()
        let status = kit.didFinishLaunching(withConfiguration: ["branchKey": ""])

        XCTAssertEqual(status.returnCode, .requirementsNotMet)
    }

    func testLaunchWithNonDictionaryConfigurationReportsRequirementsNotMet() {
        // Declared nonnull NSDictionary *, but the container hands over whatever the config parsed to.
        let kit = MPKitBranchMetrics()
        let selector = Selector(("didFinishLaunchingWithConfiguration:"))

        for configuration in [NSNull(), NSNumber(value: 1), "settings", [] as NSArray] as [Any] {
            let status = kit.perform(selector, with: configuration)?
                .takeUnretainedValue() as? MPKitExecStatus

            XCTAssertEqual(status?.returnCode, .requirementsNotMet,
                           "configuration of \(type(of: configuration)) should not start the kit")
            XCTAssertEqual(kit.configuration as NSDictionary, [:] as NSDictionary)
        }
    }

    func testNonScalarForwardScreenViewsIsTreatedAsOff() {
        for value in nonScalarValues {
            let kit = kitWithConfiguration(["forwardScreenViews": value])

            XCTAssertEqual(kit.value(forKey: "forwardScreenViews") as? Bool, false,
                           "forwardScreenViews of \(type(of: value)) should be ignored")
        }
    }

    func testScalarForwardScreenViewsIsStillHonoured() {
        for value in [true, 1, "true"] as [Any] {
            let kit = kitWithConfiguration(["forwardScreenViews": value])

            XCTAssertEqual(kit.value(forKey: "forwardScreenViews") as? Bool, true,
                           "forwardScreenViews of \(type(of: value)) should be honoured")
        }
    }

    func testNonStringUserIdentificationTypeLeavesIdentityTypeUnchanged() {
        // A wrong-typed value must take the "key absent" path, not the unrecognised-string fallback.
        let defaultIdentityType = MPKitBranchMetrics().value(forKey: "identityType") as? UInt

        for value in nonStringValues {
            let kit = kitWithConfiguration(["userIdentificationType": value])

            XCTAssertEqual(kit.value(forKey: "identityType") as? UInt, defaultIdentityType,
                           "userIdentificationType of \(type(of: value)) should not select an identity")
            XCTAssertEqual(kit.value(forKey: "isMpidIdentityType") as? Bool, false)
        }
    }

    func testRecognisedUserIdentificationStringIsStillHonoured() {
        let kit = kitWithConfiguration(["userIdentificationType": "CustomerId"])

        XCTAssertEqual(kit.value(forKey: "identityType") as? UInt, MPIdentity.customerId.rawValue)
    }

    func testUnrecognisedUserIdentificationStringStillFallsBackToEmail() {
        let kit = kitWithConfiguration(["userIdentificationType": "NotAnIdentity"])

        XCTAssertEqual(kit.value(forKey: "identityType") as? UInt, MPIdentity.email.rawValue)
    }
}
