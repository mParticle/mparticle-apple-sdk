import XCTest
import mParticle_Apple_SDK
@testable import mParticle_Apptimize

final class MPKitApptimizeTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 105
        let actualKitCode = MPKitApptimize.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 105")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container. Nothing here launches with a usable app key: that starts the real Apptimize SDK,
    // once per process.

    private let unusableAppKeys: [Any] = [NSNull(), 42, true, [Any](), [String: Any](), ""]

    // The two third-party event options the kit always sets.
    private let defaultOptionCount = 2

    func testLaunchWithoutAStringAppKeyReportsRequirementsNotMet() {
        for value in unusableAppKeys {
            let kit = MPKitApptimize()

            let status = kit.didFinishLaunching(withConfiguration: ["appKey": value])

            XCTAssertEqual(status.returnCode, .requirementsNotMet,
                           "appKey of \(type(of: value)) should not launch the kit")
            XCTAssertFalse(kit.started)
        }
    }

    func testLaunchWithoutAnAppKeyReportsRequirementsNotMet() {
        let status = MPKitApptimize().didFinishLaunching(withConfiguration: [:])

        XCTAssertEqual(status.returnCode, .requirementsNotMet)
    }

    func testStartWithoutAStringAppKeyLeavesTheKitStopped() {
        for value in unusableAppKeys {
            let kit = MPKitApptimize()
            kit.configuration = ["appKey": value]

            kit.start()

            XCTAssertFalse(kit.started, "-start with appKey of \(type(of: value)) should not start the kit")
        }
    }

    func testNonScalarOptionsAreDroppedInsteadOfRaising() {
        let keys = ["devicePairing", "delayUntilTestsAreAvailable", "logLevel"]

        for value in [NSNull(), [Any](), [String: Any]()] as [Any] {
            let kit = MPKitApptimize()
            kit.configuration = Dictionary(uniqueKeysWithValues: keys.map { ($0, value) })

            XCTAssertEqual(buildOptions(kit)?.count, defaultOptionCount,
                           "options of \(type(of: value)) should be dropped")
        }
    }

    func testNonScalarLaunchOptionsAreDroppedInsteadOfRaising() {
        let kit = MPKitApptimize()
        kit.configuration = ["appKey": "test-app-key"]
        kit.launchOptions = ["devicePairing": NSNull(), "delayUntilTestsAreAvailable": [Any]()]

        XCTAssertEqual(buildOptions(kit)?.count, defaultOptionCount)
    }

    func testNonStringLogLevelIsDropped() {
        let kit = MPKitApptimize()
        kit.configuration = ["logLevel": 3]

        XCTAssertEqual(buildOptions(kit)?.count, defaultOptionCount)
    }

    func testStringAndNumberBooleansAreRead() {
        let selector = Selector(("configBoolForKey:"))
        let cases: [(Any, Bool)] = [("true", true), ("false", false), ("YES", true), (1, true), (0, false), (true, true)]

        for (value, expected) in cases {
            let kit = MPKitApptimize()
            kit.configuration = ["devicePairing": value]

            let result = kit.perform(selector, with: "devicePairing")?.takeUnretainedValue() as? NSNumber

            XCTAssertEqual(result?.boolValue, expected, "devicePairing \(value) should read as \(expected)")
        }
    }

    func testStringAndNumberDelaysAreRead() {
        let selector = Selector(("configDoubleForKey:"))

        for value in ["2.5", 2.5] as [Any] {
            let kit = MPKitApptimize()
            kit.configuration = ["delayUntilTestsAreAvailable": value]

            let result = kit.perform(selector, with: "delayUntilTestsAreAvailable")?.takeUnretainedValue() as? NSNumber

            XCTAssertEqual(result?.doubleValue, 2.5)
        }
    }

    func testValidConfigurationSetsEveryOption() {
        let kit = MPKitApptimize()
        kit.configuration = ["appKey": "test-app-key",
                             "devicePairing": "true",
                             "delayUntilTestsAreAvailable": "2.5",
                             "logLevel": "LOG_LEVEL_DEBUG"]

        let appKey = kit.perform(Selector(("appKeyFromConfiguration:")), with: kit.configuration)?
            .takeUnretainedValue() as? String

        XCTAssertEqual(appKey, "test-app-key")
        XCTAssertEqual(buildOptions(kit)?.count, defaultOptionCount + 3)
    }

    private func buildOptions(_ kit: MPKitApptimize) -> NSDictionary? {
        kit.perform(Selector(("buildApptimizeOptions")))?.takeUnretainedValue() as? NSDictionary
    }
}
