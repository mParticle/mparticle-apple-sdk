import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUserAttributeLogicTests: XCTestCase {
    private let sentinel = "__MPNull__"

    // MARK: - fromStorage

    func testSentinelStringBecomesNull() {
        let result = MPUserAttributeLogic.attributesFromStorage(["a": sentinel], nullSentinel: sentinel)
        XCTAssertTrue(result["a"] is NSNull)
    }

    func testNonSentinelValuesAreUntouched() {
        let input: [AnyHashable: Any] = ["s": "hello", "n": 3, "list": ["x"]]
        let result = MPUserAttributeLogic.attributesFromStorage(input, nullSentinel: sentinel)
        XCTAssertEqual(result["s"] as? String, "hello")
        XCTAssertEqual(result["n"] as? Int, 3)
        XCTAssertEqual(result["list"] as? [String], ["x"])
    }

    // MARK: - forStorage

    func testNullBecomesSentinelString() {
        let result = MPUserAttributeLogic.attributesForStorage(["a": NSNull()], nullSentinel: sentinel)
        XCTAssertEqual(result["a"] as? String, sentinel)
    }

    func testForStorageLeavesOtherValues() {
        let input: [AnyHashable: Any] = ["s": "hi", "n": 7]
        let result = MPUserAttributeLogic.attributesForStorage(input, nullSentinel: sentinel)
        XCTAssertEqual(result["s"] as? String, "hi")
        XCTAssertEqual(result["n"] as? Int, 7)
    }

    func testRoundTripThroughStorage() {
        let inMemory: [AnyHashable: Any] = ["keep": "v", "null": NSNull()]
        let stored = MPUserAttributeLogic.attributesForStorage(inMemory, nullSentinel: sentinel)
        XCTAssertEqual(stored["null"] as? String, sentinel)
        let restored = MPUserAttributeLogic.attributesFromStorage(stored, nullSentinel: sentinel)
        XCTAssertTrue(restored["null"] is NSNull)
        XCTAssertEqual(restored["keep"] as? String, "v")
    }

    // MARK: - increment

    func testIntegerIncrement() {
        XCTAssertEqual(MPUserAttributeLogic.incrementedValue(from: 10, byValue: 5), 15)
    }

    func testNegativeIncrement() {
        XCTAssertEqual(MPUserAttributeLogic.incrementedValue(from: 10, byValue: -4), 6)
    }

    func testDecimalIncrementUsesDecimalArithmetic() {
        let result = MPUserAttributeLogic.incrementedValue(from: NSNumber(value: 0.1), byValue: NSNumber(value: 0.2))
        XCTAssertEqual(result, NSDecimalNumber(string: "0.3"))
    }
}
