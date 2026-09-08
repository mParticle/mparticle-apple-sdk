import Foundation

// Keeps the MPCookie Objective-C runtime name the deleted wrapper had, so the @class forward
// declaration and the -deleteCookie: / -fetchCookiesForUserId: signatures in
// Include/MPPersistenceController.h stay byte-identical. Reference MPCookiePRIVATE from Swift,
// MPCookie from Objective-C.
@objc(MPCookie)
public final class MPCookiePRIVATE: NSObject, NSSecureCoding {
    @objc public var cookieId: Int64 = 0

    private var storedContent: String?
    private var storedDomain: String?
    private var storedExpiration: String?
    private var storedName = ""

    @objc public var content: String? {
        get { storedContent }
        set { storedContent = newValue?.percentEscape() }
    }

    @objc public var domain: String? {
        get { storedDomain }
        set { storedDomain = newValue?.percentEscape() }
    }

    @objc public var expiration: String? {
        get { storedExpiration }
        set { storedExpiration = newValue?.percentEscape() }
    }

    @objc public var name: String {
        get { storedName }
        set { storedName = newValue.percentEscape() ?? newValue }
    }

    @objc override public init() {
        super.init()
    }

    @objc(initWithName:configuration:)
    public init?(name: Any?, configuration: Any?) {
        guard let name = name as? String, !MPSwiftIsNull(name),
              let configuration = configuration as? NSDictionary, !MPSwiftIsNull(configuration)
        else {
            return nil
        }

        super.init()

        func stringValue(_ value: Any?) -> String? {
            MPSwiftIsNull(value) ? nil : value as? String
        }

        self.name = name
        content = stringValue(configuration[Keys.content])
        domain = stringValue(configuration[Keys.domain])
        expiration = stringValue(configuration[Keys.expiration])
    }

    @objc public var expired: Bool {
        guard let expiration, !MPSwiftIsNull(expiration) else { return true }
        guard let cookieDate = MPDateFormatter.date(fromStringRFC3339: expiration) else { return false }
        return cookieDate.compare(Date()) == .orderedAscending
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        let dictionary = NSMutableDictionary()
        if let content { dictionary[Keys.content] = content }
        if let domain { dictionary[Keys.domain] = domain }
        if let expiration { dictionary[Keys.expiration] = expiration }
        return dictionary.allKeys.isEmpty ? nil : dictionary
    }

    @objc public func isEqual(toCookie other: MPCookiePRIVATE) -> Bool {
        name == other.name
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? MPCookiePRIVATE else { return false }
        return isEqual(toCookie: other)
    }

    override public var hash: Int {
        name.hashValue
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(name, forKey: CodingKeys.name)

        if let content { coder.encode(content, forKey: CodingKeys.content) }
        if let domain { coder.encode(domain, forKey: CodingKeys.domain) }
        if let expiration { coder.encode(expiration, forKey: CodingKeys.expiration) }
    }

    /// `content`, `domain` and `expiration` are encoded as strings, so they are decoded as strings.
    ///
    /// The deleted Objective-C wrapper passed `NSDictionary` as the expected class for all three,
    /// which never matches an `NSString`, so every restored cookie carried only its name.
    ///
    /// It went unnoticed because no production path archives a cookie — cookies are written as raw
    /// sqlite columns, and the only production archives are `MPUploadSettings` and a configuration
    /// dictionary. Cookies are archivable in principle: `MPConsumerInfo` conforms to
    /// `NSSecureCoding` and encodes its `cookies` array, and `MPConsumerInfoTests.testInstance`
    /// and `testConsumerInfoEncoding` do exercise that. Neither asserts the cookie fields, and
    /// `isEqual(toCookie:)` compares names only, so the round-trip assertions passed over the loss.
    public convenience init?(coder: NSCoder) {
        let name = coder.decodeObject(of: NSString.self, forKey: CodingKeys.name) as String?

        let configuration = NSMutableDictionary()
        if let content = coder.decodeObject(of: NSString.self, forKey: CodingKeys.content) {
            configuration[Keys.content] = content
        }
        if let domain = coder.decodeObject(of: NSString.self, forKey: CodingKeys.domain) {
            configuration[Keys.domain] = domain
        }
        if let expiration = coder.decodeObject(of: NSString.self, forKey: CodingKeys.expiration) {
            configuration[Keys.expiration] = expiration
        }

        self.init(name: name, configuration: configuration)
    }

    /// Private copies of the `kMPCKContent` / `kMPCKDomain` / `kMPCKExpiration` C globals declared
    /// in `MPConsumerInfo.h`. They stay Objective-C because Swift cannot emit C globals and
    /// Objective-C callers still reference them by name; this module cannot read them, so the
    /// three literals are duplicated here. Keep the two in step.
    private enum Keys {
        static let content = "c"
        static let domain = "d"
        static let expiration = "e"
    }

    private enum CodingKeys {
        static let name = "name"
        static let content = "content"
        static let domain = "domain"
        static let expiration = "expiration"
    }
}

@objc public final class MPConsumerInfoPRIVATE: NSObject {
    @objc public var consumerInfoId: Int64 = 0

    /// Assigned directly when restoring an already-escaped value from persistence or a decoder.
    /// New values supplied by callers must go through `escapeAndSetUniqueIdentifier` instead.
    @objc public var uniqueIdentifier: String?

    @objc public func escapeAndSetUniqueIdentifier(_ uniqueIdentifier: String?) {
        guard let uniqueIdentifier, !MPSwiftIsNull(uniqueIdentifier) else { return }
        self.uniqueIdentifier = uniqueIdentifier.percentEscape()
    }
}
