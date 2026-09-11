import Foundation

// Keeps the MPConsumerInfo Objective-C runtime name the deleted wrapper had, so the @class forward
// declaration and the -fetchConsumerInfoForUserId: / -saveConsumerInfo: / -updateConsumerInfo:
// signatures in Include/MPPersistenceAdapter.h stay byte-identical, along with the name this class
// archives under. Reference MPConsumerInfoPRIVATE from Swift, MPConsumerInfo from Objective-C.
@objc(MPConsumerInfo)
public final class MPConsumerInfoPRIVATE: NSObject, NSSecureCoding {
    @objc public var consumerInfoId: Int64 = 0

    @objc public var cookies: [MPCookiePRIVATE]?

    private var storedUniqueIdentifier: String?

    /// Reads through to the one-time `kMPRemoteConfigUniqueIdentifierKey` migration on first
    /// access: an identifier left in user defaults by an older SDK is adopted and the defaults
    /// entry removed. The adopted value is stored unescaped, exactly as the Objective-C wrapper
    /// stored it — only values supplied through the setter are escaped.
    @objc public var uniqueIdentifier: String? {
        get {
            if let storedUniqueIdentifier {
                return storedUniqueIdentifier
            }

            // nil before the Objective-C boundary has built the shared instance. Returning the
            // unmigrated value is the same answer as "nothing was stored", which is what every
            // caller before SDK start would have seen anyway.
            guard let userDefaults = MPUserDefaults.cached() else {
                return storedUniqueIdentifier
            }

            if let stored = userDefaults[RemoteConfig.kMPRemoteConfigUniqueIdentifierKey] {
                userDefaults.removeMPObject(forKey: RemoteConfig.kMPRemoteConfigUniqueIdentifierKey)
                storedUniqueIdentifier = MPSwiftIsNull(stored) ? nil : stored as? String
            }

            return storedUniqueIdentifier
        }
        set {
            guard let newValue, !MPSwiftIsNull(newValue) else { return }
            storedUniqueIdentifier = newValue.percentEscape()
        }
    }

    /// The `g` query parameter carried inside the `uid` cookie's content, or a fresh UUID when
    /// there is no such cookie. Computed once and then persisted, so the stamp is stable for the
    /// lifetime of the install.
    @objc public var deviceApplicationStamp: String? {
        guard let userDefaults = MPUserDefaults.cached() else { return nil }

        if let existing = userDefaults[Keys.deviceApplicationStampStorage] as? String {
            return existing
        }

        var value: String?
        for cookie in cookies ?? [] where cookie.name == Keys.uidCookieName {
            guard let content = cookie.content,
                  let components = URLComponents(string: "https://example.com/?\(content)")
            else {
                continue
            }
            // Last match wins, as in the Objective-C enumeration, which never stopped early.
            for item in components.queryItems ?? [] where item.name == Keys.deviceStampQueryItem {
                value = item.value
            }
        }

        let stamp = value ?? UUID().uuidString
        userDefaults[Keys.deviceApplicationStampStorage] = stamp
        userDefaults.synchronize()

        return stamp
    }

    @objc override public init() {
        super.init()
    }

    // MARK: - Configuration

    // Dictionaries below stay bridged to [AnyHashable: Any] rather than NSDictionary: the SwiftLint
    // empty_count rule rewrites a `.count == 0` test into `.isEmpty`, which NSDictionary does not
    // have, so an NSDictionary here compiles only until the formatter next touches the file.

    /// Applies the `ck` cookie table from a remote-configuration response.
    ///
    /// `existingCookies` are the cookies already persisted for the current user. They are passed in
    /// rather than fetched here because the persistence adapter is an Objective-C type this module
    /// cannot import; the one production caller already holds it. A configured cookie whose name
    /// matches an existing one updates that cookie in place instead of adding a duplicate.
    @objc(updateWithConfiguration:existingCookies:)
    public func update(withConfiguration configuration: Any?, existingCookies: [MPCookiePRIVATE]?) {
        guard let configuration = configuration as? [AnyHashable: Any], !configuration.isEmpty else {
            return
        }

        configureCookies(
            with: configuration[RemoteConfig.kMPRemoteConfigCookiesKey],
            existingCookies: existingCookies
        )
    }

    @objc(cookiesDictionaryRepresentation)
    public func cookiesDictionaryRepresentation() -> NSDictionary? {
        guard let cookies, !cookies.isEmpty else { return nil }

        var cookiesDictionary: [String: Any] = [:]
        for cookie in cookies {
            if let cookieDictionary = cookie.dictionaryRepresentation() {
                cookiesDictionary[cookie.name] = cookieDictionary
            }
        }

        return cookiesDictionary.isEmpty ? nil : cookiesDictionary as NSDictionary
    }

    @objc(configureCookiesWithDictionary:existingCookies:)
    public func configureCookies(with cookiesDictionary: Any?, existingCookies: [MPCookiePRIVATE]?) {
        guard var configured = cookiesDictionary as? [AnyHashable: Any] else { return }

        // Cookies an older SDK left in user defaults are folded in first, so a value from the
        // response still wins on a key collision. Reading them also clears them.
        if let local = localCookiesDictionary() {
            configured = local.merging(configured) { _, fromResponse in fromResponse }
        }

        var cookies = existingCookies ?? []
        for (key, value) in configured {
            guard !MPSwiftIsNull(key),
                  let cookie = MPCookiePRIVATE(name: key, configuration: value)
            else {
                continue
            }

            if let existing = cookies.first(where: { $0.name == cookie.name }) {
                existing.content = cookie.content
                existing.domain = cookie.domain
                existing.expiration = cookie.expiration
            } else {
                cookies.append(cookie)
            }
        }

        self.cookies = cookies
    }

    /// Drains the cookie table an older SDK stored in user defaults, returning it for merging.
    private func localCookiesDictionary() -> [AnyHashable: Any]? {
        guard let userDefaults = MPUserDefaults.cached() else { return nil }

        let key = RemoteConfig.kMPRemoteConfigCookiesKey
        guard let localCookies = userDefaults.mpObject(
            forKey: key,
            userId: MPUserDefaults.storedMpId()
        ) as? [AnyHashable: Any] else {
            return nil
        }

        userDefaults.removeMPObject(forKey: key)

        return localCookies
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        if let cookies {
            coder.encode(cookies, forKey: CodingKeys.cookies)
        }
        if let uniqueIdentifier {
            coder.encode(uniqueIdentifier, forKey: CodingKeys.uniqueIdentifier)
        }
    }

    /// The allowed-class set names MPCookiePRIVATE as well as NSArray, which the deleted
    /// Objective-C wrapper did not: `decodeObjectOfClass:[NSArray<MPCookie *> class]` erases its
    /// generic, so the set held NSArray alone. That is invisible on every path the SDK uses, since
    /// NSCoder only enforces the set when `requiresSecureCoding` is true and no production path
    /// archives a consumer info — but under `unarchivedObject(ofClass:)` the nested cookies set
    /// `NSCoder.error`, which fails the whole unarchive rather than just dropping the cookies.
    /// Naming both classes leaves every current caller's result unchanged.
    public init?(coder: NSCoder) {
        super.init()

        cookies = coder.decodeObject(
            of: [NSArray.self, MPCookiePRIVATE.self],
            forKey: CodingKeys.cookies
        ) as? [MPCookiePRIVATE]

        // Assigned to storage rather than through the setter: the archived value was escaped on
        // the way in and must not be escaped again.
        storedUniqueIdentifier = coder.decodeObject(
            of: NSString.self,
            forKey: CodingKeys.uniqueIdentifier
        ) as String?
    }

    private enum Keys {
        // kMPDeviceApplicationStampStorageKey in MPIConstants.h.
        static let deviceApplicationStampStorage = "dast"
        static let uidCookieName = "uid"
        static let deviceStampQueryItem = "g"
    }

    private enum CodingKeys {
        static let cookies = "cookies"
        static let uniqueIdentifier = "uniqueIdentifier"
    }
}
