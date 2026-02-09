import XCTest
import mParticle_Apple_SDK

class MPNetworkOptionsMParticlePrivateTests: XCTestCase {
    func testInit() {
        let sut = MPNetworkOptions()

        XCTAssertFalse(sut.pinningDisabledInDevelopment)
        XCTAssertFalse(sut.pinningDisabled)
        XCTAssertFalse(sut.overridesConfigSubdirectory)
        XCTAssertFalse(sut.overridesEventsSubdirectory)
        XCTAssertFalse(sut.overridesIdentitySubdirectory)
        XCTAssertFalse(sut.overridesAliasSubdirectory)
        XCTAssertFalse(sut.eventsOnly)

        XCTAssertNil(sut.configHost)
        XCTAssertNil(sut.eventsHost)
        XCTAssertNil(sut.eventsTrackingHost)
        XCTAssertNil(sut.identityHost)
        XCTAssertNil(sut.identityTrackingHost)
        XCTAssertNil(sut.aliasHost)
        XCTAssertNil(sut.aliasTrackingHost)
        XCTAssertEqual(sut.certificates, [])
    }

    func testDescription() {
        let sut = MPNetworkOptions()
        sut.configHost = "configHost"
        sut.eventsHost = "eventsHost"
        sut.eventsTrackingHost = "eventsTrackingHost"
        sut.identityHost = "identityHost"
        sut.identityTrackingHost = "identityTrackingHost"
        sut.aliasHost = "aliasHost"
        sut.aliasTrackingHost = "aliasTrackingHost"
        sut.certificates = []
        XCTAssertEqual(
            sut.description,
            """
            MPNetworkOptions {
              configHost: configHost
              overridesConfigSubdirectory: false
              eventsHost: eventsHost
              eventsTrackingHost: eventsTrackingHost
              overridesEventSubdirectory: false
              identityHost: identityHost
              identityTrackingHost: identityTrackingHost
              overridesIdentitySubdirectory: false
              aliasHost: aliasHost
              aliasTrackingHost: aliasTrackingHost
              overridesAliasSubdirectory: false
              certificates: (
            )
              pinningDisabledInDevelopment: false
              pinningDisabled: false
              eventsOnly: false
            }
            """
        )
    }
}
