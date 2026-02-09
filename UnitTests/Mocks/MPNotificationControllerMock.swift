import XCTest
import mParticle_Apple_SDK

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
