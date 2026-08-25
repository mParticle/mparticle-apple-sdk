import Foundation

@objc public final class MPCookiePRIVATE: NSObject {
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
        content = stringValue(configuration["c"])
        domain = stringValue(configuration["d"])
        expiration = stringValue(configuration["e"])
    }

    @objc public var expired: Bool {
        guard let expiration, !MPSwiftIsNull(expiration) else { return true }
        guard let cookieDate = MPDateFormatter.date(fromStringRFC3339: expiration) else { return false }
        return cookieDate.compare(Date()) == .orderedAscending
    }

    @objc public func dictionaryRepresentation() -> NSDictionary? {
        let dictionary = NSMutableDictionary()
        if let content { dictionary["c"] = content }
        if let domain { dictionary["d"] = domain }
        if let expiration { dictionary["e"] = expiration }
        return dictionary.allKeys.isEmpty ? nil : dictionary
    }

    @objc public func isEqual(toCookie other: MPCookiePRIVATE) -> Bool {
        name == other.name
    }

    override public var hash: Int {
        name.hashValue
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
