import XCTest
import mParticle_Apple_SDK_NoLocation

class SettingsProviderMock: NSObject, SettingsProviderProtocol {
    var configSettings: NSMutableDictionary?
}
