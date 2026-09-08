import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUserIdentityLogicTests: XCTestCase {
    private let typeKey = "n"
    private let advertiserId = 100

    private func entry(type: Any, id: String = "v") -> [AnyHashable: Any] {
        [typeKey: type, "i": id]
    }

    // MARK: - validIdentities

    func testKeepsTypesBelowThreshold() {
        let input = [entry(type: 1), entry(type: 7)]
        let result = MPUserIdentityLogic.validIdentities(input, typeKey: typeKey, maxValidTypeExclusive: advertiserId)
        XCTAssertEqual(result.count, 2)
    }

    func testDropsTypeAtOrAboveThreshold() {
        let input = [entry(type: 1), entry(type: advertiserId), entry(type: advertiserId + 5)]
        let result = MPUserIdentityLogic.validIdentities(input, typeKey: typeKey, maxValidTypeExclusive: advertiserId)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual((result[0][typeKey] as? NSNumber)?.intValue, 1)
    }

    func testDropsNonNumberType() {
        let input = [entry(type: "not-a-number"), entry(type: 2)]
        let result = MPUserIdentityLogic.validIdentities(input, typeKey: typeKey, maxValidTypeExclusive: advertiserId)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual((result[0][typeKey] as? NSNumber)?.intValue, 2)
    }

    // MARK: - identities removingType when

    func testRemovesMatchingTypeWhenFlagSet() {
        let input = [entry(type: 1), entry(type: advertiserId), entry(type: 2)]
        let result = MPUserIdentityLogic.identities(input, removingType: advertiserId, when: true, typeKey: typeKey)
        XCTAssertEqual(result.count, 2)
        XCTAssertFalse(result.contains { ($0[typeKey] as? NSNumber)?.intValue == advertiserId })
    }

    func testDoesNotRemoveWhenFlagClear() {
        let input = [entry(type: advertiserId)]
        let result = MPUserIdentityLogic.identities(input, removingType: advertiserId, when: false, typeKey: typeKey)
        XCTAssertEqual(result.count, 1)
    }

    func testNoOpWhenTypeAbsent() {
        let input = [entry(type: 1), entry(type: 2)]
        let result = MPUserIdentityLogic.identities(input, removingType: advertiserId, when: true, typeKey: typeKey)
        XCTAssertEqual(result.count, 2)
    }

    // MARK: - dateFirstSet

    func testDateFromMillisecondsConverts() {
        let date = MPUserIdentityLogic.dateFirstSet(fromMilliseconds: NSNumber(value: 1_000_000))
        XCTAssertEqual(date.timeIntervalSince1970, 1000.0, accuracy: 0.001)
    }

    func testDateFromNilIsNow() {
        let date = MPUserIdentityLogic.dateFirstSet(fromMilliseconds: nil)
        XCTAssertEqual(date.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 2.0)
    }
}

extension MPUserIdentityLogicTests {
    private static let typeKey = "n"
    private static let idKey = "i"
    private static let dfsKey = "dfs"
    private static let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func entry(type: Int, value: Any?, firstSetMs: Double? = nil) -> [String: Any] {
        var entry: [String: Any] = [Self.typeKey: NSNumber(value: type)]
        if let value { entry[Self.idKey] = value }
        if let firstSetMs { entry[Self.dfsKey] = NSNumber(value: firstSetMs) }
        return entry
    }

    private func plan(
        type: Int = 7,
        value: String?,
        identities: [[String: Any]]
    ) -> MPUserIdentityChangePlan {
        MPUserIdentityLogic.plan(
            forIdentityType: NSNumber(value: type),
            value: value,
            currentIdentities: identities,
            typeKey: Self.typeKey,
            idKey: Self.idKey,
            dateFirstSetKey: Self.dfsKey,
            now: Self.now
        )
    }

    // MARK: - unchanged

    func testSettingTheSameValueIsUnchanged() {
        XCTAssertEqual(plan(value: "abc", identities: [entry(type: 7, value: "abc")]).kind, .unchanged)
    }

    func testCasingDifferenceIsNotUnchanged() {
        XCTAssertEqual(plan(value: "ABC", identities: [entry(type: 7, value: "abc")]).kind, .replace)
    }

    func testTheUnchangedCheckReadsTheLastEntryOfTheType() {
        // Storage should hold at most one entry per type, but when it does not the original
        // compared against the last one while mutating the first. Both halves are pinned here.
        let identities = [entry(type: 7, value: "first"), entry(type: 7, value: "last")]

        XCTAssertEqual(plan(value: "last", identities: identities).kind, .unchanged)

        let replacement = plan(value: "first", identities: identities)
        XCTAssertEqual(replacement.kind, .replace)
        XCTAssertEqual(replacement.index, 0)
    }

    func testAnEmptyStringOverAStoredEmptyStringIsUnchangedRatherThanARemoval() {
        // "" is not null, so it satisfies the equality check before the removal branch sees it.
        XCTAssertEqual(plan(value: "", identities: [entry(type: 7, value: "")]).kind, .unchanged)
    }

    func testANullStoredValueIsNotTreatedAsAMatch() {
        XCTAssertEqual(plan(value: "abc", identities: [entry(type: 7, value: NSNull())]).kind, .replace)
        XCTAssertEqual(plan(value: "abc", identities: [entry(type: 7, value: nil)]).kind, .replace)
    }

    // MARK: - remove

    func testNilValueRemovesTheExistingEntry() {
        let result = plan(value: nil, identities: [entry(type: 1, value: "x"), entry(type: 7, value: "abc")])

        XCTAssertEqual(result.kind, .remove)
        XCTAssertEqual(result.index, 1)
        XCTAssertEqual(result.existingIdentity?[Self.idKey] as? String, "abc")
    }

    func testEmptyStringRemovesTheExistingEntry() {
        let result = plan(value: "", identities: [entry(type: 7, value: "abc")])
        XCTAssertEqual(result.kind, .remove)
        XCTAssertEqual(result.index, 0)
    }

    func testRemovalTargetsTheFirstMatchingEntry() {
        let result = plan(value: nil, identities: [entry(type: 7, value: "first"), entry(type: 7, value: "last")])
        XCTAssertEqual(result.kind, .remove)
        XCTAssertEqual(result.index, 0)
    }

    func testRemovingSomethingThatIsNotStoredPersistsNothing() {
        // Distinct from `.unchanged`: the caller still reports success here.
        XCTAssertEqual(plan(value: nil, identities: []).kind, .nothingToRemove)
        XCTAssertEqual(plan(value: "", identities: [entry(type: 1, value: "x")]).kind, .nothingToRemove)
    }

    // MARK: - add

    func testANewTypeIsAddedAndStampedAsFirstTimeSet() {
        let result = plan(value: "abc", identities: [entry(type: 1, value: "x")])

        XCTAssertEqual(result.kind, .add)
        XCTAssertEqual(result.index, NSNotFound)
        XCTAssertNil(result.existingIdentity)
        XCTAssertEqual(result.dateFirstSet, Self.now)
        XCTAssertTrue(result.isFirstTimeSet)
    }

    // MARK: - replace

    func testReplaceKeepsTheStoredFirstSetDate() {
        let result = plan(value: "new", identities: [entry(type: 7, value: "old", firstSetMs: 1_500_000_000_000)])

        XCTAssertEqual(result.kind, .replace)
        XCTAssertEqual(result.index, 0)
        XCTAssertEqual(result.existingIdentity?[Self.idKey] as? String, "old")
        XCTAssertEqual(result.dateFirstSet, Date(timeIntervalSince1970: 1_500_000_000))
        XCTAssertFalse(result.isFirstTimeSet)
    }

    func testReplaceWithoutAStoredFirstSetDateFallsBackToTheCurrentDate() throws {
        let result = plan(value: "new", identities: [entry(type: 7, value: "old")])

        XCTAssertEqual(result.kind, .replace)
        // `dateFirstSetFromMilliseconds:` answers "now" when the stamp is absent.
        let stamped = try XCTUnwrap(result.dateFirstSet)
        XCTAssertEqual(stamped.timeIntervalSinceNow, 0, accuracy: 5)
    }

    // MARK: - malformed storage

    func testEntriesWithoutANumericTypeAreIgnored() {
        let identities: [[String: Any]] = [
            [Self.typeKey: "not-a-number", Self.idKey: "abc"],
            [Self.idKey: "abc"]
        ]
        let result = plan(value: "abc", identities: identities)

        XCTAssertEqual(result.kind, .add)
    }
}
