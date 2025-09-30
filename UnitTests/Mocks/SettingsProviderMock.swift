import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class SettingsProviderMock: NSObject, SettingsProviderProtocol {
    var configSettings: NSMutableDictionary?
}
