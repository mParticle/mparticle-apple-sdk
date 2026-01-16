import XCTest
import mParticle_Apple_SDK_NoLocation

class MParticleSessionMParticlePrivateTests: XCTestCase {
    func testInit() {
        let sut = MParticleSession(uuid: "UUID")
        XCTAssertEqual(sut?.sessionID, 8_993_343_810_776_384_128 as NSNumber)
        XCTAssertEqual(sut?.uuid, "UUID")
    }
}
