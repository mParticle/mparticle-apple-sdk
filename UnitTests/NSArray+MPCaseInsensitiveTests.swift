import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class NSArray_MPCaseInsensitiveTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

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
}
