import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif


class MPUserDefaultsMock: MPUserDefaultsProtocol {
    var setMPObjectCalled = false
    var setMPObjectValueParam: Any?
    var setMPObjectKeyParam: String?
    var setMPObjectUserIdParam: NSNumber?
    
    func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber) {
        setMPObjectCalled = true
        setMPObjectValueParam = value
        setMPObjectKeyParam = key
        setMPObjectUserIdParam = userId
    }
    
    var synchronizeCalled = false
    
    func synchronize() {
        synchronizeCalled = true
    }
}
