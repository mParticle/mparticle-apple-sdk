import XCTest
@testable import mParticle_Localytics

final class MPKitLocalyticsTests: XCTestCase {

    func testKitCode() {
        let expectedKitCode: NSNumber = 84
        let actualKitCode = MPKitLocalytics.kitCode()

        XCTAssertEqual(actualKitCode, expectedKitCode, "Kit code should be 84")
    }

    // MARK: - Logout

    // Every identifier name the kit writes with setValue:forIdentifier:. The kit sends the customer id
    // and the email to their own setters, so "CustomerId" and "Email" are not in this set.
    private let kitIdentifierNames: Set<String> = [
        "Other", "Facebook", "Twitter", "Google", "Microsoft", "Yahoo", "Alias", "FacebookCustomAudienceId",
        "Other2", "Other3", "Other4", "Other5", "Other6", "Other7", "Other8", "Other9", "Other10",
        "MobileNumber", "PhoneNumber2", "PhoneNumber3"
    ]

    private let logoutSelector = #selector(MPKitProtocol.onLogoutComplete(_:request:))

    func testLogoutClearsTheCustomerIdTheEmailAndTheKitIdentifiers() {
        let kit = LocalyticsRecordingKit()
        guard kit.responds(to: logoutSelector) else {
            return XCTFail("The kit should handle logout")
        }

        let status = kit.onLogoutComplete(FilteredUserStub(), request: FilteredMPIdentityApiRequest())

        XCTAssertEqual(status.returnCode, .success)
        XCTAssertEqual(Array(kit.calls.prefix(2)), [.customerId(nil), .email(nil)])
        let clears = kit.calls.dropFirst(2)
        XCTAssertEqual(clears.count, kitIdentifierNames.count)
        XCTAssertEqual(Set(clears), Set(kitIdentifierNames.map { LocalyticsRecordingKit.Call.identifier(nil, $0) }),
                       "Logout should clear every identifier the kit sets, and only those")
    }

    func testLogoutAppliesTheNextUsersIdentitiesAfterTheClear() {
        let kit = LocalyticsRecordingKit()
        guard kit.responds(to: logoutSelector) else {
            return XCTFail("The kit should handle logout")
        }
        let nextUser = FilteredUserStub(userIdentities: [
            NSNumber(value: MPUserIdentity.customerId.rawValue): "example-user-id",
            NSNumber(value: MPUserIdentity.email.rawValue): "user@example.com",
            NSNumber(value: MPUserIdentity.other.rawValue): "example-other-id",
            // The first device identity key. The core never forwards device identities to
            // setUserIdentity:identityType:, so logout skips it too.
            NSNumber(value: MPUserIdentity.phoneNumber3.rawValue + 1): "test-device-id"
        ])

        _ = kit.onLogoutComplete(nextUser, request: FilteredMPIdentityApiRequest())

        let clearCount = 2 + kitIdentifierNames.count
        XCTAssertTrue(kit.calls.prefix(clearCount).allSatisfy { $0.value == nil }, "The clear should come first")
        let applied = kit.calls.dropFirst(clearCount)
        XCTAssertEqual(applied.count, 3)
        XCTAssertTrue(applied.contains(.customerId("example-user-id")))
        XCTAssertTrue(applied.contains(.email("user@example.com")))
        XCTAssertTrue(applied.contains(.identifier("example-other-id", "Other")))
    }

    func testSetUserIdentityWritesThroughTheKitsOwnMethods() {
        let kit = LocalyticsRecordingKit()
        // Without the private write methods these calls would reach the Localytics SDK, which is not started.
        guard MPKitLocalytics.instancesRespond(to: NSSelectorFromString("setLocalyticsCustomerId:")) else {
            return XCTFail("The kit should route its Localytics identity writes through its own methods")
        }

        XCTAssertEqual(kit.setUserIdentity("example-user-id", identityType: .customerId).returnCode, .success)
        XCTAssertEqual(kit.setUserIdentity("user@example.com", identityType: .email).returnCode, .success)
        XCTAssertEqual(kit.setUserIdentity("example-facebook-id", identityType: .facebook).returnCode, .success)

        XCTAssertEqual(kit.calls, [
            .customerId("example-user-id"),
            .email("user@example.com"),
            .identifier("example-facebook-id", "Facebook")
        ])
    }
}

// Replaces the kit's private Localytics identity writes through Objective-C dispatch, so tests can
// read what the kit asks of Localytics without starting the Localytics SDK.
private final class LocalyticsRecordingKit: MPKitLocalytics {
    enum Call: Hashable {
        case customerId(String?)
        case email(String?)
        case identifier(String?, String)

        var value: String? {
            switch self {
            case let .customerId(value), let .email(value), let .identifier(value, _):
                return value
            }
        }
    }

    private(set) var calls: [Call] = []

    @objc(setLocalyticsCustomerId:)
    func setLocalyticsCustomerId(_ customerId: String?) {
        calls.append(.customerId(customerId))
    }

    @objc(setLocalyticsCustomerEmail:)
    func setLocalyticsCustomerEmail(_ email: String?) {
        calls.append(.email(email))
    }

    @objc(setLocalyticsValue:forIdentifier:)
    func setLocalyticsValue(_ value: String?, forIdentifier identifier: String) {
        calls.append(.identifier(value, identifier))
    }
}

private final class FilteredUserStub: FilteredMParticleUser {
    private let stubIdentities: [NSNumber: String]

    init(userIdentities: [NSNumber: String] = [:]) {
        stubIdentities = userIdentities
        super.init()
    }

    override var userIdentities: [NSNumber: String] { stubIdentities }
}
