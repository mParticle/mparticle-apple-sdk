import Foundation

/// The push device-token accessors `MParticle` forwards to.
@objc(MPNotificationControllerProtocol) public protocol MPNotificationControllerProtocol {
    #if os(iOS)
    func deviceToken() -> Data?
    func setDeviceToken(_ devToken: Data?)
    #endif
}

/// Reads, changes and persists the push device token held by `DeviceTokenStore.shared`.
/// User defaults, the message queue and the device-ID call are supplied by the Objective-C
/// module, which this one cannot import, and are read on every use.
@objc(MPNotificationController_PRIVATE)
public final class MPNotificationControllerPRIVATE: NSObject, MPNotificationControllerProtocol {
    private let userDefaults: () -> MPUserDefaults
    private let messageQueue: () -> DispatchQueue
    private let modifyDeviceID: (_ deviceIdType: String, _ value: String, _ oldValue: String) -> Void

    @objc public init(
        userDefaults: @escaping () -> MPUserDefaults,
        messageQueue: @escaping () -> DispatchQueue,
        modifyDeviceID: @escaping (_ deviceIdType: String, _ value: String, _ oldValue: String) -> Void
    ) {
        self.userDefaults = userDefaults
        self.messageQueue = messageQueue
        self.modifyDeviceID = modifyDeviceID
        super.init()
    }

    #if os(iOS)
    /// kMPDeviceTokenKey in MPIConstants.m.
    private static let deviceTokenKey = "to"

    public func deviceToken() -> Data? {
        DeviceTokenStore.shared.adopt(persistedToken: userDefaults()[Self.deviceTokenKey] as? Data)
    }

    public func setDeviceToken(_ devToken: Data?) {
        let store = DeviceTokenStore.shared
        guard let change = store.change(to: devToken) else { return }

        messageQueue().async { [self] in
            store.post(change)

            if change.shouldModifyDeviceID, let value = change.newTokenString, let oldValue = change.oldTokenString {
                modifyDeviceID("push_token", value, oldValue)
            }

            // The change's own token, not the store's: any read through adopt(persistedToken:)
            // since the change has put the old persisted token back in the store.
            let defaults = userDefaults()
            defaults[Self.deviceTokenKey] = change.newToken
            defaults.synchronize()
        }
    }
    #endif
}
