import XCTest
import mParticle_Apple_SDK_Swift

class MPCustomModulePreferenceLogicTests: XCTestCase {
    private typealias Logic = CustomModulePreferenceLogic

    private let fixedUUID = UUID(uuidString: "0123ABCD-0000-0000-0102-030405060708")!

    // MARK: - isMacroPlaceholder

    func testRecognisesEveryMacroPlaceholder() {
        for placeholder in ["%gn%", "%oaid%", "%dt%", "%glsb%", "%g%"] {
            XCTAssertTrue(Logic.isMacroPlaceholder(placeholder), placeholder)
        }
    }

    func testRejectsNonMacroValues() {
        XCTAssertFalse(Logic.isMacroPlaceholder("vid"))
        XCTAssertFalse(Logic.isMacroPlaceholder(""))
        XCTAssertFalse(Logic.isMacroPlaceholder("%unknown%"))
        XCTAssertFalse(Logic.isMacroPlaceholder(nil as Any?))
        XCTAssertFalse(Logic.isMacroPlaceholder(NSNull()))
        XCTAssertFalse(Logic.isMacroPlaceholder(42))
    }

    // MARK: - defaultValue(forDataType:)

    func testDefaultValuePerDataType() {
        XCTAssertEqual(Logic.defaultValue(forDataType: 1), "")
        XCTAssertEqual(Logic.defaultValue(forDataType: 2), "0")
        XCTAssertEqual(Logic.defaultValue(forDataType: 3), "false")
        XCTAssertEqual(Logic.defaultValue(forDataType: 4), "0.0")
        XCTAssertEqual(Logic.defaultValue(forDataType: 5), "0")
    }

    func testDefaultValueIsNilForUnknownDataType() {
        XCTAssertNil(Logic.defaultValue(forDataType: 0))
        XCTAssertNil(Logic.defaultValue(forDataType: 99))
    }

    // MARK: - value(forDefaultValue:dataType:)

    func testStringValuePassesThrough() {
        XCTAssertEqual(Logic.value(forDefaultValue: "hello", dataType: 1) as? String, "hello")
    }

    func testIntegerValuesUseNSStringParsing() {
        XCTAssertEqual(Logic.value(forDefaultValue: "42", dataType: 2) as? NSNumber, NSNumber(value: 42))
        XCTAssertEqual(Logic.value(forDefaultValue: "42", dataType: 5) as? NSNumber, NSNumber(value: 42))
        XCTAssertEqual(Logic.value(forDefaultValue: "-7", dataType: 2) as? NSNumber, NSNumber(value: -7))
    }

    func testIntegerParsingToleratesTrailingCharacters() {
        XCTAssertEqual(Logic.value(forDefaultValue: "12abc", dataType: 2) as? NSNumber, NSNumber(value: 12))
        XCTAssertEqual(Logic.value(forDefaultValue: "abc", dataType: 2) as? NSNumber, NSNumber(value: 0))
    }

    func testBooleanFalseStrings() {
        for falseValue in ["false", "NO", "0"] {
            XCTAssertEqual(Logic.value(forDefaultValue: falseValue, dataType: 3) as? NSNumber,
                           NSNumber(value: false),
                           falseValue)
        }
    }

    func testBooleanTrueForAnythingElse() {
        for trueValue in ["true", "YES", "1", "", "False", "no"] {
            XCTAssertEqual(Logic.value(forDefaultValue: trueValue, dataType: 3) as? NSNumber,
                           NSNumber(value: true),
                           trueValue)
        }
    }

    func testFloatValues() {
        XCTAssertEqual(Logic.value(forDefaultValue: "3.5", dataType: 4) as? NSNumber, NSNumber(value: Float(3.5)))
        XCTAssertEqual(Logic.value(forDefaultValue: "0.0", dataType: 4) as? NSNumber, NSNumber(value: Float(0)))
    }

    func testValueIsNilForUnknownDataType() {
        XCTAssertNil(Logic.value(forDefaultValue: "anything", dataType: 0))
    }

    // MARK: - Macro expansion

    func testUndashedUUIDStripsAllDashes() {
        let undashed = Logic.undashedUUID(fixedUUID)
        XCTAssertEqual(undashed.count, 32)
        XCTAssertFalse(undashed.contains("-"))
    }

    func testPlainGuidMacroUsesFullUUIDString() {
        let result = Logic.defaultValue(forMacroPlaceholder: "%g%", uuid: { self.fixedUUID }, date: { Date() })
        XCTAssertEqual(result, fixedUUID.uuidString)
    }

    func testUndashedGuidMacro() {
        let result = Logic.defaultValue(forMacroPlaceholder: "%gn%", uuid: { self.fixedUUID }, date: { Date() })
        XCTAssertEqual(result, Logic.undashedUUID(fixedUUID))
        XCTAssertEqual(result.count, 32)
    }

    func testDateMacroIsFormattedInUTC() {
        let date = Date(timeIntervalSince1970: 1600000000)
        let result = Logic.defaultValue(forMacroPlaceholder: "%dt%", uuid: { self.fixedUUID }, date: { date })
        XCTAssertEqual(result, "2020-09-13 12:26:40 +0000")
    }

    func testUnknownMacroReturnsEmptyString() {
        let result = Logic.defaultValue(forMacroPlaceholder: "%nope%", uuid: { self.fixedUUID }, date: { Date() })
        XCTAssertEqual(result, "")
    }

    // MARK: - %glsb%

    func testLeastSignificantBitsAssemblesBytesBigEndian() {
        let uuid = UUID(uuidString: "00000000-0000-0000-0102-030405060708")!
        XCTAssertEqual(Logic.leastSignificantBits(of: uuid), "72623859790382856")
    }

    func testLeastSignificantBitsIsSigned() {
        let uuid = UUID(uuidString: "00000000-0000-0000-FF00-000000000000")!
        XCTAssertEqual(Logic.leastSignificantBits(of: uuid), "-72057594037927936")
    }

    func testLeastSignificantBitsIgnoresLeadingBytes() {
        let a = UUID(uuidString: "11111111-1111-1111-0102-030405060708")!
        let b = UUID(uuidString: "22222222-2222-2222-0102-030405060708")!
        XCTAssertEqual(Logic.leastSignificantBits(of: a), Logic.leastSignificantBits(of: b))
    }

    // MARK: - %oaid%

    func testAdvertisingIdentifierLeavesLowCharactersAlone() {
        let result = Logic.advertisingIdentifier(from: "0123456789abcdef0123456789abcdef") { _ in
            XCTFail("should not need a random value")
            return 0
        }
        XCTAssertEqual(result, "0123456789abcdef-0123456789abcdef")
    }

    func testAdvertisingIdentifierClampsHighCharacters() {
        let result = Logic.advertisingIdentifier(from: "f123456789abcdef9123456789abcdef") { bound in
            bound == 8 ? 5 : 2
        }
        XCTAssertEqual(result, "5123456789abcdef-2123456789abcdef")
    }

    func testAdvertisingIdentifierShape() {
        let result = Logic.advertisingIdentifier(from: Logic.undashedUUID(UUID()))
        XCTAssertEqual(result.count, 33)

        let characters = Array(result)
        XCTAssertEqual(characters[16], "-")
        XCTAssertLessThan(characters[0].asciiValue ?? 0, UInt8(ascii: "8"))
        XCTAssertLessThan(characters[17].asciiValue ?? 0, UInt8(ascii: "4"))
    }

    func testAdvertisingIdentifierReturnsInputWhenTooShort() {
        XCTAssertEqual(Logic.advertisingIdentifier(from: "abc"), "abc")
    }
}
