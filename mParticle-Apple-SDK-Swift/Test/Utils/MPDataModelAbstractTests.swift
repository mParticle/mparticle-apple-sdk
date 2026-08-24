import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPDataModelAbstractTests: XCTestCase {
    func testCopyUUIDWithValue() {
        XCTAssertEqual(MPDataModelAbstractPRIVATE.copyUUID("abc"), "abc")
    }

    func testCopyUUIDWithNil() {
        XCTAssertNil(MPDataModelAbstractPRIVATE.copyUUID(nil))
    }

    func testCopyUUIDReturnsIndependentValue() {
        var original = "abc"
        let copy = MPDataModelAbstractPRIVATE.copyUUID(original)
        original += "-mutated"
        XCTAssertEqual(copy, "abc")
        XCTAssertNotEqual(original, copy)
    }
}
