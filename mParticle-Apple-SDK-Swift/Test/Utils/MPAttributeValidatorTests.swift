import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPAttributeValidatorTests: XCTestCase {
    private let keyLimit = 256
    private let valueLimit = 4096

    private func validate(key: Any?, value: Any?) -> MPAttributeValidationResult {
        MPAttributeValidator.validate(
            key: key,
            value: value,
            keyLengthLimit: keyLimit,
            valueLengthLimit: valueLimit,
            invalidArrayEntry: nil
        )
    }

    // MARK: - Valid values

    func testAStringValueIsValid() {
        XCTAssertEqual(validate(key: "foo", value: "bar"), .valid)
    }

    func testANumberValueIsValid() {
        XCTAssertEqual(validate(key: "foo", value: NSNumber(value: 123.0)), .valid)
    }

    func testAnNSNullValueIsValid() {
        XCTAssertEqual(validate(key: "foo", value: NSNull()), .valid)
    }

    func testAnArrayOfStringsWithinTheLimitIsValid() {
        XCTAssertEqual(validate(key: "foo", value: ["a", "b", "c"]), .valid)
    }

    func testAKeyAtExactlyTheLimitIsValid() {
        XCTAssertEqual(validate(key: String(repeating: "k", count: keyLimit), value: "bar"), .valid)
    }

    // MARK: - Key failures

    func testANilKeyIsInvalid() {
        XCTAssertEqual(validate(key: nil, value: "bar"), .invalidKey)
    }

    func testAnNSNullKeyIsInvalid() {
        XCTAssertEqual(validate(key: NSNull(), value: "bar"), .invalidKey)
    }

    func testAKeyOverTheLimitIsTooLong() {
        XCTAssertEqual(validate(key: String(repeating: "k", count: keyLimit + 1), value: "bar"), .keyTooLong)
    }

    // MARK: - Value failures

    func testANilValueReportsNilValue() {
        XCTAssertEqual(validate(key: "foo", value: nil), .nilValue)
    }

    func testAnUnsupportedValueTypeIsInvalid() {
        XCTAssertEqual(validate(key: "foo", value: NSDate()), .invalidType)
    }

    func testAStringValueOverTheLimitIsTooLong() {
        XCTAssertEqual(validate(key: "foo", value: String(repeating: "v", count: valueLimit + 1)), .valueTooLong)
    }

    func testAnArrayWithANonStringEntryIsInvalid() {
        var invalidArrayEntry: AnyObject?
        let result = MPAttributeValidator.validate(
            key: "foo",
            value: ["a", NSNumber(value: 1), "c"],
            keyLengthLimit: keyLimit,
            valueLengthLimit: valueLimit,
            invalidArrayEntry: &invalidArrayEntry
        )

        XCTAssertEqual(result, .invalidArrayEntry)
        XCTAssertEqual(invalidArrayEntry as? NSNumber, NSNumber(value: 1))
    }

    func testAnArrayWhoseCombinedLengthExceedsTheLimitIsTooLong() {
        let half = String(repeating: "v", count: valueLimit/2 + 1)
        XCTAssertEqual(validate(key: "foo", value: [half, half]), .arrayValueTooLong)
    }
}
