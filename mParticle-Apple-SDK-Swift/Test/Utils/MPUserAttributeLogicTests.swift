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

extension MPUserAttributeLogicTests {
    // MARK: - mutation(forValidationResult:keyExists:)

    func testAValidPairIsAlwaysStored() {
        XCTAssertEqual(MPUserAttributeLogic.mutation(forValidationResult: .valid, keyExists: false), .store)
        XCTAssertEqual(MPUserAttributeLogic.mutation(forValidationResult: .valid, keyExists: true), .store)
    }

    func testANilValueRemovesOnlyAKeyThatIsPresent() {
        XCTAssertEqual(MPUserAttributeLogic.mutation(forValidationResult: .nilValue, keyExists: true), .delete)
        XCTAssertEqual(MPUserAttributeLogic.mutation(forValidationResult: .nilValue, keyExists: false), .reject)
    }

    func testEveryOtherValidationFailureIsRejected() {
        let failures: [MPAttributeValidationResult] = [
            .invalidKey, .keyTooLong, .invalidType, .valueTooLong, .invalidArrayEntry, .arrayValueTooLong
        ]

        for failure in failures {
            XCTAssertEqual(MPUserAttributeLogic.mutation(forValidationResult: failure, keyExists: true), .reject, "\(failure)")
            XCTAssertEqual(MPUserAttributeLogic.mutation(forValidationResult: failure, keyExists: false), .reject, "\(failure)")
        }
    }

    // MARK: - valueToLog

    func testNumbersAreLoggedAsStrings() {
        XCTAssertEqual(MPUserAttributeLogic.valueToLog(for: NSNumber(value: 42)) as? String, "42")
        XCTAssertEqual(MPUserAttributeLogic.valueToLog(for: NSNumber(value: 3.5)) as? String, "3.5")
        XCTAssertEqual(MPUserAttributeLogic.valueToLog(for: NSNumber(value: true)) as? String, "1")
    }

    func testEverythingElseIsLoggedUnchanged() {
        XCTAssertEqual(MPUserAttributeLogic.valueToLog(for: "abc") as? String, "abc")
        XCTAssertTrue(MPUserAttributeLogic.valueToLog(for: NSNull()) is NSNull)
        XCTAssertEqual(MPUserAttributeLogic.valueToLog(for: ["a", "b"]) as? [String], ["a", "b"])
        XCTAssertNil(MPUserAttributeLogic.valueToLog(for: nil))
    }
}
