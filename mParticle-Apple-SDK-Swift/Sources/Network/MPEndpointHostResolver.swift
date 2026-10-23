import Foundation

@objc public final class MPEndpointHostResolver: NSObject {
    static func defaultHost(subdomain: String, apiKey: String?) -> String {
        let podPrefix = apiKey?.components(separatedBy: "-") ?? []
        guard podPrefix.count > 1 else {
            return "\(subdomain).us1.mparticle.com"
        }
        return "\(subdomain).\(podPrefix[0]).mparticle.com"
    }

    /// The host `customBaseURL` routes to, with its port when it has one: the Rokt kit hands the
    /// same URL to its SDK, which keeps the port. A path in the URL is not used.
    @objc(customBaseURLHostWithURL:)
    public static func customBaseURLHost(url: URL?) -> String? {
        guard let host = url?.host else {
            return nil
        }
        guard let port = url?.port else {
            return host
        }
        return "\(host):\(port)"
    }

    static func resolvedHost(
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
