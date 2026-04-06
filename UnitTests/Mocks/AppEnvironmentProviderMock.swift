import XCTest
import mParticle_Apple_SDK

class AppEnvironmentProviderMock: AppEnvironmentProviderProtocol {
    var isAppExtensionCalled = false
    var isAppExtensionReturnValue = false
    
    func isAppExtension() -> Bool {
        isAppExtensionCalled = true
        return isAppExtensionReturnValue
    }
}
