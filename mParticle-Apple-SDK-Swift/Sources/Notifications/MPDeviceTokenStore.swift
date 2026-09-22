import Foundation

/// The result of a push device-token transition: the notification payload to post,
/// and the token strings the device-ID modification call needs.
@objc(MPDeviceTokenChange) public final class DeviceTokenChange: NSObject {
    @objc public let userInfo: [String: Any]
    @objc public let newTokenString: String?
    @objc public let oldTokenString: String?

    /// Mirrors `if (oldTokenString && newTokenString)` — an empty token yields a nil
    /// string from `stringFromDeviceToken`, so it does not report a device-ID change.
    @objc public var shouldModifyDeviceID: Bool {
        return newTokenString != nil && oldTokenString != nil
    }

    init(newToken: Data?, oldToken: Data?) {
        var userInfo: [String: Any] = [:]

        if let newToken = newToken {
            userInfo[Notifications.kMPRemoteNotificationDeviceTokenKey.rawValue] = newToken
            newTokenString = MPUserDefaults.stringFromDeviceToken(newToken)
        } else {
            newTokenString = nil
        }

        if let oldToken = oldToken {
            userInfo[Notifications.kMPRemoteNotificationOldDeviceTokenKey.rawValue] = oldToken
            oldTokenString = MPUserDefaults.stringFromDeviceToken(oldToken)
        } else {
            oldTokenString = nil
        }

        self.userInfo = userInfo

        super.init()
    }
}

/// Owns the process-wide push device token. Replaces the file-static `NSData *deviceToken`
/// in MPNotificationController.m; persistence stays on the ObjC side, which cannot be
/// reached from here.
@objc(MPDeviceTokenStore) public final class DeviceTokenStore: NSObject {
    @objc public static let shared = DeviceTokenStore()

    private let lock = NSLock()
    private var token: Data?

    @objc override public init() {
        super.init()
    }

    @objc(currentToken)
    public func currentToken() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    /// The getter path: the ObjC property reloaded the token from persistence on every
    /// read and left the process-wide value holding whatever it found, nil included.
    @objc(adoptPersistedToken:)
    public func adopt(persistedToken: Data?) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        token = persistedToken
        return token
    }

    /// Returns nil when there is nothing to do.
    ///
    /// Mirrors `if ([deviceToken isEqualToData:devToken]) return;`, which messages a nil
    /// receiver while no token is stored and so returns NO — meaning a transition out of
    /// "no token", nil-to-nil included, proceeds rather than short-circuiting.
    @objc(changeToToken:)
    public func change(to newToken: Data?) -> DeviceTokenChange? {
        lock.lock()
        defer { lock.unlock() }

        if let existing = token, existing == newToken {
            return nil
        }

        let oldToken = token
        token = newToken
        return DeviceTokenChange(newToken: newToken, oldToken: oldToken)
    }

    @objc(postChange:)
    public func post(_ change: DeviceTokenChange) {
        NotificationCenter.default.post(name: Notifications.kMPRemoteNotificationDeviceTokenNotification,
                                        object: nil,
                                        userInfo: change.userInfo)
    }
}
