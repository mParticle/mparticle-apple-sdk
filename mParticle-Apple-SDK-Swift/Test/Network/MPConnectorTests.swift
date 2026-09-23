import CommonCrypto
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPConnectorSwiftTests: XCTestCase {
    override func tearDown() {
        MPConnectorURLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    // Guards against an accidental change to the pinned certificate set: fails if the
    // GoDaddy TLS Root CA - R1 certificate is ever dropped or replaced by a different one,
    // by checking the fingerprint against GoDaddy's published SHA-256 value rather than just
    // asserting a certificate is present.
    func testDefaultPinnedCertificatesContainGoDaddyTLSRootR1() {
        let expectedFingerprint = "25CF3DA8E9B97ADDBF92543C2B82527C8A4E2CFF2062A6483040D4B64ACE719F"

        let containsCertificate = MPPinnedCertificates.values.contains { encodedCertificate in
            guard let certificateData = Data(base64Encoded: encodedCertificate) else {
                XCTFail("Pinned certificate is not valid base64")
                return false
            }
            return Self.sha256Fingerprint(for: certificateData) == expectedFingerprint
        }

        XCTAssertTrue(containsCertificate)
    }

    private static func sha256Fingerprint(for data: Data) -> String {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { bytes in
            _ = CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02X", $0) }.joined()
    }

    func testPreservesObjectiveCRuntimeContracts() {
        let connector: MPConnectorProtocol = MPConnector()
        let response: MPConnectorResponseProtocol = MPConnectorResponse()

        XCTAssertTrue(connector is MPConnector)
        XCTAssertTrue(response is MPConnectorResponse)
        XCTAssertEqual(NSStringFromClass(MPConnector.self), "MPConnector")
        XCTAssertEqual(NSStringFromClass(MPConnectorResponse.self), "MPConnectorResponse")
    }

    func testResponseStartsEmpty() {
        let response = MPConnectorResponse()

        XCTAssertNil(response.data)
        XCTAssertNil(response.error)
        XCTAssertEqual(response.downloadTime, 0)
        XCTAssertNil(response.httpResponse)
    }

    func testBuildsRequestWithProvidedContext() throws {
        var requestedKinds: [MPURLRequestKind] = []
        let configuration = makeConfiguration { kind in
            requestedKinds.append(kind)
            return Self.requestContext()
        }
        let connector = MPConnector(configuration: configuration)
        let outgoingURL = try XCTUnwrap(URL(string: "https://example.com/config"))
        let canonicalURL = try XCTUnwrap(URL(string: "https://config2.mparticle.com/v4/key/config"))
        let url = try XCTUnwrap(MPURL(url: outgoingURL, defaultURL: canonicalURL))

        let request = connector.urlRequest(
            for: url,
            message: nil,
            httpMethod: "GET",
            postData: nil,
            secret: nil
        )

        XCTAssertEqual(request?.url, outgoingURL)
        XCTAssertEqual(request?.httpMethod, "GET")
        XCTAssertEqual(requestedKinds, [.config])
    }

    func testCreatesEphemeralSessionWithLegacyTimeouts() throws {
        let connector = MPConnector(configuration: makeConfiguration())

        let session = try XCTUnwrap(connector.urlSession)

        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 30)
        XCTAssertEqual(session.configuration.timeoutIntervalForResource, 30)
        XCTAssertNotNil(session.sessionDescription)
        session.invalidateAndCancel()
    }

    func testBundledCertificatesAreValidBase64() {
        let certificates = MPConnector.defaultPinnedCertificates()

        XCTAssertEqual(certificates.count, 6)
        XCTAssertTrue(certificates.allSatisfy { Data(base64Encoded: $0) != nil })
    }

    func testPerformsRequestAndReturnsResponseData() throws {
        let expectedData = Data("response".utf8)
        MPConnectorURLProtocolStub.requestHandler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: request.url ?? URL(fileURLWithPath: "/"),
                    statusCode: HTTPStatusCode.success.rawValue,
                    httpVersion: nil,
                    headerFields: ["Content-Length": "\(expectedData.count)"]
                )
            )
            return (response, expectedData)
        }
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.protocolClasses = [MPConnectorURLProtocolStub.self]
        let connector = MPConnector(
            configuration: makeConfiguration(),
            sessionConfiguration: sessionConfiguration
        )
        let endpoint = try XCTUnwrap(URL(string: "https://example.com/config"))
        let url = try XCTUnwrap(MPURL(url: endpoint, defaultURL: endpoint))

        let response = connector.responseFromGetRequest(to: url)

        XCTAssertEqual(response.data, expectedData)
        XCTAssertNil(response.error)
        XCTAssertEqual(response.httpResponse?.statusCode, HTTPStatusCode.success.rawValue)
        XCTAssertGreaterThanOrEqual(response.downloadTime, 0)
    }

    private func makeConfiguration(
        requestContextProvider: @escaping (MPURLRequestKind) -> MPURLRequestContext = { _ in
            MPConnectorSwiftTests.requestContext()
        }
    ) -> MPConnectorConfiguration {
        MPConnectorConfiguration(
            pinnedHosts: [],
            customCertificates: [],
            pinningDisabledInDevelopment: false,
            pinningDisabled: false,
            isDevelopmentEnvironment: false,
            secureScheme: "https",
            requestTimeout: 10,
            logger: MPLog(logLevel: .none),
            requestContextProvider: requestContextProvider
        )
    }

    private static func requestContext() -> MPURLRequestContext {
        MPURLRequestContext(
            apiKey: "key",
            fallbackSecret: "secret",
            userAgent: "Unit Test Agent",
            supportedKits: [],
            configuredKits: [],
            eTag: nil,
            hasStoredConfiguration: false,
            environment: 0,
            requestTimeout: 10,
            networkPerformanceMessageType: "npe",
            logger: MPLog(logLevel: .none)
        )
    }
}

private class MPConnectorURLProtocolStub: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            XCTFail("Missing request handler")
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
