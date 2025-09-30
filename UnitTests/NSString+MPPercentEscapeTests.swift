import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class NSString_MPPercentEscapeTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testPercentEscape() {
        let array = ["288160084=2832403&-515079401=2832403&1546594223=2832403&264784951=2832403&4151713=2832403&-1663781220=2832403", "Test;Testing", "Test Testing", "AbCdEF"]
        let escapedArray = ["288160084=2832403&-515079401=2832403&1546594223=2832403&264784951=2832403&4151713=2832403&-1663781220=2832403", "Test%3BTesting", "Test%20Testing", "AbCdEF"]

        XCTAssertEqual(array[0].percentEscape(), escapedArray[0])
        XCTAssertEqual(array[1].percentEscape(), escapedArray[1])
        XCTAssertEqual(array[2].percentEscape(), escapedArray[2])
        XCTAssertEqual(array[3].percentEscape(), escapedArray[3])
    }
}
