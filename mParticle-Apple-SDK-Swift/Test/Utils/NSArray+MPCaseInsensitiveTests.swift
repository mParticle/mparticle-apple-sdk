import XCTest
import mParticle_Apple_SDK_Swift

class NSArrayMPCaseInsensitiveTests: XCTestCase {
    override func setUp() {}

    override func tearDown() {}

    func testArrayTrue() {
        let array = ["someWord", "someOtherWord", "ABC", "AbCdEF"]
        XCTAssertTrue(array.caseInsensitiveContainsObject("someWord"))
        XCTAssertTrue(array.caseInsensitiveContainsObject("ABC"))
        XCTAssertTrue(array.caseInsensitiveContainsObject("someotherword"))
        XCTAssertTrue(array.caseInsensitiveContainsObject("abcdef"))
    }

    func testArrayFalse() {
        let array = ["someWord", "someOtherWord", "ABC", "AbCdEF"]
        XCTAssertFalse(array.caseInsensitiveContainsObject("somWord"))
        XCTAssertFalse(array.caseInsensitiveContainsObject("ABCD"))
        XCTAssertFalse(array.caseInsensitiveContainsObject("someotherwords"))
        XCTAssertFalse(array.caseInsensitiveContainsObject("abcdefg"))
    }

    func testNSArrayTrue() {
        let nsArray = ["someWord", "someOtherWord", "ABC", "AbCdEF"] as NSArray
        XCTAssertTrue(nsArray.caseInsensitiveContainsObject("someWord"))
        XCTAssertTrue(nsArray.caseInsensitiveContainsObject("ABC"))
        XCTAssertTrue(nsArray.caseInsensitiveContainsObject("someotherword"))
        XCTAssertTrue(nsArray.caseInsensitiveContainsObject("abcdef"))
    }

    func testNSArrayFalse() {
        let nsArray = ["someWord", "someOtherWord", "ABC", "AbCdEF"] as NSArray
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject("somWord"))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject("ABCD"))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject("someotherwords"))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject("abcdefg"))
    }

    // Objective-C callers in the kit projection engine pass raw attribute values, which can be
    // any class. A String parameter would be bridged before the body ran, raising instead.
    func testNSArrayNonStringArgument() {
        let nsArray = ["someWord", "someOtherWord", "ABC", "AbCdEF"] as NSArray
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject(NSNull()))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject(NSNumber(value: 25)))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject(["someWord"] as NSArray))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject(nil))
    }

    func testNSArrayWithNonStringElements() {
        let nsArray = [NSNull(), NSNumber(value: 25), "someWord"] as NSArray
        XCTAssertTrue(nsArray.caseInsensitiveContainsObject("SOMEWORD"))
        XCTAssertFalse(nsArray.caseInsensitiveContainsObject("25"))
    }
}
