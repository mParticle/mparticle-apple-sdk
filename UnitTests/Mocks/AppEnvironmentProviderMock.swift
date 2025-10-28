import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class AppEnvironmentProviderMock: AppEnvironmentProviderProtocol {
    var isAppExtensionCalled = false
    var isAppExtensionReturnValue = false
    
    func isAppExtension() -> Bool {
        isAppExtensionCalled = true
        return isAppExtensionReturnValue
    }
}
