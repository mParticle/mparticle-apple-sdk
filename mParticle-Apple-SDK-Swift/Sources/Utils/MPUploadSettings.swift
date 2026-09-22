import Foundation

@objc public final class MPUploadSettingsPRIVATE: NSObject {
    private enum Keys {
        static let apiKey = "apiKey"
        static let secret = "secret"
        static let eventsHost = "eventsHost"
        static let eventsTrackingHost = "eventsTrackingHost"
        static let overridesEventsSubdirectory = "overridesEventsSubdirectory"
        static let aliasHost = "aliasHost"
        static let aliasTrackingHost = "aliasTrackingHost"
        static let overridesAliasSubdirectory = "overridesAliasSubdirectory"
        static let eventsOnly = "eventsOnly"
    }

    @objc public var apiKey: String
    @objc public var secret: String
    @objc public var eventsHost: String?
    @objc public var eventsTrackingHost: String?
    @objc public var overridesEventsSubdirectory: Bool
    @objc public var aliasHost: String?
    @objc public var aliasTrackingHost: String?
    @objc public var overridesAliasSubdirectory: Bool
    @objc public var eventsOnly: Bool

    @objc public override init() {
        apiKey = ""
        secret = ""
        eventsHost = nil
        eventsTrackingHost = nil
        overridesEventsSubdirectory = false
        aliasHost = nil
        aliasTrackingHost = nil
        overridesAliasSubdirectory = false
        eventsOnly = false
    }

    @objc public init(apiKey: String,
                      secret: String,
                      eventsHost: String?,
                      eventsTrackingHost: String?,
                      overridesEventsSubdirectory: Bool,
                      aliasHost: String?,
                      aliasTrackingHost: String?,
                      overridesAliasSubdirectory: Bool,
                      eventsOnly: Bool) {
        self.apiKey = apiKey
        self.secret = secret
        self.eventsHost = eventsHost
        self.eventsTrackingHost = eventsTrackingHost
        self.overridesEventsSubdirectory = overridesEventsSubdirectory
        self.aliasHost = aliasHost
        self.aliasTrackingHost = aliasTrackingHost
        self.overridesAliasSubdirectory = overridesAliasSubdirectory
        self.eventsOnly = eventsOnly
    }

    @objc(initFromCoder:) public init(fromCoder coder: NSCoder) {
        apiKey = coder.decodeObject(of: NSString.self, forKey: Keys.apiKey) as String? ?? ""
        secret = coder.decodeObject(of: NSString.self, forKey: Keys.secret) as String? ?? ""
        eventsHost = coder.decodeObject(of: NSString.self, forKey: Keys.eventsHost) as String?
        eventsTrackingHost = coder.decodeObject(of: NSString.self, forKey: Keys.eventsTrackingHost) as String?
        overridesEventsSubdirectory = coder.decodeBool(forKey: Keys.overridesEventsSubdirectory)
        aliasHost = coder.decodeObject(of: NSString.self, forKey: Keys.aliasHost) as String?
        aliasTrackingHost = coder.decodeObject(of: NSString.self, forKey: Keys.aliasTrackingHost) as String?
        overridesAliasSubdirectory = coder.decodeBool(forKey: Keys.overridesAliasSubdirectory)
        eventsOnly = coder.decodeBool(forKey: Keys.eventsOnly)
    }

    @objc(encodeToCoder:) public func encode(to coder: NSCoder) {
        coder.encode(apiKey, forKey: Keys.apiKey)
        coder.encode(secret, forKey: Keys.secret)
        coder.encode(eventsHost, forKey: Keys.eventsHost)
        coder.encode(eventsTrackingHost, forKey: Keys.eventsTrackingHost)
        coder.encode(overridesEventsSubdirectory, forKey: Keys.overridesEventsSubdirectory)
        coder.encode(aliasHost, forKey: Keys.aliasHost)
        coder.encode(aliasTrackingHost, forKey: Keys.aliasTrackingHost)
        coder.encode(overridesAliasSubdirectory, forKey: Keys.overridesAliasSubdirectory)
        coder.encode(eventsOnly, forKey: Keys.eventsOnly)
    }

    @objc(resolvedHostWithCustomHost:host:) public static func resolvedHost(customHost: String?, host: String?) -> String? {
        customHost ?? host
    }
}
