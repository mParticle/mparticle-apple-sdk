import Foundation

@objc public final class MPEndpointHostResolver: NSObject {
    @objc(defaultHostWithSubdomain:apiKey:)
    public static func defaultHost(subdomain: String, apiKey: String?) -> String {
        let podPrefix = apiKey?.components(separatedBy: "-") ?? []
        guard podPrefix.count > 1 else {
            return "\(subdomain).us1.mparticle.com"
        }
        return "\(subdomain).\(podPrefix[0]).mparticle.com"
    }

    @objc(resolvedHostWithCustomBaseURLHost:trackingHost:host:defaultHost:attAuthorized:)
    public static func resolvedHost(
        customBaseURLHost: String?,
        trackingHost: String?,
        host: String?,
        defaultHost: String,
        attAuthorized: Bool
    ) -> String {
        if let customBaseURLHost {
            return customBaseURLHost
        }
        if let trackingHost, attAuthorized {
            return trackingHost
        }
        return host ?? defaultHost
    }
}
