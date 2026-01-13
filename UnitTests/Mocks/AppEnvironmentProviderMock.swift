import XCTest
import mParticle_Apple_SDK_NoLocation

class AppEnvironmentProviderMock: AppEnvironmentProviderProtocol {
    var isAppExtensionCalled = false
    var isAppExtensionReturnValue = false
    
    func isAppExtension() -> Bool {
        isAppExtensionCalled = true
        return isAppExtensionReturnValue
    }
}
