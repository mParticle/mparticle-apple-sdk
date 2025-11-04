import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MParticleSessionMParticlePrivateTests: XCTestCase {
    func testInit() {
        let sut = MParticleSession(uuid: "UUID")
        XCTAssertEqual(sut?.sessionID, 8_993_343_810_776_384_128 as NSNumber)
        XCTAssertEqual(sut?.uuid, "UUID")
    }
}
