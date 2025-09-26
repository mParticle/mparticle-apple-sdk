//
//  MPUploadSettings.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 1/22/25.
//
private let kApiKey = "apiKey"
private let kSecret = "secret"
private let kEventsHost = "eventsHost"
private let kEventsTrackingHost = "eventsTrackingHost"
private let kOverridesEventsSubdirectory: String = "overridesEventsSubdirectory"
private let kAliasHost = "aliasHost"
private let kAliasTrackingHost = "aliasTrackingHost"
private let kOverridesAliasSubdirectory = "overridesAliasSubdirectory"
private let kEventsOnly = "eventsOnly"

@objc(MPUploadSettings)
public class MPUploadSettings: NSObject, NSCopying, NSSecureCoding {
    @objc public var apiKey: String
    @objc public var secret: String
    @objc public var eventsHost: String?
    @objc public var eventsTrackingHost: String?
    @objc public var overridesEventsSubdirectory: Bool = false
    @objc public var aliasHost: String?
    @objc public var aliasTrackingHost: String?
    @objc public var overridesAliasSubdirectory: Bool = false
    @objc public var eventsOnly: Bool = false

    @objc override public init() {
        apiKey = ""
        secret = ""
        super.init()
    }

    public func copy(with _: NSZone? = nil) -> Any {
        return MPUploadSettings(apiKey: apiKey,
                                secret: secret,
                                eventsHost: eventsHost,
                                eventsTrackingHost: eventsTrackingHost,
                                overridesEventsSubdirectory: overridesEventsSubdirectory,
                                aliasHost: aliasHost,
                                aliasTrackingHost: aliasTrackingHost,
                                overridesAliasSubdirectory: overridesAliasSubdirectory,
                                eventsOnly: eventsOnly)
    }

    public static var supportsSecureCoding: Bool = true

    public func encode(with coder: NSCoder) {
        coder.encode(apiKey, forKey: kApiKey)
        coder.encode(secret, forKey: kSecret)
        coder.encode(eventsHost, forKey: kEventsHost)
        coder.encode(eventsTrackingHost, forKey: kEventsTrackingHost)
        coder.encode(overridesEventsSubdirectory, forKey: kOverridesEventsSubdirectory)
        coder.encode(aliasHost, forKey: kAliasHost)
        coder.encode(aliasTrackingHost, forKey: kAliasTrackingHost)
        coder.encode(overridesAliasSubdirectory, forKey: kOverridesAliasSubdirectory)
        coder.encode(eventsOnly, forKey: kEventsOnly)
    }

    @objc public required init?(coder: NSCoder) {
        apiKey = coder.decodeObject(forKey: kApiKey) as? String ?? ""
        secret = coder.decodeObject(forKey: kSecret) as? String ?? ""
        eventsHost = coder.decodeObject(forKey: kEventsHost) as? String
        eventsTrackingHost = coder.decodeObject(forKey: kEventsTrackingHost) as? String
        overridesEventsSubdirectory = coder.decodeBool(forKey: kOverridesEventsSubdirectory)
        aliasHost = coder.decodeObject(forKey: kAliasHost) as? String
        aliasTrackingHost = coder.decodeObject(forKey: kAliasTrackingHost) as? String
        overridesAliasSubdirectory = coder.decodeBool(forKey: kOverridesAliasSubdirectory)
        eventsOnly = coder.decodeBool(forKey: kEventsOnly)
    }

    @objc public class func currentUploadSettings(stateMachine: MPStateMachineProtocol, networkOptions: MPNetworkOptions) -> MPUploadSettings {
        return MPUploadSettings(apiKey: stateMachine.apiKey, secret: stateMachine.secret, networkOptions: networkOptions)
    }

    @objc public init(apiKey: String, secret: String, eventsHost: String? = nil, eventsTrackingHost: String? = nil, overridesEventsSubdirectory: Bool = false, aliasHost: String? = nil, aliasTrackingHost: String? = nil, overridesAliasSubdirectory: Bool = false, eventsOnly: Bool = false) {
        self.apiKey = apiKey
        self.secret = secret
        self.eventsHost = eventsHost
        self.eventsTrackingHost = eventsTrackingHost
        self.overridesEventsSubdirectory = overridesEventsSubdirectory
        self.aliasHost = aliasHost
        self.aliasTrackingHost = aliasTrackingHost
        self.overridesAliasSubdirectory = overridesAliasSubdirectory
        self.eventsOnly = eventsOnly

        super.init()
    }

    @objc public init(apiKey: String, secret: String, networkOptions: MPNetworkOptions) {
        self.apiKey = apiKey
        self.secret = secret
        eventsHost = networkOptions.eventsHost
        eventsTrackingHost = networkOptions.eventsTrackingHost
        overridesEventsSubdirectory = networkOptions.overridesEventsSubdirectory
        aliasHost = networkOptions.aliasHost
        aliasTrackingHost = networkOptions.aliasTrackingHost
        overridesAliasSubdirectory = networkOptions.overridesAliasSubdirectory
        eventsOnly = networkOptions.eventsOnly

        super.init()
    }
}
