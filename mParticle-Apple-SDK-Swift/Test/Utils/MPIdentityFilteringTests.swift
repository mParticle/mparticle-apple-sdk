import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPIdentityFilteringTests: XCTestCase {

    private let filtering = MPIdentityFilteringPRIVATE()
    private func num(_ value: Int) -> NSNumber { NSNumber(value: value) }
    private func makeHasher() -> MPIHasher { MPIHasher(logger: MPLog(logLevel: .none)) }

    // MARK: - userIdentities(fromStoredArray:)

    func testParseStoredArray() {
        let array: [[AnyHashable: Any]] = [
            ["n": num(7), "i": "example@example.com"],
            ["n": num(1), "i": "12345"]
        ]
        let result = filtering.userIdentities(fromStoredArray: array)
        XCTAssertEqual(result[num(7)], "example@example.com")
        XCTAssertEqual(result[num(1)], "12345")
    }

    func testParseStoredArrayNilReturnsEmpty() {
        XCTAssertTrue(filtering.userIdentities(fromStoredArray: nil).isEmpty)
    }

    func testParseStoredArraySkipsMalformedEntries() {
        let array: [[AnyHashable: Any]] = [
            ["n": num(7)], // missing "i"
            ["i": "orphan"], // missing "n"
            ["n": num(1), "i": "ok"]
        ]
        let result = filtering.userIdentities(fromStoredArray: array)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[num(1)], "ok")
    }

    // MARK: - filterUserIdentities

    func testFilterDropsConfigBlockedIdentity() {
        let identities: [NSNumber: Any] = [num(7): "e@x.com", num(1): "12345"]
        let filters: [AnyHashable: Any] = ["7": num(0)]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: filters, isBlocked: { _ in false })
        XCTAssertNil(result[num(7)])
        XCTAssertEqual(result[num(1)] as? String, "12345")
    }

    func testFilterKeepsConfigAllowedIdentity() {
        let identities: [NSNumber: Any] = [num(1): "12345"]
        let filters: [AnyHashable: Any] = ["1": num(1)]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: filters, isBlocked: { _ in false })
        XCTAssertEqual(result[num(1)] as? String, "12345")
    }

    func testFilterDropsDeviceIdentities() {
        // iosAdvertiserId (22) and above are device identities, never forwarded.
        let identities: [NSNumber: Any] = [num(22): "idfa", num(1): "12345"]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: nil, isBlocked: { _ in false })
        XCTAssertNil(result[num(22)])
        XCTAssertEqual(result[num(1)] as? String, "12345")
    }

    func testFilterDropsDataPlanBlockedIdentity() {
        let identities: [NSNumber: Any] = [num(1): "12345"]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: nil, isBlocked: { $0.intValue == 1 })
        XCTAssertNil(result[num(1)])
    }

    func testFilterPreservesNSNullValues() {
        let identities: [NSNumber: Any] = [num(1): NSNull()]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: nil, isBlocked: { _ in false })
        XCTAssertTrue(result[num(1)] is NSNull)
    }

    // Regression cover for PR #823 (dropped-alias symptom): alias (8) is below the
    // device-identity threshold (22), so it must survive filtering and reach kits.
    func testFilterKeepsAliasIdentity() {
        let alias = num(MPIdentitySwift.alias.rawValue)
        let identities: [NSNumber: Any] = [alias: "alias-value", num(22): "idfa"]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: nil, isBlocked: { _ in false })
        XCTAssertEqual(result[alias] as? String, "alias-value")
        XCTAssertNil(result[num(22)], "device identity should still be dropped")
    }

    func testFilterDropsAliasWhenConfigBlocks() {
        let alias = num(MPIdentitySwift.alias.rawValue)
        let identities: [NSNumber: Any] = [alias: "alias-value"]
        let filters: [AnyHashable: Any] = [alias.stringValue: num(0)]
        let result = filtering.filterUserIdentities(identities, userIdentityFilters: filters, isBlocked: { _ in false })
        XCTAssertNil(result[alias])
    }

    // MARK: - filterUserAttributes

    func testFilterUserAttributesDropsConfigBlocked() {
        let hasher = makeHasher()
        let attributes: [String: Any] = ["good data": "67890", "bad data": "12345"]
        let filters: [AnyHashable: Any] = [hasher.hashString("bad data"): num(0)]
        let result = filtering.filterUserAttributes(
            attributes,
            userAttributeFilters: filters,
            hasher: hasher,
            isBlocked: { _ in false }
        )
        XCTAssertNil(result["bad data"])
        XCTAssertEqual(result["good data"] as? String, "67890")
    }

    func testFilterUserAttributesDropsDataPlanBlocked() {
        let attributes: [String: Any] = ["blocked": "x", "kept": "y"]
        let result = filtering.filterUserAttributes(
            attributes,
            userAttributeFilters: nil,
            hasher: makeHasher(),
            isBlocked: { $0 == "blocked" }
        )
        XCTAssertNil(result["blocked"])
        XCTAssertEqual(result["kept"] as? String, "y")
    }
}
