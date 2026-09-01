import Foundation

@objc public final class MPRequestSigningTarget: NSObject {
    @objc public let httpMethod: String
    @objc public let date: String
    @objc public let relativePath: String?

    @objc(initWithHTTPMethod:date:relativePath:)
    public init(httpMethod: String, date: String, relativePath: String?) {
        self.httpMethod = httpMethod
        self.date = date
        self.relativePath = relativePath
        super.init()
    }
}

@objc public final class MPLocaleHeaders: NSObject {
    @objc public let deviceLocale: String
    @objc public let timeZoneName: String
    @objc public let secondsFromGMT: Int

    @objc(initWithDeviceLocale:timeZoneName:secondsFromGMT:)
    public init(deviceLocale: String, timeZoneName: String, secondsFromGMT: Int) {
        self.deviceLocale = deviceLocale
        self.timeZoneName = timeZoneName
        self.secondsFromGMT = secondsFromGMT
        super.init()
    }
}

@objc public final class MPURLRequestPlan: NSObject {
    @objc public let headers: [String: String]
    @objc public let signatureMessage: String
    @objc public let failureReason: String?

    private init(headers: [String: String], signatureMessage: String) {
        self.headers = headers
        self.signatureMessage = signatureMessage
        failureReason = nil
        super.init()
    }

    private init(failureReason: String) {
        headers = [:]
        signatureMessage = ""
        self.failureReason = failureReason
        super.init()
    }

    @objc(audiencePlanWithTarget:query:apiKey:userAgent:)
    public static func audiencePlan(
        target: MPRequestSigningTarget,
        query: String?,
        apiKey: String?,
        userAgent: String?
    ) -> MPURLRequestPlan {
        guard let relativePath = target.relativePath else {
            return MPURLRequestPlan(failureReason: "audience relative path is nil")
        }
        if MPRequestSigner.exceedsMaxQueryLength(query) {
            return MPURLRequestPlan(failureReason: "audience query exceeds max supported length")
        }

        var headers = ["Date": target.date]
        headers["x-mp-key"] = apiKey
        headers["User-Agent"] = userAgent

        return MPURLRequestPlan(
            headers: headers,
            signatureMessage: MPRequestSigner.signatureMessage(
                httpMethod: target.httpMethod,
                date: target.date,
                relativePath: relativePath,
                query: query
            )
        )
    }

    @objc(identityPlanWithTarget:postData:apiKey:localeHeaders:)
    public static func identityPlan(
        target: MPRequestSigningTarget,
        postData: Data?,
        apiKey: String?,
        localeHeaders: MPLocaleHeaders
    ) -> MPURLRequestPlan {
        guard let relativePath = target.relativePath else {
            return MPURLRequestPlan(failureReason: "relative path is nil")
        }
        guard let postData else {
            return MPURLRequestPlan(failureReason: "post data is nil for identity request")
        }
        guard let postDataString = String(data: postData, encoding: .utf8) else {
            return MPURLRequestPlan(failureReason: "failed to encode post data as UTF-8")
        }

        var headers = commonHeaders(
            date: target.date,
            contentType: "application/json",
            localeHeaders: localeHeaders,
            compressesBody: false
        )
        headers["x-mp-key"] = apiKey

        return MPURLRequestPlan(
            headers: headers,
            signatureMessage: MPRequestSigner.signatureMessage(
                httpMethod: target.httpMethod,
                date: target.date,
                relativePath: relativePath,
                body: postDataString
            )
        )
    }

    @objc(eventPlanWithTarget:message:supportedKits:configuredKits:userAgent:localeHeaders:networkPerformanceMessageType:)
    public static func eventPlan(
        target: MPRequestSigningTarget,
        message: String,
        supportedKits: [NSNumber]?,
        configuredKits: [NSNumber]?,
        userAgent: String?,
        localeHeaders: MPLocaleHeaders,
        networkPerformanceMessageType: String
    ) -> MPURLRequestPlan {
        guard let relativePath = target.relativePath else {
            return MPURLRequestPlan(failureReason: "relative path is nil")
        }

        var headers = commonHeaders(
            date: target.date,
            contentType: "application/json",
            localeHeaders: localeHeaders,
            compressesBody: true
        )
        headers["x-mp-bundled-kits"] = joined(supportedKits)
        headers["x-mp-kits"] = joined(configuredKits)
        headers["User-Agent"] = userAgent
        if message.contains(networkPerformanceMessageType) {
            headers[networkPerformanceMessageType] = networkPerformanceMessageType
        }

        return MPURLRequestPlan(
            headers: headers,
            signatureMessage: MPRequestSigner.signatureMessage(
                httpMethod: target.httpMethod,
                date: target.date,
                relativePath: relativePath,
                body: message
            )
        )
    }

    @objc(configPlanWithTarget:query:supportedKits:eTag:hasStoredConfiguration:userAgent:localeHeaders:environment:)
    public static func configPlan(
        target: MPRequestSigningTarget,
        query: String?,
        supportedKits: [NSNumber]?,
        eTag: String?,
        hasStoredConfiguration: Bool,
        userAgent: String?,
        localeHeaders: MPLocaleHeaders,
        environment: Int
    ) -> MPURLRequestPlan {
        guard let relativePath = target.relativePath else {
            return MPURLRequestPlan(failureReason: "relative path is nil")
        }
        if MPRequestSigner.exceedsMaxQueryLength(query) {
            return MPURLRequestPlan(failureReason: "config query exceeds max supported length")
        }

        var headers = commonHeaders(
            date: target.date,
            contentType: "application/x-www-form-urlencoded",
            localeHeaders: localeHeaders,
            compressesBody: true
        )
        headers["x-mp-env"] = "\(environment)"
        headers["If-None-Match"] = hasStoredConfiguration ? eTag : nil
        headers["x-mp-kits"] = joined(supportedKits)
        headers["User-Agent"] = userAgent

        return MPURLRequestPlan(
            headers: headers,
            signatureMessage: MPRequestSigner.signatureMessage(
                httpMethod: target.httpMethod,
                date: target.date,
                relativePath: relativePath,
                query: query
            )
        )
    }

    private static func joined(_ kits: [NSNumber]?) -> String? {
        kits?.map(\.stringValue).joined(separator: ",")
    }

    private static func commonHeaders(
        date: String,
        contentType: String,
        localeHeaders: MPLocaleHeaders,
        compressesBody: Bool
    ) -> [String: String] {
        var headers = [
            "Accept-Encoding": "gzip",
            "locale": localeHeaders.deviceLocale,
            "Content-Type": contentType,
            "timezone": localeHeaders.timeZoneName,
            "secondsFromGMT": "\(localeHeaders.secondsFromGMT)",
            "Date": date
        ]
        if compressesBody {
            headers["Content-Encoding"] = "gzip"
        }
        return headers
    }
}
