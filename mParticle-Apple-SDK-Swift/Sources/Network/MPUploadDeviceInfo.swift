import Foundation

/// Applies the App Tracking Transparency status to an event upload's device-info
/// block: writes the wire status string, drops the advertiser id unless the user
/// authorized tracking, and stamps the ATT timestamp. Pure JSON transform — the
/// caller resolves the ATT status/timestamp and keeps compression and I/O.
@objc public final class MPUploadDeviceInfo: NSObject {
    // Mirrors MPIConstants wire keys.
    private enum Keys {
        static let deviceInfo = "di" // kMPDeviceInformationKey
        static let att = "atts" // kMPATT
        static let attTimestamp = "attt" // kMPATTTimestamp
        static let advertiserId = "aid" // kMPDeviceAdvertiserIdKey
    }

    // Mirrors MPATTAuthorizationStatus (MPEnums.h): 0 notDetermined, 1 restricted, 2 denied, 3 authorized.
    private static let authorizedStatus = 3

    /// Returns `uploadData` with ATT applied to its device-info block, or
    /// `uploadData` unchanged when it is not a JSON object.
    @objc(uploadDataApplyingATT:authStatus:authTimestamp:)
    public static func uploadDataApplyingATT(_ uploadData: Data, authStatus: Int, authTimestamp: NSNumber) -> Data {
        guard var uploadDict = (try? JSONSerialization.jsonObject(with: uploadData)) as? [AnyHashable: Any] else {
            return uploadData
        }

        // When there is no device-info block the original messaged a nil dictionary
        // and wrote nothing, so an absent (or non-dictionary) `di` is left untouched
        // rather than synthesizing a new block with ATT metadata.
        guard var deviceDict = uploadDict[Keys.deviceInfo] as? [AnyHashable: Any] else {
            return uploadData
        }

        if let status = wireStatus(authStatus) {
            deviceDict[Keys.att] = status
            if authStatus != authorizedStatus {
                deviceDict.removeValue(forKey: Keys.advertiserId)
            }
        }
        deviceDict[Keys.attTimestamp] = authTimestamp
        uploadDict[Keys.deviceInfo] = deviceDict

        guard let updated = try? JSONSerialization.data(withJSONObject: uploadDict) else {
            return uploadData
        }
        return updated
    }

    private static func wireStatus(_ authStatus: Int) -> String? {
        switch authStatus {
        case 0: return "not_determined"
        case 1: return "restricted"
        case 2: return "denied"
        case 3: return "authorized"
        default: return nil
        }
    }
}
