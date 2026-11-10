import XCTest
@testable import mParticle_Apple_SDK
@testable import mParticle_Kochava

final class MPKitKochavaTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 37
        let actualKitCode = MPKitKochava.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 37")
    }

    // MARK: - Malformed server configuration

    // Server configuration is parsed JSON, so any value can arrive as a number, boolean or
    // container.
    // Nothing here calls -start with a usable appId: that starts the real vendor SDK.

    private let nonStringValues: [Any] = [NSNull(), 42, true, [Any](), [String: Any]()]

    func testLaunchWithNonStringAppIdReportsRequirementsNotMet() {
        for value in nonStringValues {
            let status = MPKitKochava().didFinishLaunching(withConfiguration: ["appId": value])

            XCTAssertEqual(status.returnCode, .requirementsNotMet,
                           "appId of \(type(of: value)) should not launch the kit")
        }

        let status = MPKitKochava().didFinishLaunching(withConfiguration: ["appId": "app-guid"])
        XCTAssertEqual(status.returnCode, .success)
    }

    func testStartWithoutStringAppIdLeavesTheKitStopped() {
        for configuration in [[:], ["appId": 42]] as [[AnyHashable: Any]] {
            let kit = MPKitKochava()
            kit.configuration = configuration

            kit.start()

            XCTAssertFalse(kit.started, "-start with configuration \(configuration) should not start the kit")
        }
    }

    func testNonStringIdentificationTypesAreTreatedAsUnset() {
        for value in nonStringValues {
            let kit = kitWithEmailUser(configuration: ["userIdentificationType": value,
                                                       "emailIdentificationType": value])

            let status = kit.setUserIdentity("user@example.com", identityType: .email)

            XCTAssertNotEqual(status.returnCode, .success,
                              "identification types of \(type(of: value)) should be treated as unset")
        }
    }

    func testStringIdentificationTypeIsStillHonoured() {
        // The user has no CustomerId identity, so nothing is registered with the vendor SDK.
        let kit = kitWithEmailUser(configuration: ["userIdentificationType": "CustomerId"])

        let status = kit.setUserIdentity("user@example.com", identityType: .email)

        XCTAssertEqual(status.returnCode, .success)
    }

    func testNonScalarSettingsAreTreatedAsUnset() {
        let selector = Selector(("configurationScalarForKey:"))
        let keys = ["enableATT", "enableATTPrompt", "waitIntervalATT", "limitAdTracking", "enableLogging"]

        for value in [NSNull(), [Any](), [String: Any]()] as [Any] {
            let kit = MPKitKochava()
            kit.configuration = Dictionary(uniqueKeysWithValues: keys.map { ($0, value) })

            for key in keys {
                XCTAssertNil(kit.perform(selector, with: key),
                             "\(key) of \(type(of: value)) should be ignored")
            }
        }

        let kit = MPKitKochava()
        kit.configuration = ["enableATT": "true", "waitIntervalATT": 30]

        XCTAssertEqual(kit.perform(selector, with: "enableATT")?.takeUnretainedValue() as? String, "true")
        XCTAssertEqual(kit.perform(selector, with: "waitIntervalATT")?.takeUnretainedValue() as? Int, 30)
    }

    private func kitWithEmailUser(configuration: [AnyHashable: Any]) -> MPKitKochava {
        let kit = MPKitKochava()
        kit.kitApi = KitAPIWithEmailUser()
        kit.configuration = configuration
        return kit
    }
}

private final class EmailUser: FilteredMParticleUser {
    override var userIdentities: [NSNumber: String] {
        [NSNumber(value: MPUserIdentity.email.rawValue): "user@example.com"]
    }
}

// Supplies a user with an email identity without going through the core SDK.
private final class KitAPIWithEmailUser: MPKitAPI {
    override func getCurrentUser(withKit kit: any MPKitProtocol) -> FilteredMParticleUser {
        EmailUser()
    }
}
