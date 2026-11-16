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

    // MARK: - Logout

    // The user a logout returns is the new anonymous user, which usually has no customer id or email.

    private let customerIdKey = NSNumber(value: MPUserIdentity.customerId.rawValue)
    private let emailKey = NSNumber(value: MPUserIdentity.email.rawValue)

    func testLogoutMovesLeanplumToItsDeviceIdWhenTheNewUserHasNoMappedIdentity() {
        for userIdField in ["customerId", "email"] {
            let kit = LeanplumRecordingKit(deviceId: "example-device-id")
            kit.configuration = ["userIdField": userIdField]

            let status = kit.onLogoutComplete(FilteredUserStub(userId: 42), request: FilteredMPIdentityApiRequest())

            XCTAssertEqual(status.returnCode, .success)
            XCTAssertEqual(kit.calls, [.setUserId("example-device-id"), .forceContentUpdate],
                           "In \(userIdField) mode the logged-out user's Leanplum id should not survive a logout")
        }
    }

    func testLogoutUsesTheNewUsersOwnMappedIdentity() {
        let customerIdCase = ("customerId", customerIdKey, "example-customer-id")
        let emailCase = ("email", emailKey, "user@example.com")
        for (userIdField, key, value) in [customerIdCase, emailCase] {
            let kit = LeanplumRecordingKit(deviceId: "example-device-id")
            kit.configuration = ["userIdField": userIdField]
            let user = FilteredUserStub(userId: 42, userIdentities: [key: value])

            let status = kit.onLogoutComplete(user, request: FilteredMPIdentityApiRequest())

            XCTAssertEqual(status.returnCode, .success)
            XCTAssertEqual(kit.calls, [.setUserId(value), .forceContentUpdate])
        }
    }

    func testLogoutTreatsAnEmptyMappedIdentityAsMissing() {
        let kit = LeanplumRecordingKit(deviceId: "example-device-id")
        kit.configuration = ["userIdField": "customerId"]
        let user = FilteredUserStub(userId: 42, userIdentities: [customerIdKey: ""])

        _ = kit.onLogoutComplete(user, request: FilteredMPIdentityApiRequest())

        XCTAssertEqual(kit.calls, [.setUserId("example-device-id"), .forceContentUpdate])
    }

    func testLogoutWithNoIdToSetChangesNothing() {
        let kit = LeanplumRecordingKit(deviceId: nil)
        kit.configuration = ["userIdField": "customerId"]

        let status = kit.onLogoutComplete(FilteredUserStub(userId: 42), request: FilteredMPIdentityApiRequest())

        XCTAssertEqual(status.returnCode, .fail)
        XCTAssertEqual(kit.calls, [])
    }

    func testLogoutInMPIDModeLeavesTheIdentityObserverToMoveLeanplum() {
        let kit = LeanplumRecordingKit(deviceId: "example-device-id")
        kit.configuration = ["userIdField": "mpid"]

        let status = kit.onLogoutComplete(FilteredUserStub(userId: 42), request: FilteredMPIdentityApiRequest())

        XCTAssertEqual(status.returnCode, .unavailable)
        XCTAssertEqual(kit.calls, [])
    }
}

// Replaces the kit's private Leanplum calls through Objective-C dispatch, so tests can read what the
// kit asks of Leanplum without starting the Leanplum SDK.
private final class LeanplumRecordingKit: MPKitLeanplum {
    enum Call: Equatable {
        case setUserId(String)
        case forceContentUpdate
    }

    private let stubDeviceId: String?
    private(set) var calls: [Call] = []

    init(deviceId: String?) {
        stubDeviceId = deviceId
        super.init()
    }

    @objc func leanplumDeviceId() -> String? {
        stubDeviceId
    }

    @objc(setLeanplumUserId:)
    func setLeanplumUserId(_ userId: String) {
        calls.append(.setUserId(userId))
    }

    @objc func forceLeanplumContentUpdate() {
        calls.append(.forceContentUpdate)
    }
}

private final class FilteredUserStub: FilteredMParticleUser {
    private let stubUserId: NSNumber
    private let stubIdentities: [NSNumber: String]

    init(userId: NSNumber, userIdentities: [NSNumber: String] = [:]) {
        stubUserId = userId
        stubIdentities = userIdentities
        super.init()
    }

    override var userId: NSNumber { stubUserId }
    override var userIdentities: [NSNumber: String] { stubIdentities }
}
