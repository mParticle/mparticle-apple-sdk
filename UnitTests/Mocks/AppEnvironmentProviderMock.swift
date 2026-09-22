import XCTest
import mParticle_Apple_SDK
internal import mParticle_Apple_SDK_Swift

class AppEnvironmentProviderMock: AppEnvironmentProviderProtocol {
    var isAppExtensionCalled = false
    var isAppExtensionReturnValue = false
    
    func isAppExtension() -> Bool {
        isAppExtensionCalled = true
        return isAppExtensionReturnValue
    }
}
