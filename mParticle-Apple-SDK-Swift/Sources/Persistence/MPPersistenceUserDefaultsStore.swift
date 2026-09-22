import Foundation

protocol MPPersistenceKeyValueStorage: AnyObject {
    func mpObject(forKey key: String, userId: NSNumber) -> Any?
    func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber)
    func removeMPObject(forKey key: String, userId: NSNumber)
    func synchronize()
}

extension MPUserDefaults: MPPersistenceKeyValueStorage {}

final class MPPersistenceConsentStringStore {
    private enum Keys {
        static let userConsent = "consent_state"
        static let deviceConsent = "device_consent_state"
    }

    private let storage: MPPersistenceKeyValueStorage

    init(storage: MPPersistenceKeyValueStorage) {
        self.storage = storage
    }

    func consentString(forMpid mpid: NSNumber) -> String? {
        storage.mpObject(forKey: Keys.userConsent, userId: mpid) as? String
    }

    func setConsentString(_ value: String?, forMpid mpid: NSNumber) {
        set(value, key: Keys.userConsent, userId: mpid)
    }

    func deviceConsentString() -> String? {
        storage.mpObject(forKey: Keys.deviceConsent, userId: 0) as? String
    }

    func setDeviceConsentString(_ value: String?) {
        set(value, key: Keys.deviceConsent, userId: 0)
    }

    func effectiveConsentString(forMpid mpid: NSNumber?) -> String? {
        if let device = deviceConsentString() {
            return device
        }
        return mpid.flatMap(consentString(forMpid:))
    }

    private func set(_ value: String?, key: String, userId: NSNumber) {
        if let value {
            storage.setMPObject(value, forKey: key, userId: userId)
        } else {
            storage.removeMPObject(forKey: key, userId: userId)
        }
        storage.synchronize()
    }
}
