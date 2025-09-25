import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class mParticle_Swift_SDKTests: XCTestCase {
    
    func testNewMPIdentityResponseErrorCodes() {
        XCTAssertNotNil(MPIdentityErrorResponseCode(rawValue: 500))
        XCTAssertNotNil(MPIdentityErrorResponseCode(rawValue: 502))
    }
    
    func testMPIdentityApiRequestIdentitiesInterop() {
        let request = MPIdentityApiRequest()
        request.setIdentity("test id", identityType: .customerId)
        request.setIdentity("test@test.com", identityType: .email)
                
        var identities = [NSNumber: NSObject]()
        identities[NSNumber(value: MPIdentity.customerId.rawValue)] = NSString(string: "test id")
        identities[NSNumber(value: MPIdentity.email.rawValue)] = NSString(string: "test@test.com")
        XCTAssertEqual(identities, request.identities);
        
        request.email = nil
        identities[NSNumber(value: MPIdentity.email.rawValue)] = NSNull()
        XCTAssertEqual(identities, request.identities);
    }
}
