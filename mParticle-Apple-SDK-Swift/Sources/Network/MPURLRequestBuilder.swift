import Foundation

/// The wire-protocol behavior to apply when constructing an SDK request.
@objc public enum MPURLRequestKind: Int {
    /// A request to a caller-supplied endpoint.
    case custom
    /// An audience request.
    case audience
    /// An identity or alias request.
    case identity
    /// An event upload request.
    case event
    /// A remote-configuration request.
    case config
}

/// Foundation values resolved by the Objective-C networking boundary for one request.
@objc public final class MPURLRequestContext: NSObject {
    /// The workspace API key, when required by the request kind.
    @objc public let apiKey: String?
    /// The state-machine secret used when the request has no explicit override.
    @objc public let fallbackSecret: String?
    /// The user agent selected for the request kind.
    @objc public let userAgent: String?
    /// The integration IDs bundled with the SDK.
    @objc public let supportedKits: [NSNumber]?
    /// The integration IDs configured for the workspace.
    @objc public let configuredKits: [NSNumber]?
    /// The previously stored configuration ETag.
    @objc public let eTag: String?
    /// Whether a stored configuration is available for conditional retrieval.
    @objc public let hasStoredConfiguration: Bool
    /// The SDK environment value sent with configuration requests.
    @objc public let environment: Int
    /// The request timeout interval.
    @objc public let requestTimeout: TimeInterval
    /// The message type that identifies network-performance events.
    @objc public let networkPerformanceMessageType: String
    /// The logger used for request diagnostics.
    @objc public let logger: MPLog

    // The Objective-C boundary keeps every context field explicit in its selector.
    // swiftlint:disable line_length
    /// Creates a snapshot of the values needed to construct a request.
    @objc(
        initWithAPIKey:fallbackSecret:userAgent:supportedKits:configuredKits:eTag:hasStoredConfiguration:environment:requestTimeout:networkPerformanceMessageType:logger:
    )
    public init(
        apiKey: String?,
        fallbackSecret: String?,
        userAgent: String?,
        supportedKits: [NSNumber]?,
        configuredKits: [NSNumber]?,
        eTag: String?,
        hasStoredConfiguration: Bool,
        environment: Int,
        requestTimeout: TimeInterval,
        networkPerformanceMessageType: String,
        logger: MPLog
    ) {
        self.apiKey = apiKey
        self.fallbackSecret = fallbackSecret
        self.userAgent = userAgent
        self.supportedKits = supportedKits
        self.configuredKits = configuredKits
        self.eTag = eTag
        self.hasStoredConfiguration = hasStoredConfiguration
        self.environment = environment
        self.requestTimeout = requestTimeout
        self.networkPerformanceMessageType = networkPerformanceMessageType
        self.logger = logger
        super.init()
    }
    // swiftlint:enable line_length
}

/// Constructs and signs an SDK URL request from Foundation values.
@objc(MPURLRequestBuilder)
public final class MPURLRequestBuilder: NSObject {
    /// The HTTP method assigned to the request.
    @objc public private(set) var httpMethod: String
    /// The bytes assigned to the request body.
    @objc public private(set) var postData: Data?
    /// The outgoing destination URL.
    @objc public let url: URL
    /// The canonical URL used for SDK request signing.
    @objc public let defaultURL: URL

    private let message: String?
    private let requestKind: MPURLRequestKind
    private let context: MPURLRequestContext
    private let now: () -> Date
    private let localeIdentifier: () -> String
    private let timeZone: () -> TimeZone

    private var headerData: Data?
    private var secret: String?

    /// Classifies a request using the legacy endpoint-hint precedence.
    @objc(requestKindForEndpointHint:message:isSDKURLRequest:)
    public static func requestKind(
        endpointHint: String?,
        message: String?,
        isSDKURLRequest: Bool
    ) -> MPURLRequestKind {
        if endpointHint == "audience" {
            return .audience
        }
        if endpointHint == "identity" {
            return .identity
        }
        if isSDKURLRequest {
            return message == nil ? .config : .event
        }
        return .custom
    }

    /// Creates a builder for an outgoing URL and its canonical signing URL.
    @objc(initWithURL:defaultURL:message:httpMethod:requestKind:context:)
    public convenience init?(
        url: URL?,
        defaultURL: URL?,
        message: String?,
        httpMethod: String?,
        requestKind: MPURLRequestKind,
        context: MPURLRequestContext
    ) {
        self.init(
            url: url,
            defaultURL: defaultURL,
            message: message,
            httpMethod: httpMethod,
            requestKind: requestKind,
            context: context,
            now: Date.init,
            localeIdentifier: { Locale.autoupdatingCurrent.identifier },
            timeZone: { NSTimeZone.default as TimeZone }
        )
    }

    init?(
        url: URL?,
        defaultURL: URL?,
        message: String?,
        httpMethod: String?,
        requestKind: MPURLRequestKind,
        context: MPURLRequestContext,
        now: @escaping () -> Date,
        localeIdentifier: @escaping () -> String,
        timeZone: @escaping () -> TimeZone
    ) {
        guard let url else {
            context.logger.error("Cannot build URL request - URL is nil")
            return nil
        }
        guard let defaultURL else {
            context.logger.error("Cannot build URL request - defaultURL is nil")
            return nil
        }

        self.url = url
        self.defaultURL = defaultURL
        self.message = message
        self.httpMethod = httpMethod ?? "GET"
        self.requestKind = requestKind
        self.context = context
        self.now = now
        self.localeIdentifier = localeIdentifier
        self.timeZone = timeZone
        super.init()
    }

    /// Applies JSON-encoded string headers to a custom request.
    @objc(withHeaderData:)
    @discardableResult
    public func withHeaderData(_ headerData: Data?) -> MPURLRequestBuilder {
        self.headerData = headerData
        return self
    }

    /// Replaces the HTTP method, defaulting a nil value to GET.
    @objc(withHttpMethod:)
    @discardableResult
    public func withHttpMethod(_ httpMethod: String?) -> MPURLRequestBuilder {
        self.httpMethod = httpMethod ?? "GET"
        return self
    }

    /// Sets the bytes sent as the request body.
    @objc(withPostData:)
    @discardableResult
    public func withPostData(_ postData: Data?) -> MPURLRequestBuilder {
        self.postData = postData
        return self
    }

    /// Overrides the fallback signing secret for this request.
    @objc(withSecret:)
    @discardableResult
    public func withSecret(_ secret: String?) -> MPURLRequestBuilder {
        self.secret = secret
        return self
    }

    /// Builds the request, returning nil when a required input or plan is invalid.
    @objc public func build() -> NSMutableURLRequest? {
        if requestKind == .event, message == nil {
            context.logger.error("Cannot build URL request - event message is nil")
            return nil
        }

        let request = NSMutableURLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = context.requestTimeout
        request.httpMethod = httpMethod

        let dateValue = now()
        let date = MPDateFormatter.string(fromDateRFC1123: dateValue) ?? ""
        let currentTimeZone = timeZone()
        let localeHeaders = MPLocaleHeaders(
            deviceLocale: localeIdentifier(),
            timeZoneName: currentTimeZone.identifier,
            secondsFromGMT: currentTimeZone.secondsFromGMT(for: dateValue)
        )

        if let plan = requestPlan(date: date, localeHeaders: localeHeaders) {
            guard let failureReason = plan.failureReason else {
                apply(plan: plan, to: request)
                applyPostData(to: request)
                log(request)
                return request
            }
            context.logger.error("Cannot build URL request - \(failureReason)")
            return nil
        }

        applyCustomHeaders(to: request)
        applyPostData(to: request)
        log(request)
        return request
    }

    private func requestPlan(date: String, localeHeaders: MPLocaleHeaders) -> MPURLRequestPlan? {
        switch requestKind {
        case .custom:
            return nil
        case .audience:
            let target = MPRequestSigningTarget(
                httpMethod: httpMethod,
                date: date,
                relativePath: url.relativePath
            )
            let plan = MPURLRequestPlan.audiencePlan(
                target: target,
                query: url.query,
                apiKey: context.apiKey,
                userAgent: context.userAgent
            )
            if plan.failureReason == nil {
                context.logger.verbose("Audience Signature:\n\(plan.signatureMessage)")
            }
            return plan
        case .identity:
            let target = signingTarget(date: date)
            return MPURLRequestPlan.identityPlan(
                target: target,
                postData: postData,
                apiKey: context.apiKey,
                localeHeaders: localeHeaders
            )
        case .event:
            return MPURLRequestPlan.eventPlan(
                target: signingTarget(date: date),
                message: message ?? "",
                supportedKits: context.supportedKits,
                configuredKits: context.configuredKits,
                userAgent: context.userAgent,
                localeHeaders: localeHeaders,
                networkPerformanceMessageType: context.networkPerformanceMessageType
            )
        case .config:
            return MPURLRequestPlan.configPlan(
                target: signingTarget(date: date),
                query: defaultURL.query,
                supportedKits: context.supportedKits,
                eTag: context.eTag,
                hasStoredConfiguration: context.hasStoredConfiguration,
                userAgent: context.userAgent,
                localeHeaders: localeHeaders,
                environment: context.environment
            )
        }
    }

    private func signingTarget(date: String) -> MPRequestSigningTarget {
        MPRequestSigningTarget(
            httpMethod: httpMethod,
            date: date,
            relativePath: defaultURL.relativePath
        )
    }

    private func apply(plan: MPURLRequestPlan, to request: NSMutableURLRequest) {
        for (field, value) in plan.headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let signingSecret = secret ?? context.fallbackSecret
        if let signature = MPRequestSigner.hmacSHA256Hex(
            message: plan.signatureMessage,
            key: signingSecret
        ) {
            request.setValue(signature, forHTTPHeaderField: "x-mp-signature")
        }
    }

    private func applyCustomHeaders(to request: NSMutableURLRequest) {
        guard let headerData else {
            return
        }
        guard let object = try? JSONSerialization.jsonObject(with: headerData),
              let headers = object as? [String: Any]
        else {
            context.logger.warning("Ignoring malformed custom URL request headers")
            return
        }

        for (field, value) in headers {
            guard let value = value as? String else {
                context.logger.warning("Ignoring non-string custom URL request header: \(field)")
                continue
            }
            request.setValue(value, forHTTPHeaderField: field)
        }
    }

    private func applyPostData(to request: NSMutableURLRequest) {
        if let postData, !postData.isEmpty {
            request.httpBody = postData
        }
    }

    private func log(_ request: NSMutableURLRequest) {
        context.logger.verbose("URL Request built")
        context.logger.verbose("with URL:\n\(request.url?.absoluteString ?? "(null)")")
        context.logger.verbose("with headers:\n\(request.allHTTPHeaderFields ?? [:])")
    }
}
