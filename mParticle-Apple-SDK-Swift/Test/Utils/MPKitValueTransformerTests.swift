import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPKitValueTransformerTests: XCTestCase {
    private let transformer = MPKitValueTransformer(logger: MPLog(logLevel: .none))

    func testString() {
        let value = transformer.transformValue("The quick brown fox", dataType: .string)
        XCTAssertEqual(value as? String, "The quick brown fox")
    }

    func testBool() {
        XCTAssertEqual(transformer.transformValue("TRue", dataType: .bool) as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(transformer.transformValue("FaLSe", dataType: .bool) as? NSNumber, NSNumber(value: false))
        XCTAssertEqual(transformer.transformValue("Just a String", dataType: .bool) as? NSNumber, NSNumber(value: false))
    }

    func testInt() {
        XCTAssertEqual(transformer.transformValue("1618033", dataType: .int) as? NSNumber, NSNumber(value: 1618033))
        // NSString.integerValue parses the leading integer portion.
        XCTAssertEqual(transformer.transformValue("1.618033", dataType: .int) as? NSNumber, NSNumber(value: 1))
        XCTAssertNil(transformer.transformValue("An Int string", dataType: .int))
        XCTAssertEqual(transformer.transformValue("0", dataType: .int) as? NSNumber, NSNumber(value: 0))
    }

    func testLong() {
        XCTAssertEqual(transformer.transformValue("161803398875", dataType: .long) as? NSNumber, NSNumber(value: 161803398875))
        XCTAssertNil(transformer.transformValue("A Long string", dataType: .long))
    }

    func testFloat() {
        XCTAssertEqual(transformer.transformValue("1.5", dataType: .float) as? NSNumber, NSNumber(value: 1.5))
        XCTAssertEqual(transformer.transformValue("0.0", dataType: .float) as? NSNumber, NSNumber(value: 0.0))
        // Unparseable float returns NSNull (not nil), matching the ObjC original.
        XCTAssertTrue(transformer.transformValue("A Float string", dataType: .float) is NSNull)
    }

    func testNullAndNil() {
        XCTAssertNil(transformer.transformValue(nil, dataType: .string))
        XCTAssertNil(transformer.transformValue(NSNull(), dataType: .string))

        for dataType in [MPDataTypeSwift.int, .long] {
            XCTAssertEqual(transformer.transformValue(nil, dataType: dataType) as? NSNumber, NSNumber(value: 0))
            XCTAssertEqual(transformer.transformValue(NSNull(), dataType: dataType) as? NSNumber, NSNumber(value: 0))
        }

        XCTAssertEqual(transformer.transformValue(nil, dataType: .float) as? NSNumber, NSNumber(value: 0))
        XCTAssertEqual(transformer.transformValue(NSNull(), dataType: .float) as? NSNumber, NSNumber(value: 0))

        XCTAssertEqual(transformer.transformValue(nil, dataType: .bool) as? NSNumber, NSNumber(value: false))
        XCTAssertEqual(transformer.transformValue(NSNull(), dataType: .bool) as? NSNumber, NSNumber(value: false))
    }

    // customAttributes are `[String: id]` and reach the projection path un-stringified, so values
    // can be NSNumber. The ObjC original coerced these via integerValue/floatValue; verify parity.
    func testNumberInputs() {
        XCTAssertEqual(
            transformer.transformValue(NSNumber(value: 1618033), dataType: .int) as? NSNumber,
            NSNumber(value: 1618033)
        )
        XCTAssertEqual(
            transformer.transformValue(NSNumber(value: 161803398875), dataType: .long) as? NSNumber,
            NSNumber(value: 161803398875)
        )
        XCTAssertEqual(transformer.transformValue(NSNumber(value: 1.5), dataType: .float) as? NSNumber, NSNumber(value: 1.5))
        // Matches ObjC [@(1.5) integerValue] == 1
        XCTAssertEqual(transformer.transformValue(NSNumber(value: 1.5), dataType: .int) as? NSNumber, NSNumber(value: 1))
        XCTAssertEqual(transformer.transformValue(NSNumber(value: 0), dataType: .int) as? NSNumber, NSNumber(value: 0))
        // .string returns the object as-is
        XCTAssertEqual(transformer.transformValue(NSNumber(value: 42), dataType: .string) as? NSNumber, NSNumber(value: 42))
    }

    // Explicit decision (the ObjC original would have raised unrecognized-selector here):
    // an NSNumber bool attribute uses its boolValue; string parsing is unchanged.
    func testBoolFromNumber() {
        XCTAssertEqual(transformer.transformValue(NSNumber(value: true), dataType: .bool) as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(transformer.transformValue(NSNumber(value: false), dataType: .bool) as? NSNumber, NSNumber(value: false))
        XCTAssertEqual(transformer.transformValue(NSNumber(value: 1), dataType: .bool) as? NSNumber, NSNumber(value: true))
        XCTAssertEqual(transformer.transformValue(NSNumber(value: 0), dataType: .bool) as? NSNumber, NSNumber(value: false))
    }
}
