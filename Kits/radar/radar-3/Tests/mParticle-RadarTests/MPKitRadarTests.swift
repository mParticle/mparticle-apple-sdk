import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Radar

final class MPKitRadarTests: XCTestCase {

    func testKitCode() throws {
        let kitCode = NSClassFromString("MPKitRadar") as AnyObject
        XCTAssertNotNil(kitCode, "MPKitRadar class should be loadable")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. A raise is an Objective-C exception Swift cannot catch, so a regression here
    // fails the run by terminating it rather than by a failed assertion.
    // Settings go through -updateConfiguredSettings, not a full launch: a launch that clears the
    // requirements check starts the real vendor SDK and costs minutes.

    private let nonStringValues: [Any] = [NSNull(), 42, true, [Any](), [String: Any]()]

    private let nonScalarValues: [Any] = [NSNull(), [Any](), [String: Any]()]

    private func kitWithConfiguration(_ configuration: [AnyHashable: Any]) -> MPKitRadar {
        let kit = MPKitRadar()
        kit.configuration = configuration
        kit.perform(Selector(("updateConfiguredSettings")))
        return kit
    }

    func testLaunchWithNonStringPublishableKeyReportsRequirementsNotMet() {
        for value in nonStringValues {
            let kit = MPKitRadar()
            let status = kit.didFinishLaunching(withConfiguration: ["publishableKey": value])

            XCTAssertEqual(status.returnCode, .requirementsNotMet,
                           "publishableKey of \(type(of: value)) should not start the kit")
            XCTAssertFalse(kit.started)
        }
    }

    func testRejectedLaunchLeavesTrackingModeUntouched() {
        // runAutomatically used to be read before the requirements check.
        let kit = MPKitRadar()
        kit.didFinishLaunching(withConfiguration: ["runAutomatically": true])

        XCTAssertEqual(kit.value(forKey: "runAutomatically") as? Bool, false)
    }

    func testLaunchWithNonDictionaryConfigurationReportsRequirementsNotMet() {
        // Declared nonnull NSDictionary *, but the container hands over whatever the config parsed to.
        let kit = MPKitRadar()
        let selector = Selector(("didFinishLaunchingWithConfiguration:"))

        for configuration in [NSNull(), NSNumber(value: 1), "settings", [] as NSArray] as [Any] {
            let status = kit.perform(selector, with: configuration)?
                .takeUnretainedValue() as? MPKitExecStatus

            XCTAssertEqual(status?.returnCode, .requirementsNotMet,
                           "configuration of \(type(of: configuration)) should not start the kit")
            XCTAssertEqual(kit.configuration as NSDictionary, [:] as NSDictionary)
        }
    }

    func testNonScalarRunAutomaticallyIsTreatedAsOff() {
        for value in nonScalarValues {
            let kit = kitWithConfiguration(["runAutomatically": value])

            XCTAssertEqual(kit.value(forKey: "runAutomatically") as? Bool, false,
                           "runAutomatically of \(type(of: value)) should be ignored")
        }
    }

    func testScalarRunAutomaticallyIsStillHonoured() {
        for value in [true, 1, "true"] as [Any] {
            let kit = kitWithConfiguration(["runAutomatically": value])

            XCTAssertEqual(kit.value(forKey: "runAutomatically") as? Bool, true,
                           "runAutomatically of \(type(of: value)) should be honoured")
        }
    }
}
