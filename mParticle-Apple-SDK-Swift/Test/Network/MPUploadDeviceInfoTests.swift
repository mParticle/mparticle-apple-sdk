import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPUploadDeviceInfoTests: XCTestCase {
    private let timestamp = NSNumber(value: 1_700_000_000)

    private func transformedDeviceInfo(authStatus: Int,
                                       device: [String: Any] = ["aid": "ad-id", "os": "iOS"]) -> [String: Any] {
        let input = (try? JSONSerialization.data(withJSONObject: ["di": device, "mid": 7])) ?? Data()
        let output = MPUploadDeviceInfo.uploadDataApplyingATT(input, authStatus: authStatus, authTimestamp: timestamp)
        let dict = (try? JSONSerialization.jsonObject(with: output)) as? [String: Any]
        return (dict?["di"] as? [String: Any]) ?? [:]
    }

    func testAuthorizedKeepsAdvertiserId() {
        let di = transformedDeviceInfo(authStatus: 3)
        XCTAssertEqual(di["atts"] as? String, "authorized")
        XCTAssertEqual(di["aid"] as? String, "ad-id")
        XCTAssertEqual(di["attt"] as? NSNumber, timestamp)
    }

    func testDeniedDropsAdvertiserId() {
        let di = transformedDeviceInfo(authStatus: 2)
        XCTAssertEqual(di["atts"] as? String, "denied")
        XCTAssertNil(di["aid"])
    }

    func testNotDeterminedDropsAdvertiserId() {
        let di = transformedDeviceInfo(authStatus: 0)
        XCTAssertEqual(di["atts"] as? String, "not_determined")
        XCTAssertNil(di["aid"])
    }

    func testRestrictedDropsAdvertiserId() {
        let di = transformedDeviceInfo(authStatus: 1)
        XCTAssertEqual(di["atts"] as? String, "restricted")
        XCTAssertNil(di["aid"])
    }

    func testUnknownStatusStampsTimestampOnly() {
        let di = transformedDeviceInfo(authStatus: 99)
        XCTAssertNil(di["atts"])
        XCTAssertEqual(di["aid"] as? String, "ad-id")
        XCTAssertEqual(di["attt"] as? NSNumber, timestamp)
    }

    func testNonJSONInputIsReturnedUnchanged() {
        let junk = Data([0x00, 0x01, 0x02])
        let output = MPUploadDeviceInfo.uploadDataApplyingATT(junk, authStatus: 3, authTimestamp: timestamp)
        XCTAssertEqual(output, junk)
    }

    func testMissingDeviceInfoIsNotSynthesized() {
        let input = (try? JSONSerialization.data(withJSONObject: ["mid": 7])) ?? Data()
        let output = MPUploadDeviceInfo.uploadDataApplyingATT(input, authStatus: 2, authTimestamp: timestamp)
        let dict = (try? JSONSerialization.jsonObject(with: output)) as? [String: Any]
        XCTAssertNil(dict?["di"], "no device-info block should be synthesized when di is absent")
    }

    func testNonDictionaryDeviceInfoIsLeftUntouched() {
        let input = (try? JSONSerialization.data(withJSONObject: ["di": "not-a-dict", "mid": 7])) ?? Data()
        let output = MPUploadDeviceInfo.uploadDataApplyingATT(input, authStatus: 2, authTimestamp: timestamp)
        let dict = (try? JSONSerialization.jsonObject(with: output)) as? [String: Any]
        XCTAssertEqual(dict?["di"] as? String, "not-a-dict")
    }
}
