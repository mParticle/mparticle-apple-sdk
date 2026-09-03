import Foundation
import Security
import UIKit

/// Executes SDK HTTP requests and validates pinned server certificates.
@objc(MPConnector)
public final class MPConnector: NSObject, MPConnectorProtocol, URLSessionDataDelegate {
    private typealias CompletionHandler = (Data?, NSError?, TimeInterval, HTTPURLResponse?) -> Void

    private let configuration: MPConnectorConfiguration
    private let sessionConfiguration: URLSessionConfiguration
    private var receivedData: NSMutableData?
    private var requestStartTime: Date?
    private var httpURLResponse: HTTPURLResponse?
    private var completionHandler: CompletionHandler?
    private var urlSessionStorage: URLSession?

    /// The active task, exposed for Objective-C integration tests.
    @objc public var dataTask: URLSessionDataTask?

    /// The lazily created ephemeral session.
    @objc public var urlSession: URLSession? {
        get {
            if let urlSessionStorage {
                return urlSessionStorage
            }

            sessionConfiguration.timeoutIntervalForRequest = 30
            sessionConfiguration.timeoutIntervalForResource = 30
            let session = URLSession(
                configuration: sessionConfiguration,
                delegate: self,
                delegateQueue: nil
            )
            session.sessionDescription = UUID().uuidString
            urlSessionStorage = session
            return session
        }
        set {
            urlSessionStorage = newValue
        }
    }

    /// Creates a connector with safe defaults for direct construction.
    @objc override public convenience init() {
        self.init(configuration: .defaultConfiguration())
    }

    /// Creates a connector from dependencies assembled by the SDK networking boundary.
    @objc(initWithConfiguration:)
    public convenience init(configuration: MPConnectorConfiguration) {
        self.init(configuration: configuration, sessionConfiguration: .ephemeral)
    }

    init(
        configuration: MPConnectorConfiguration,
        sessionConfiguration: URLSessionConfiguration
    ) {
        self.configuration = configuration
        self.sessionConfiguration = sessionConfiguration
        super.init()
    }

    /// The bundled roots accepted by certificate pinning.
    @objc(defaultPinnedCertificates)
    public static func defaultPinnedCertificates() -> [String] {
        MPPinnedCertificates.values
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error {
            configuration.logger.error("URL session invalidated with error: \(error.localizedDescription)")
        } else {
            configuration.logger.debug("URL session invalidated")
        }
        urlSessionStorage = nil
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let protectionSpace = challenge.protectionSpace
        let authenticationMethod = protectionSpace.authenticationMethod
        let host = protectionSpace.host
        let requestProtocol = protectionSpace.protocol
        let serverTrust = protectionSpace.serverTrust
        let isPinningHost = isPinningHost(host)

        configuration.logger.verbose(
            "SSL challenge received - host: \(host), authMethod: \(authenticationMethod), "
                + "protocol: \(requestProtocol ?? "nil"), isPinningHost: \(isPinningHost), "
                + "serverTrust: \(serverTrust == nil ? "nil" : "present")"
        )

        guard authenticationMethod == NSURLAuthenticationMethodServerTrust,
              isPinningHost,
              requestProtocol == configuration.secureScheme,
              protectionSpace.receivesCredentialSecurely,
              let serverTrust
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        DispatchQueue.global(qos: .default).async { [configuration] in
            let trustChallenge = Self.evaluate(
                serverTrust,
                customCertificates: configuration.customCertificates,
                logger: configuration.logger
            )
            let shouldDisablePinning = configuration.pinningDisabled
                || (configuration.pinningDisabledInDevelopment
                    && configuration.isDevelopmentEnvironment)

            if trustChallenge || shouldDisablePinning {
                configuration.logger.debug("SSL challenge accepted for host: \(host)")
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                configuration.logger.warning(
                    "SSL pinning disabled - pinningDisabledInDevelopment: "
                        + "\(configuration.pinningDisabledInDevelopment), "
                        + "pinningDisabled: \(configuration.pinningDisabled)"
                )
                configuration.logger.error(
                    "SSL certificate pinning rejected - host: \(host), trustChallenge: false, "
                        + "shouldDisablePinning: false"
                )
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        httpURLResponse = response as? HTTPURLResponse
        let responseCode = httpURLResponse?.statusCode ?? 0

        configuration.logger.verbose(
            "HTTP response received - statusCode: \(responseCode), "
                + "expectedContentLength: \(response.expectedContentLength)"
        )

        if responseCode == HTTPStatusCode.success.rawValue
            || responseCode == HTTPStatusCode.accepted.rawValue {
            if response.expectedContentLength != NSURLSessionTransferSizeUnknown,
               response.expectedContentLength > 0 {
                receivedData = NSMutableData(capacity: Int(response.expectedContentLength))
            } else {
                receivedData = NSMutableData()
            }
        } else {
            receivedData = nil
        }

        completionHandler(.allow)
    }

    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive data: Data
    ) {
        receivedData?.append(data)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            let nsError = error as NSError
            configuration.logger.error(
                "Network task failed - error: \(nsError.localizedDescription) "
                    + "(domain: \(nsError.domain), code: \(nsError.code))"
            )
            completionHandler?(nil, nsError, 0, nil)
        } else {
            let downloadTime = requestStartTime.map { Date().timeIntervalSince($0) } ?? 0
            let data = receivedData.map { $0 as Data }
            configuration.logger.debug(
                "Network task completed - downloadTime: \(downloadTime * 1_000)ms, "
                    + "dataSize: \(data?.count ?? 0) bytes"
            )
            completionHandler?(data, nil, downloadTime, httpURLResponse)
        }

        urlSessionStorage?.finishTasksAndInvalidate()
        urlSessionStorage = nil
    }

    /// Builds the request used by the synchronous connector methods.
    @objc(urlRequestForURL:message:httpMethod:postData:secret:)
    public func urlRequest(
        for url: MPURL,
        message: String?,
        httpMethod: String?,
        postData: Data?,
        secret: String?
    ) -> NSMutableURLRequest? {
        let endpointHint = (url.url as NSURL).accessibilityHint
        let requestKind = MPURLRequestBuilder.requestKind(
            endpointHint: endpointHint,
            message: message,
            isSDKURLRequest: true
        )
        let context = configuration.requestContext(for: requestKind)
        guard let builder = MPURLRequestBuilder(
            url: url.url,
            defaultURL: url.defaultURL,
            message: message,
            httpMethod: httpMethod,
            requestKind: requestKind,
            context: context
        ) else {
            return nil
        }

        return builder.withPostData(postData).withSecret(secret).build()
    }

    public func responseFromGetRequest(to url: MPURL) -> MPConnectorResponseProtocol {
        response(
            to: url,
            message: nil,
            serializedParams: nil,
            secret: nil,
            httpMethod: "GET"
        )
    }

    public func responseFromPostRequest(
        to url: MPURL,
        message: String?,
        serializedParams: Data?,
        secret: String?
    ) -> MPConnectorResponseProtocol {
        response(
            to: url,
            message: message,
            serializedParams: serializedParams,
            secret: secret,
            httpMethod: "POST"
        )
    }

    private func response(
        to url: MPURL,
        message: String?,
        serializedParams: Data?,
        secret: String?,
        httpMethod: String
    ) -> MPConnectorResponse {
        let response = MPConnectorResponse()
        configuration.logger.debug("Starting \(httpMethod) request to: \(url.url.host ?? "nil")")

        guard let request = urlRequest(
            for: url,
            message: message,
            httpMethod: httpMethod,
            postData: serializedParams,
            secret: secret
        ) else {
            configuration.logger.error(
                "\(httpMethod) request failed - could not build URL request for: "
                    + "\(url.url.host ?? "nil")"
            )
            response.error = NSError(domain: "MPConnector", code: 1)
            return response
        }

        requestStartTime = Date()
        let requestSemaphore = DispatchSemaphore(value: 0)
        var completionData: Data?
        var completionError: NSError?
        var completionDownloadTime: TimeInterval = 0
        var completionHTTPResponse: HTTPURLResponse?
        completionHandler = { data, error, downloadTime, httpResponse in
            completionData = data
            completionError = error
            completionDownloadTime = downloadTime
            completionHTTPResponse = httpResponse
            requestSemaphore.signal()
        }

        dataTask = urlSession?.dataTask(with: request as URLRequest)
        dataTask?.resume()
        let waitResult = requestSemaphore.wait(
            timeout: .now() + configuration.requestTimeout + 1
        )

        if waitResult == .success {
            response.data = completionData
            response.error = completionError
            response.downloadTime = completionDownloadTime
            response.httpResponse = completionHTTPResponse
            configuration.logger.verbose(
                "\(httpMethod) request completed - statusCode: "
                    + "\(completionHTTPResponse?.statusCode ?? 0), "
                    + "dataSize: \(completionData?.count ?? 0) bytes"
            )
        } else {
            configuration.logger.error(
                "\(httpMethod) request timed out after "
                    + "\(Int(configuration.requestTimeout + 1)) seconds - "
                    + "host: \(url.url.host ?? "nil")"
            )
            response.error = NSError(
                domain: MPTransportErrorDetector.semaphoreTimeoutErrorDomain() as String,
                code: MPTransportErrorDetector.semaphoreTimeoutErrorCode().intValue,
                userInfo: ["mParticle Error": "Semaphore wait timed out"]
            )
            urlSessionStorage?.invalidateAndCancel()
        }

        return response
    }

    private func isPinningHost(_ host: String) -> Bool {
        host.contains("mparticle.com") || configuration.pinnedHosts.contains(host)
    }

    private static func evaluate(
        _ trust: SecTrust,
        customCertificates: [Data],
        logger: MPLog
    ) -> Bool {
        var error: CFError?
        let trustResult = SecTrustEvaluateWithError(trust, &error)
        logger.verbose("SSL trust evaluation - trustResult: \(trustResult)")
        guard trustResult,
              let certificateChain = SecTrustCopyCertificateChain(trust) as? [SecCertificate],
              let rootCertificate = certificateChain.last
        else {
            if let error {
                logger.verbose("SSL trust evaluation failed - \(error.localizedDescription)")
            }
            return false
        }

        let certificateData = SecCertificateCopyData(rootCertificate) as Data
        let encodedCertificate = certificateData.base64EncodedString()
        let storedCertificateMatch = MPPinnedCertificates.values.contains(encodedCertificate)
        let customCertificateMatch = customCertificates.contains(certificateData)
        logger.verbose(
            "SSL certificate match - storedCertMatch: \(storedCertificateMatch), "
                + "customCertCount: \(customCertificates.count)"
        )
        return storedCertificateMatch || customCertificateMatch
    }
}
