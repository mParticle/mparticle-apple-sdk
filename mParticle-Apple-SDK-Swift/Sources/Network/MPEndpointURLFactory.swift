import Foundation
import UIKit

/// Endpoint routing inputs, flattened on the Objective-C side.
///
/// `MPNetworkOptions` and `MPUploadSettings` cannot be imported here, so their fields
/// arrive as scalars, the same shape `MPUploadBatchLimits` uses for the upload
/// constants. One instance describes every endpoint family; each factory method reads
/// only the fields its own endpoint consults.
@objc(MPEndpointRouting)
public final class MPEndpointRouting: NSObject {
    @objc public let apiKey: String?
    @objc public let customBaseURLHost: String?
    @objc public let hasCustomBaseURL: Bool
    @objc public let configHost: String?
    @objc public let eventsHost: String?
    @objc public let eventsTrackingHost: String?
    @objc public let identityHost: String?
    @objc public let identityTrackingHost: String?
    @objc public let aliasHost: String?
    @objc public let aliasTrackingHost: String?
    @objc public let overridesConfigSubdirectory: Bool
    @objc public let overridesEventsSubdirectory: Bool
    @objc public let overridesIdentitySubdirectory: Bool
    @objc public let overridesAliasSubdirectory: Bool
    @objc public let eventsOnly: Bool
    @objc public let attAuthorized: Bool

    // Selector left to the compiler: spelled out, it is a single 299-character line.
    @objc public init(
        apiKey: String?,
        customBaseURLHost: String?,
        hasCustomBaseURL: Bool,
        configHost: String?,
        eventsHost: String?,
        eventsTrackingHost: String?,
        identityHost: String?,
        identityTrackingHost: String?,
        aliasHost: String?,
        aliasTrackingHost: String?,
        overridesConfigSubdirectory: Bool,
        overridesEventsSubdirectory: Bool,
        overridesIdentitySubdirectory: Bool,
        overridesAliasSubdirectory: Bool,
        eventsOnly: Bool,
        attAuthorized: Bool
    ) {
        self.apiKey = apiKey
        self.customBaseURLHost = customBaseURLHost
        self.hasCustomBaseURL = hasCustomBaseURL
        self.configHost = configHost
        self.eventsHost = eventsHost
        self.eventsTrackingHost = eventsTrackingHost
        self.identityHost = identityHost
        self.identityTrackingHost = identityTrackingHost
        self.aliasHost = aliasHost
        self.aliasTrackingHost = aliasTrackingHost
        self.overridesConfigSubdirectory = overridesConfigSubdirectory
        self.overridesEventsSubdirectory = overridesEventsSubdirectory
        self.overridesIdentitySubdirectory = overridesIdentitySubdirectory
        self.overridesAliasSubdirectory = overridesAliasSubdirectory
        self.eventsOnly = eventsOnly
        self.attAuthorized = attAuthorized
        super.init()
    }
}

/// Builds the outgoing/canonical URL pair for every mParticle endpoint.
///
/// Each method pairs the URL the request is sent to with the canonical mParticle URL
/// used to sign it, mirroring what `MPNetworkCommunication` did inline.
@objc(MPEndpointURLFactory)
public final class MPEndpointURLFactory: NSObject {
    private let logger: () -> MPLog?

    @objc public init(logger: @escaping () -> MPLog?) {
        self.logger = logger
        super.init()
    }

    /// Mirrors the endpoint constants in `MPNetworkCommunication.m`. Those are
    /// external-linkage C globals that `MPNetworkCommunication+Tests.h` and the public
    /// header extern, so they stay defined in Objective-C and are duplicated here, the
    /// same way `MessageKeys.swift` mirrors `MPIConstants`.
    private enum Constant {
        static let scheme = "https"
        static let configHost = "config2.mparticle.com"
        static let configVersion = "v4"
        static let configPath = "/config"
        static let configCDNVersion = "config/v4"
        static let eventsVersion = "v2"
        static let eventsPath = "/events"
        static let eventsCDNVersion = "nativeevents/v2"
        static let audienceVersion = "v1"
        static let audiencePath = "/audience"
        static let audienceCDNVersion = "nativeevents/v1"
        static let identityVersion = "v1"
        static let identityKey = "identity"
        static let identityCDNVersion = "identity/v1"
        static let aliasCDNVersion = "nativeevents/v1"
        static let audienceHint = "audience"
    }

    @objc(configURLWithRouting:appVersion:sdkVersion:dataPlanId:dataPlanVersion:)
    public func configURL(
        routing: MPEndpointRouting,
        appVersion: String?,
        sdkVersion: String,
        dataPlanId: String?,
        dataPlanVersion: NSNumber?
    ) -> MPURL? {
        let log = logger()
        if routing.customBaseURLHost != nil, routing.configHost != nil {
            log?.warning("MPNetworkOptions: customBaseURL is set; configHost is ignored.")
        }

        let host = MPEndpointHostResolver.resolvedHost(
            customBaseURLHost: routing.customBaseURLHost,
            trackingHost: nil,
            host: routing.configHost,
            defaultHost: Constant.configHost,
            attAuthorized: false
        )

        let dataPlan = MPDataPlanQuery.query(planId: dataPlanId, planVersion: dataPlanVersion)
        if let rejected = dataPlan.rejectedVersion {
            log?.warning(
                "Data plan version of \(rejected.intValue) is out of range and will not be used "
                    + "to fetch remote data plan. Version must be between 1 and 1000."
            )
        }

        let apiKey = objcDescription(routing.apiKey)
        let query = "?av=\(objcDescription(appVersion.flatMap { $0.percentEscape() }))&sv=\(sdkVersion)"

        // Built before the data plan suffix is appended, so the canonical URL never
        // carries it.
        let canonical = "\(Constant.scheme)://\(Constant.configHost)/\(Constant.configVersion)/"
            + "\(apiKey)\(Constant.configPath)\(query)"

        let style = MPEndpointPathStyle.style(
            defaultVersion: Constant.configVersion,
            cdnVersion: Constant.configCDNVersion,
            usesCustomHost: routing.customBaseURLHost != nil,
            overridesSubdirectory: routing.overridesConfigSubdirectory
        )
        warnIfOverrideIgnored(style, field: "overridesConfigSubdirectory", log: log)

        var requested = style.usesOverrideFormat
            ? "\(Constant.scheme)://\(host)/\(apiKey)\(Constant.configPath)\(query)"
            : "\(Constant.scheme)://\(host)/\(style.versionSegment)/\(apiKey)\(Constant.configPath)\(query)"
        if let dataPlanQuery = dataPlan.query {
            requested += dataPlanQuery
        }

        return urlPair(requested: requested, canonical: canonical, hint: nil)
    }

    @objc(eventURLWithRouting:defaultEventHost:)
    public func eventURL(routing: MPEndpointRouting, defaultEventHost: String) -> MPURL? {
        let host = MPEndpointHostResolver.resolvedHost(
            customBaseURLHost: nil,
            trackingHost: routing.eventsTrackingHost,
            host: routing.eventsHost,
            defaultHost: defaultEventHost,
            attAuthorized: routing.attAuthorized
        )

        let apiKey = objcDescription(routing.apiKey)
        let canonical = "\(Constant.scheme)://\(defaultEventHost)/\(Constant.eventsVersion)/"
            + "\(apiKey)\(Constant.eventsPath)"

        let style = MPEndpointPathStyle.style(
            defaultVersion: Constant.eventsVersion,
            cdnVersion: Constant.eventsCDNVersion,
            usesCustomHost: routing.hasCustomBaseURL,
            overridesSubdirectory: routing.overridesEventsSubdirectory
        )
        warnIfOverrideIgnored(style, field: "overridesEventsSubdirectory", log: logger())

        let requested = style.usesOverrideFormat
            ? "\(Constant.scheme)://\(host)/\(apiKey)\(Constant.eventsPath)"
            : "\(Constant.scheme)://\(host)/\(style.versionSegment)/\(apiKey)\(Constant.eventsPath)"

        return urlPair(requested: requested, canonical: canonical, hint: nil)
    }

    /// Carries over two format/argument mismatches from the Objective-C original: the
    /// canonical URL and the subdirectory-override URL both feed `/audience` into the
    /// `mpid` slot and drop the real mpid, and the override URL leaves the version
    /// jammed against the API key. `MPNetworkCommunicationTests` pins all three strings.
    @objc(audienceURLWithRouting:defaultEventHost:mpId:)
    public func audienceURL(
        routing: MPEndpointRouting,
        defaultEventHost: String,
        mpId: NSNumber
    ) -> MPURL? {
        let log = logger()
        if routing.customBaseURLHost != nil, routing.eventsHost != nil {
            log?.warning("MPNetworkOptions: customBaseURL is set; eventsHost is ignored.")
        }

        let host = MPEndpointHostResolver.resolvedHost(
            customBaseURLHost: routing.customBaseURLHost,
            trackingHost: nil,
            host: routing.eventsHost,
            defaultHost: defaultEventHost,
            attAuthorized: false
        )

        let apiKey = objcDescription(routing.apiKey)
        let canonical = "\(Constant.scheme)://\(defaultEventHost)/\(Constant.audienceVersion)/"
            + "\(apiKey)?mpid=\(Constant.audiencePath)"

        let style = MPEndpointPathStyle.style(
            defaultVersion: Constant.audienceVersion,
            cdnVersion: Constant.audienceCDNVersion,
            usesCustomHost: routing.customBaseURLHost != nil,
            overridesSubdirectory: routing.overridesEventsSubdirectory
        )
        warnIfOverrideIgnored(style, field: "overridesEventsSubdirectory", log: log)

        let requested = style.usesOverrideFormat
            ? "\(Constant.scheme)://\(host)/\(Constant.audienceVersion)\(apiKey)?mpid=\(Constant.audiencePath)"
            : "\(Constant.scheme)://\(host)/\(style.versionSegment)/\(apiKey)\(Constant.audiencePath)?mpid=\(mpId)"

        return urlPair(requested: requested, canonical: canonical, hint: Constant.audienceHint)
    }

    @objc(identityURLWithRouting:defaultIdentityHost:pathComponent:)
    public func identityURL(
        routing: MPEndpointRouting,
        defaultIdentityHost: String,
        pathComponent: String
    ) -> MPURL? {
        let log = logger()
        let host = identityHost(routing: routing, defaultIdentityHost: defaultIdentityHost, log: log)

        let canonical = "\(Constant.scheme)://\(defaultIdentityHost)/\(Constant.identityVersion)/\(pathComponent)"

        let style = identityPathStyle(routing: routing)
        warnIfOverrideIgnored(style, field: "overridesIdentitySubdirectory", log: log)

        let requested = style.usesOverrideFormat
            ? "\(Constant.scheme)://\(host)/\(pathComponent)"
            : "\(Constant.scheme)://\(host)/\(style.versionSegment)/\(pathComponent)"

        return urlPair(requested: requested, canonical: canonical, hint: Constant.identityKey)
    }

    @objc(modifyURLWithRouting:defaultIdentityHost:mpId:)
    public func modifyURL(
        routing: MPEndpointRouting,
        defaultIdentityHost: String,
        mpId: NSNumber
    ) -> MPURL? {
        let pathComponent = "modify"
        let log = logger()
        let host = identityHost(routing: routing, defaultIdentityHost: defaultIdentityHost, log: log)

        let canonical = "\(Constant.scheme)://\(defaultIdentityHost)/\(Constant.identityVersion)/"
            + "\(mpId)/\(pathComponent)"

        let style = identityPathStyle(routing: routing)
        warnIfOverrideIgnored(style, field: "overridesIdentitySubdirectory", log: log)

        let requested = style.usesOverrideFormat
            ? "\(Constant.scheme)://\(host)/\(mpId)/\(pathComponent)"
            : "\(Constant.scheme)://\(host)/\(style.versionSegment)/\(mpId)/\(pathComponent)"

        return urlPair(requested: requested, canonical: canonical, hint: Constant.identityKey)
    }

    @objc(aliasURLWithRouting:defaultEventHost:)
    public func aliasURL(routing: MPEndpointRouting, defaultEventHost: String) -> MPURL? {
        let pathComponent = "alias"
        var host = MPEndpointHostResolver.resolvedHost(
            customBaseURLHost: nil,
            trackingHost: routing.aliasTrackingHost,
            host: routing.aliasHost,
            defaultHost: defaultEventHost,
            attAuthorized: routing.attAuthorized
        )

        let apiKey = objcDescription(routing.apiKey)
        let canonical = "\(Constant.scheme)://\(defaultEventHost)/\(Constant.identityVersion)/"
            + "\(Constant.identityKey)/\(apiKey)/\(pathComponent)"

        // Without an explicit alias host, a non-events-only upload re-resolves through
        // the events host, which discards aliasTrackingHost.
        var overridesSubdirectory = routing.overridesAliasSubdirectory
        if !routing.eventsOnly, routing.aliasHost == nil {
            host = routing.eventsHost ?? defaultEventHost
            overridesSubdirectory = routing.overridesEventsSubdirectory
        }

        let style = MPEndpointPathStyle.style(
            defaultVersion: Constant.identityVersion,
            cdnVersion: Constant.aliasCDNVersion,
            usesCustomHost: routing.hasCustomBaseURL,
            overridesSubdirectory: overridesSubdirectory
        )
        if style.warnsSubdirectoryOverrideIgnored {
            logger()?.warning(
                "MPNetworkOptions: customBaseURL with overridesAliasSubdirectory/overridesEventsSubdirectory "
                    + "is unsupported for CDN routing; subdirectory override will be ignored."
            )
        }

        let versioned = "\(Constant.scheme)://\(host)/\(style.versionSegment)/"
            + "\(Constant.identityKey)/\(apiKey)/\(pathComponent)"
        let requested = style.usesOverrideFormat
            ? "\(Constant.scheme)://\(host)/\(apiKey)/\(pathComponent)"
            : versioned

        return urlPair(requested: requested, canonical: canonical, hint: Constant.identityKey)
    }

    // MARK: - Shared pieces

    private func identityHost(
        routing: MPEndpointRouting,
        defaultIdentityHost: String,
        log: MPLog?
    ) -> String {
        if routing.customBaseURLHost != nil,
           routing.identityHost != nil || routing.identityTrackingHost != nil {
            log?.warning("MPNetworkOptions: customBaseURL is set; identityHost/identityTrackingHost are ignored.")
        }

        return MPEndpointHostResolver.resolvedHost(
            customBaseURLHost: routing.customBaseURLHost,
            trackingHost: routing.identityTrackingHost,
            host: routing.identityHost,
            defaultHost: defaultIdentityHost,
            attAuthorized: routing.attAuthorized
        )
    }

    private func identityPathStyle(routing: MPEndpointRouting) -> MPEndpointPathStyle {
        MPEndpointPathStyle.style(
            defaultVersion: Constant.identityVersion,
            cdnVersion: Constant.identityCDNVersion,
            usesCustomHost: routing.customBaseURLHost != nil,
            overridesSubdirectory: routing.overridesIdentitySubdirectory
        )
    }

    private func warnIfOverrideIgnored(_ style: MPEndpointPathStyle, field: String, log: MPLog?) {
        guard style.warnsSubdirectoryOverrideIgnored else { return }
        log?.warning(
            "MPNetworkOptions: customBaseURL with \(field) is unsupported for CDN routing; "
                + "\(field) will be ignored."
        )
    }

    /// `stringWithFormat:` renders a nil `%@` argument as `(null)`; interpolating an
    /// Optional directly would produce `nil` or `Optional("...")` instead.
    private func objcDescription(_ value: String?) -> String {
        value ?? "(null)"
    }

    /// The hint is a routing side channel, not accessibility metadata: `MPConnector`
    /// reads it back off the outgoing URL to choose the request kind and its signing
    /// context, so it has to survive onto both URLs.
    private func urlPair(requested: String, canonical: String, hint: String?) -> MPURL? {
        let requestedURL = NSURL(string: requested)
        let canonicalURL = NSURL(string: canonical)

        if let hint {
            requestedURL?.accessibilityHint = hint
            canonicalURL?.accessibilityHint = hint
        }

        return MPURL(url: requestedURL as URL?, defaultURL: canonicalURL as URL?)
    }
}
