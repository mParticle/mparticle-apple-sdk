import Foundation

/// HTTP response codes interpreted by the SDK networking layer.
@objc public enum HTTPStatusCode: Int {
    case success = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    case notModified = 304
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case timeout = 408
    case tooManyRequests = 429
    case serverError = 500
    case notImplemented = 501
    case badGateway = 502
    case serviceUnavailable = 503
    case networkAuthenticationRequired = 511
}

/// The response values returned by a connector request.
@objc public protocol MPConnectorResponseProtocol: NSObjectProtocol {
    var data: Data? { get set }
    var error: NSError? { get set }
    var downloadTime: TimeInterval { get set }
    var httpResponse: HTTPURLResponse? { get set }
}

/// Performs the synchronous request operations used by the SDK network coordinator.
@objc public protocol MPConnectorProtocol: NSObjectProtocol {
    @objc(responseFromGetRequestToURL:)
    func responseFromGetRequest(to url: MPURL) -> MPConnectorResponseProtocol

    @objc(responseFromPostRequestToURL:message:serializedParams:secret:)
    func responseFromPostRequest(
        to url: MPURL,
        message: String?,
        serializedParams: Data?,
        secret: String?
    ) -> MPConnectorResponseProtocol
}

/// Mutable result object returned by connector operations.
@objc(MPConnectorResponse)
public final class MPConnectorResponse: NSObject, MPConnectorResponseProtocol {
    @objc public var data: Data?
    @objc public var error: NSError?
    @objc public var downloadTime: TimeInterval = 0
    @objc public var httpResponse: HTTPURLResponse?
}

/// Foundation-only dependencies needed by a connector instance.
@objc public final class MPConnectorConfiguration: NSObject {
    @objc public let pinnedHosts: [String]
    @objc public let customCertificates: [Data]
    @objc public let pinningDisabledInDevelopment: Bool
    @objc public let pinningDisabled: Bool
    @objc public let isDevelopmentEnvironment: Bool
    @objc public let secureScheme: String
    @objc public let requestTimeout: TimeInterval
    @objc public let logger: MPLog

    private let requestContextProvider: (MPURLRequestKind) -> MPURLRequestContext

    // swiftlint:disable line_length
    /// Creates a connector dependency snapshot at the Objective-C networking boundary.
    @objc(
        initWithPinnedHosts:customCertificates:pinningDisabledInDevelopment:pinningDisabled:isDevelopmentEnvironment:secureScheme:requestTimeout:logger:requestContextProvider:
    )
    public init(
        pinnedHosts: [String],
        customCertificates: [Data],
        pinningDisabledInDevelopment: Bool,
        pinningDisabled: Bool,
        isDevelopmentEnvironment: Bool,
        secureScheme: String,
        requestTimeout: TimeInterval,
        logger: MPLog,
        requestContextProvider: @escaping (MPURLRequestKind) -> MPURLRequestContext
    ) {
        self.pinnedHosts = pinnedHosts
        self.customCertificates = customCertificates
        self.pinningDisabledInDevelopment = pinningDisabledInDevelopment
        self.pinningDisabled = pinningDisabled
        self.isDevelopmentEnvironment = isDevelopmentEnvironment
        self.secureScheme = secureScheme
        self.requestTimeout = requestTimeout
        self.logger = logger
        self.requestContextProvider = requestContextProvider
        super.init()
    }
    // swiftlint:enable line_length

    func requestContext(for kind: MPURLRequestKind) -> MPURLRequestContext {
        requestContextProvider(kind)
    }

    static func defaultConfiguration() -> MPConnectorConfiguration {
        let logger = MPLog(logLevel: .none)
        return MPConnectorConfiguration(
            pinnedHosts: [],
            customCertificates: [],
            pinningDisabledInDevelopment: false,
            pinningDisabled: false,
            isDevelopmentEnvironment: false,
            secureScheme: "https",
            requestTimeout: 10,
            logger: logger
        ) { _ in
            MPURLRequestContext(
                apiKey: nil,
                fallbackSecret: nil,
                userAgent: nil,
                supportedKits: nil,
                configuredKits: nil,
                eTag: nil,
                hasStoredConfiguration: false,
                environment: 0,
                requestTimeout: 10,
                networkPerformanceMessageType: "npe",
                logger: logger
            )
        }
    }
}
