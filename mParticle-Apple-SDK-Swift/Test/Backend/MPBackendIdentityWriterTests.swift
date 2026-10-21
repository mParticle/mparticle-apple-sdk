import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPBackendIdentityWriterTests: MPBackendWorkflowTestCase {
    private var fixture = MPBackendSessionFixture()
    private var host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
    private var writer: MPBackendIdentityWriter!

    override func setUp() {
        super.setUp()
        fixture = MPBackendSessionFixture()
        host = MPBackendFakeHost(defaults: MPBackendMemoryUserDefaults())
        _ = fixture.session()
        writer = MPBackendIdentityWriter(
            state: fixture.state, dependencies: fixture.dependencies, writer: fixture.writer, host: host
        )
        writer.now = { Date(timeIntervalSince1970: 1000) }
    }

    private func stored() -> [[String: Any]] {
        writer.userIdentities(forUserId: 1) as? [[String: Any]] ?? []
    }

    private func loggedMessageTypes() -> [String] {
        fixture.persistence.savedMessages.compactMap {
            ($0.dictionaryRepresentation() as? [String: Any])?["dt"] as? String
        }
    }

    func testAddingAnIdentityStoresItAndLogsTheChange() throws {
        onMessageQueue { [self] in
            let outcome = writer.setUserIdentity("a@example.com", identityType: .email, timestamp: nil)
            XCTAssertEqual(outcome.status, .success)
            XCTAssertEqual(outcome.value as? String, "a@example.com")
            XCTAssertEqual(outcome.type, .email)
        }

        let entry = try XCTUnwrap(stored().first)
        XCTAssertEqual(stored().count, 1)
        XCTAssertEqual(entry["n"] as? NSNumber, 7)
        XCTAssertEqual(entry["i"] as? String, "a@example.com")
        XCTAssertEqual(entry["f"] as? Bool, true)
        XCTAssertEqual((entry["dfs"] as? NSNumber)?.doubleValue, 1_000_000)
        XCTAssertEqual(loggedMessageTypes(), ["uic"])
    }

    func testSettingTheStoredValueAgainReportsFailureAndLogsNothing() {
        onMessageQueue { [self] in
            _ = writer.setUserIdentity("a@example.com", identityType: .email, timestamp: nil)
            let again = writer.setUserIdentity("a@example.com", identityType: .email, timestamp: nil)
            XCTAssertEqual(again.status, .fail)
            XCTAssertEqual(again.value as? String, "a@example.com")
            XCTAssertEqual(again.type, .email)
        }

        XCTAssertEqual(stored().count, 1)
        XCTAssertEqual(loggedMessageTypes(), ["uic"])
    }

    func testReplacingAnIdentityKeepsTheDateItWasFirstSet() throws {
        onMessageQueue { [self] in
            _ = writer.setUserIdentity("old", identityType: .customerId, timestamp: nil)
            writer.now = { Date(timeIntervalSince1970: 9999) }
            XCTAssertEqual(writer.setUserIdentity("new", identityType: .customerId, timestamp: nil).status, .success)
        }

        let entry = try XCTUnwrap(stored().first)
        XCTAssertEqual(stored().count, 1)
        XCTAssertEqual(entry["i"] as? String, "new")
        XCTAssertEqual(entry["f"] as? Bool, false)
        XCTAssertEqual((entry["dfs"] as? NSNumber)?.doubleValue, 1_000_000)
        XCTAssertEqual(loggedMessageTypes(), ["uic", "uic"])
    }

    func testRemovingWithNilNullOrEmptyStringReportsNoValueAndTypeZero() {
        for removal in [nil, NSNull(), ""] as [Any?] {
            onMessageQueue { [self] in
                _ = writer.setUserIdentity("a@example.com", identityType: .email, timestamp: nil)
                let outcome = writer.setUserIdentity(removal, identityType: .email, timestamp: nil)
                XCTAssertEqual(outcome.status, .success)
                XCTAssertNil(outcome.value)
                XCTAssertEqual(outcome.type, .other)
            }

            XCTAssertTrue(stored().isEmpty)
        }
        XCTAssertEqual(loggedMessageTypes(), ["uic", "uic", "uic", "uic", "uic", "uic"])
    }

    func testTheChangeMessageCarriesTheCallersTimestamp() throws {
        onMessageQueue { [self] in
            _ = writer.setUserIdentity("a@example.com", identityType: .email, timestamp: Date(timeIntervalSince1970: 500))
        }

        let message = try XCTUnwrap(
            fixture.persistence.savedMessages.first?.dictionaryRepresentation() as? [String: Any]
        )
        XCTAssertEqual((message["ct"] as? NSNumber)?.doubleValue, 500_000)
    }

    func testRemovingAnAbsentIdentityReportsSuccessAndLogsNothing() {
        onMessageQueue { [self] in
            let outcome = writer.setUserIdentity(nil, identityType: .email, timestamp: nil)
            XCTAssertEqual(outcome.status, .success)
            XCTAssertNil(outcome.value)
            XCTAssertEqual(outcome.type, .email)
        }

        XCTAssertTrue(stored().isEmpty)
        XCTAssertTrue(loggedMessageTypes().isEmpty)
    }

    func testANonStringIdentityIsRejectedWithoutTouchingStorage() {
        onMessageQueue { [self] in
            _ = writer.setUserIdentity("a@example.com", identityType: .email, timestamp: nil)
            let outcome = writer.setUserIdentity(NSNumber(value: 7), identityType: .email, timestamp: nil)
            XCTAssertEqual(outcome.status, .invalidDataType)
            XCTAssertEqual(outcome.value as? NSNumber, 7)
            XCTAssertEqual(outcome.type, .email)
        }

        XCTAssertEqual(stored().map { $0["i"] as? String }, ["a@example.com"])
        XCTAssertEqual(loggedMessageTypes(), ["uic"])
    }

    func testStoredIdentitiesLeaveOutDeviceTypesAndMalformedEntries() {
        host.defaults.setMPObject(
            [
                ["n": 7, "i": "a@example.com"],
                ["n": 22, "i": "advertiser"],
                ["i": "no type"],
                "not a dictionary"
            ],
            forKey: "ui",
            userId: 1
        )

        XCTAssertEqual(stored().map { $0["i"] as? String }, ["a@example.com"])
    }
}
