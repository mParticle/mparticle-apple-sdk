//
//  MPNetworkOptions.swift
//  mParticle-Apple-SDK
//
//  Created on 12/18/24.
//

import Foundation

/**
 Allows you to override the default HTTPS hosts and certificates used by the SDK.
 */
@objcMembers
public class MPNetworkOptions: NSObject {
    /**
     Allows you to override the default configuration host.
     */
    public var configHost: String?
    
    /**
     Defaults to false. If set true the configHost above will overwrite the subdirectory of the URL in addition to the host.
     */
    public var overridesConfigSubdirectory: Bool = false
    
    /**
     Allows you to override the default event host.
     */
    public var eventsHost: String?
    
    /**
     Allows you to override the tracking event host. Set this to automatically use an alternate custom domain when ATTStatus has been authorized.
     */
    public var eventsTrackingHost: String?
    
    /**
     Defaults to false. If set true the eventsHost above will overwrite the subdirectory of the URL in addition to the host.
     */
    public var overridesEventsSubdirectory: Bool = false
    
    /**
     Allows you to override the default identity host.
     */
    public var identityHost: String?
    
    /**
     Allows you to override the tracking identity host. Set this to automatically use an alternate custom domain when ATTStatus has been authorized.
     */
    public var identityTrackingHost: String?
    
    /**
     Defaults to false. If set true the identityHost above will overwrite the subdirectory of the URL in addition to the host.
     */
    public var overridesIdentitySubdirectory: Bool = false
    
    /**
     Allows you to override the default alias host.
     */
    public var aliasHost: String?
    
    /**
     Allows you to override the tracking alias host. Set this to automatically use an alternate custom domain when ATTStatus has been authorized.
     */
    public var aliasTrackingHost: String?
    
    /**
     Defaults to false. If set true the aliasHost above will overwrite the subdirectory of the URL in addition to the host.
     */
    public var overridesAliasSubdirectory: Bool = false
    
    /**
     SSL certificates for certificate pinning.
     */
    public var certificates: [Data]?
    
    /**
     Disables certificate pinning in development builds.
     */
    public var pinningDisabledInDevelopment: Bool = false
    
    /**
     Disables certificate pinning entirely.
     */
    public var pinningDisabled: Bool = false
    
    /**
     Defaults to false. Prevents the eventsHost above from overwriting the alias endpoint.
     */
    public var eventsOnly: Bool = false
    
    /**
     Default initializer.
     */
    public override init() {
        super.init()
    }
    
    /**
     Returns a string representation of the network options.
     */
    public override var description: String {
        var description = "MPNetworkOptions {\n"
        description += "  configHost: \(configHost?.description ?? "nil")\n"
        description += "  overridesConfigSubdirectory: \(overridesConfigSubdirectory ? "true" : "false")\n"
        description += "  eventsHost: \(eventsHost?.description ?? "nil")\n"
        description += "  eventsTrackingHost: \(eventsTrackingHost?.description ?? "nil")\n"
        description += "  overridesEventsSubdirectory: \(overridesEventsSubdirectory ? "true" : "false")\n"
        description += "  identityHost: \(identityHost?.description ?? "nil")\n"
        description += "  identityTrackingHost: \(identityTrackingHost?.description ?? "nil")\n"
        description += "  overridesIdentitySubdirectory: \(overridesIdentitySubdirectory ? "true" : "false")\n"
        description += "  aliasHost: \(aliasHost?.description ?? "nil")\n"
        description += "  aliasTrackingHost: \(aliasTrackingHost?.description ?? "nil")\n"
        description += "  overridesAliasSubdirectory: \(overridesAliasSubdirectory ? "true" : "false")\n"
        description += "  certificates: \(certificates?.description ?? "nil")\n"
        description += "  pinningDisabledInDevelopment: \(pinningDisabledInDevelopment ? "true" : "false")\n"
        description += "  pinningDisabled: \(pinningDisabled ? "true" : "false")\n"
        description += "  eventsOnly: \(eventsOnly ? "true" : "false")\n"
        description += "}"
        return description
    }
}
