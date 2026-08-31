import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitValueTransformerTests: XCTestCase {
    private let transformer = MPKitValueTransformer(logger: MPLog(logLevel: .none))

    private func transform(_ value: Any?, _ dataType: CustomModuleDataType) -> Any? {
        transformer.transformValue(value, dataType: dataType.rawValue)
    }

    func testString() {
        let value = transform("The quick brown fox", .string)
        XCTAssertEqual(value as? String, "The quick brown fox")
    }

    func testBool() {
        XCTAssertEqual(transform("TRue", .bool) as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(transform("FaLSe", .bool) as? NSNumber, NSNumber(value: false))
        XCTAssertEqual(transform("Just a String", .bool) as? NSNumber, NSNumber(value: false))
    }

    func testInt() {
        XCTAssertEqual(transform("1618033", .int) as? NSNumber, NSNumber(value: 1618033))
        // NSString.integerValue parses the leading integer portion.
        XCTAssertEqual(transform("1.618033", .int) as? NSNumber, NSNumber(value: 1))
        XCTAssertNil(transform("An Int string", .int))
        XCTAssertEqual(transform("0", .int) as? NSNumber, NSNumber(value: 0))
    }

    func testLong() {
        XCTAssertEqual(transform("161803398875", .long) as? NSNumber, NSNumber(value: 161803398875))
        XCTAssertNil(transform("A Long string", .long))
    }

    func testFloat() {
        XCTAssertEqual(transform("1.5", .float) as? NSNumber, NSNumber(value: 1.5))
        XCTAssertEqual(transform("0.0", .float) as? NSNumber, NSNumber(value: 0.0))
        // Unparseable float returns NSNull (not nil), matching the ObjC original.
        XCTAssertTrue(transform("A Float string", .float) is NSNull)
    }

    func testNullAndNil() {
        XCTAssertNil(transform(nil, .string))
        XCTAssertNil(transform(NSNull(), .string))

        for dataType in [CustomModuleDataType.int, .long] {
            XCTAssertEqual(transform(nil, dataType) as? NSNumber, NSNumber(value: 0))
            XCTAssertEqual(transform(NSNull(), dataType) as? NSNumber, NSNumber(value: 0))
        }

        XCTAssertEqual(transform(nil, .float) as? NSNumber, NSNumber(value: 0))
        XCTAssertEqual(transform(NSNull(), .float) as? NSNumber, NSNumber(value: 0))

        XCTAssertEqual(transform(nil, .bool) as? NSNumber, NSNumber(value: false))
        XCTAssertEqual(transform(NSNull(), .bool) as? NSNumber, NSNumber(value: false))
    }

    // customAttributes are `[String: id]` and reach the projection path un-stringified, so values
    // can be NSNumber. The ObjC original coerced these via integerValue/floatValue; verify parity.
    func testNumberInputs() {
        XCTAssertEqual(
            transform(NSNumber(value: 1618033), .int) as? NSNumber,
            NSNumber(value: 1618033)
        )
        XCTAssertEqual(
            transform(NSNumber(value: 161803398875), .long) as? NSNumber,
            NSNumber(value: 161803398875)
        )
        XCTAssertEqual(transform(NSNumber(value: 1.5), .float) as? NSNumber, NSNumber(value: 1.5))
        // Matches ObjC [@(1.5) integerValue] == 1
        XCTAssertEqual(transform(NSNumber(value: 1.5), .int) as? NSNumber, NSNumber(value: 1))
        XCTAssertEqual(transform(NSNumber(value: 0), .int) as? NSNumber, NSNumber(value: 0))
        // .string returns the object as-is
        XCTAssertEqual(transform(NSNumber(value: 42), .string) as? NSNumber, NSNumber(value: 42))
    }

    // A fractional NSNumber in (-1, 1) truncates to 0 for int/long (ObjC [@(0.5) integerValue] == 0)
    // rather than dropping to nil, which the earlier stringify-then-parse path did.
    func testFractionalNumberInputs() {
        XCTAssertEqual(transform(NSNumber(value: 0.5), .int) as? NSNumber, NSNumber(value: 0))
        XCTAssertEqual(transform(NSNumber(value: -0.5), .int) as? NSNumber, NSNumber(value: 0))
        XCTAssertEqual(transform(NSNumber(value: 0.9), .long) as? NSNumber, NSNumber(value: 0))
        XCTAssertEqual(transform(NSNumber(value: 1.9), .int) as? NSNumber, NSNumber(value: 1))
        // Full 64-bit range survives (int64Value, not int32)
        XCTAssertEqual(
            transform(NSNumber(value: 9_000_000_000), .long) as? NSNumber,
            NSNumber(value: 9_000_000_000)
        )
        // Float keeps the fractional value
        XCTAssertEqual(transform(NSNumber(value: 0.5), .float) as? NSNumber, NSNumber(value: 0.5))
    }

    // Explicit decision (the ObjC original would have raised unrecognized-selector here):
    // an NSNumber bool attribute uses its boolValue; string parsing is unchanged.
    func testBoolFromNumber() {
        XCTAssertEqual(transform(NSNumber(value: true), .bool) as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(transform(NSNumber(value: false), .bool) as? NSNumber, NSNumber(value: false))
        XCTAssertEqual(transform(NSNumber(value: 1), .bool) as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(transform(NSNumber(value: 0), .bool) as? NSNumber, NSNumber(value: false))
    }

    // An unrecognised raw MPDataType (not 1...5) yields nil.
    func testUnknownDataTypeReturnsNil() {
        XCTAssertNil(transformer.transformValue("anything", dataType: 0))
        XCTAssertNil(transformer.transformValue(NSNumber(value: 5), dataType: 99))
    }
}
