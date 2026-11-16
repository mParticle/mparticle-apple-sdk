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

    // MARK: - Logout

    // CleverTap has no logout call, so the kit leaves a profile only by switching to another one.
    // These tests read the switch through the kit's one switch method, never the real CleverTap SDK.

    private let customerIdType = NSNumber(value: MPUserIdentity.customerId.rawValue)
    private let emailType = NSNumber(value: MPUserIdentity.email.rawValue)

    func testKitReceivesLogout() {
        // The core forwards a logout only to a kit that responds to the callback.
        XCTAssertTrue(MPKitCleverTap().responds(to: Selector(("onLogoutComplete:request:"))))
    }

    func testLogoutSwitchesToTheLoggedOutUsersMPID() {
        let kit = SwitchRecordingKit()
        kit.configuration = ["userIdField": "mpid"]

        let status = kit.onLogoutComplete(StubUser(userId: 1234), request: StubRequest(identities: [:]))

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(kit.switches.count, 1)
        XCTAssertEqual(kit.switches.first?["Identity"] as? String, "1234")
    }

    func testLogoutSwitchesToTheIdentitiesTheLogoutRequestNamed() {
        let kit = SwitchRecordingKit()
        kit.configuration = [:]

        let request = StubRequest(identities: [customerIdType: "guest-1", emailType: "guest@example.com"])
        let status = kit.onLogoutComplete(StubUser(userId: 1234), request: request)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(kit.switches.count, 1)
        XCTAssertEqual(kit.switches.first?["Identity"] as? String, "guest-1")
        XCTAssertEqual(kit.switches.first?["Email"] as? String, "guest@example.com")
    }

    func testLogoutWithNoIdentityKeepsTheCurrentProfile() {
        let kit = SwitchRecordingKit()
        kit.configuration = [:]

        let status = kit.onLogoutComplete(StubUser(userId: 1234), request: StubRequest(identities: [:]))

        XCTAssertEqual(status.returnCode, .requirementsNotMet)
        XCTAssertTrue(kit.switches.isEmpty)
    }

    func testLoginStillSwitchesThroughTheSameMethod() {
        let kit = SwitchRecordingKit()
        kit.configuration = [:]

        let request = StubRequest(identities: [customerIdType: "user-1"])
        let status = kit.onLoginComplete(StubUser(userId: 1234), request: request)

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(kit.switches.first?["Identity"] as? String, "user-1")
    }
}

// Records each profile switch in place of the real CleverTap SDK's onUserLogin:.
private final class SwitchRecordingKit: MPKitCleverTap {
    var switches: [NSDictionary] = []

    @objc(switchCleverTapProfileTo:)
    func recordSwitch(to profile: NSDictionary) {
        switches.append(profile)
    }
}

private final class StubUser: FilteredMParticleUser {
    private let stubUserId: NSNumber

    init(userId: NSNumber) {
        stubUserId = userId
        super.init()
    }

    override var userId: NSNumber { stubUserId }
}

private final class StubRequest: FilteredMPIdentityApiRequest {
    private let stubIdentities: [NSNumber: String]

    init(identities: [NSNumber: String]) {
        stubIdentities = identities
        super.init()
    }

    override var userIdentities: [NSNumber: String]? { stubIdentities }
}
