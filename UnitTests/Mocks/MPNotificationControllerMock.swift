import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MPNotificationControllerMock: MPNotificationControllerProtocol {
    var deviceTokenCalled = false
    var deviceTokenReturnValue: Data?
    
    func deviceToken() -> Data? {
        deviceTokenCalled = true
        return deviceTokenReturnValue
    }
    
    var setDeviceTokenCalled = false
    var setDeviceTokenParam: Data?
    
    func setDeviceToken(_ deviceToken: Data?) {
        setDeviceTokenCalled = true
        setDeviceTokenParam = deviceToken
    }
}
