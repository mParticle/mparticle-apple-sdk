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
