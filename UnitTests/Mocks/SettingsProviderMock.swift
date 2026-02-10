import XCTest
import mParticle_Apple_SDK

class SettingsProviderMock: NSObject, SettingsProviderProtocol {
    var configSettings: NSMutableDictionary?
}
