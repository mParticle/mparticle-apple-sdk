import XCTest
@testable import mParticle_Apple_SDK_Swift

class MPStateMachineMPDeviceMock: MPStateMachineMPDeviceProtocol {
    var deviceTokenType: String?
    var attAuthorizationStatus: NSNumber?
    var attAuthorizationTimestamp: NSNumber?
}

class MPIdentityApiMPUserDefaultsMock: MPIdentityApiMPUserDefaultsProtocol {
    var map: [String: Any] = [:]

    subscript(key: String) -> Any? {
        get {
            return map[key]
        }
        set(newValue) {
            map[key] = newValue
        }
    }
}

class MPIdentityApiMPDeviceMock: MPIdentityApiMPDeviceProtocol {
    func currentUserIdentities() -> [NSNumber: String]? {
        return nil
    }

    func userIdentities(mpId: NSNumber) -> [NSNumber: String]? {
        return nil
    }
}

final class MPDeviceTests: XCTestCase {

    func testDictionaryDescription() {
        let kMPDeviceTokenKey = "to"
        let testDeviceToken = Data("<000000000000000000000000000000>".utf8)
        let userDefaults = MPIdentityApiMPUserDefaultsMock()
        userDefaults[kMPDeviceTokenKey] = testDeviceToken

        let testCountry = Locale.current.region?.identifier

        let logger = MPLog(logLevel: .debug)

        let device = MPDevice(
            stateMachine: MPStateMachineMPDeviceMock(),
            userDefaults: userDefaults,
            identity: MPIdentityApiMPDeviceMock(),
            logger: logger
        )

        let testDictionary = device.dictionaryRepresentation(withMpid: 1)

        XCTAssertEqual(testDictionary["dll"] as? String, "en")
        XCTAssertEqual(testDictionary["dlc"] as? String, testCountry)
        XCTAssertEqual(testDictionary["dma"] as? String, "Apple")
    }
}
