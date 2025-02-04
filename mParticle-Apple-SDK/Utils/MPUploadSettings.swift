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

@objc public class MPUploadSettings: NSObject, NSCopying, NSSecureCoding {
    @objc public var apiKey: String
    @objc public var secret: String
    @objc public var eventsHost: String?
    @objc public var eventsTrackingHost: String?
    @objc public var overridesEventsSubdirectory: Bool = false
    @objc public var aliasHost: String?
    @objc public var aliasTrackingHost: String?
    @objc public var overridesAliasSubdirectory: Bool = false
    @objc public var eventsOnly: Bool = false
    
    @objc public override init() {
        self.apiKey = ""
        self.secret = ""
        super.init()
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return MPUploadSettings(apiKey: self.apiKey,
                                secret: self.secret,
                                eventsHost: self.eventsHost,
                                eventsTrackingHost: self.eventsTrackingHost,
                                overridesEventsSubdirectory: self.overridesEventsSubdirectory,
                                aliasHost: self.aliasHost,
                                aliasTrackingHost: self.aliasTrackingHost,
                                overridesAliasSubdirectory: self.overridesAliasSubdirectory,
                                eventsOnly: self.eventsOnly)
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
        self.apiKey = coder.decodeObject(forKey: kApiKey) as? String ?? ""
        self.secret = coder.decodeObject(forKey: kSecret) as? String ?? ""
        self.eventsHost = coder.decodeObject(forKey: kEventsHost) as? String
        self.eventsTrackingHost = coder.decodeObject(forKey: kEventsTrackingHost) as? String
        self.overridesEventsSubdirectory = coder.decodeBool(forKey: kOverridesEventsSubdirectory)
        self.aliasHost = coder.decodeObject(forKey: kAliasHost) as? String
        self.aliasTrackingHost = coder.decodeObject(forKey: kAliasTrackingHost) as? String
        self.overridesAliasSubdirectory = coder.decodeBool(forKey: kOverridesAliasSubdirectory)
        self.eventsOnly = coder.decodeBool(forKey: kEventsOnly)
        
    }
    
    @objc public class func currentUploadSettings(stateMachine: MPStateMachine_PRIVATE, networkOptions: MPNetworkOptions) -> MPUploadSettings {
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
        self.eventsHost = networkOptions.eventsHost
        self.eventsTrackingHost = networkOptions.eventsTrackingHost
        self.overridesEventsSubdirectory = networkOptions.overridesEventsSubdirectory
        self.aliasHost = networkOptions.aliasHost
        self.aliasTrackingHost = networkOptions.aliasTrackingHost
        self.overridesAliasSubdirectory = networkOptions.overridesAliasSubdirectory
        self.eventsOnly = networkOptions.eventsOnly
        
        super.init()
    }
}
