import Foundation
import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPURLRequestBuilderTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 0)
    private let utc = TimeZone(secondsFromGMT: 0)!

    func testRequestKindPrecedence() {
        XCTAssertEqual(
            MPURLRequestBuilder.requestKind(
                endpointHint: "audience", message: "event", isSDKURLRequest: true
            ),
            .audience
        )
        XCTAssertEqual(
            MPURLRequestBuilder.requestKind(
                endpointHint: "identity", message: "alias", isSDKURLRequest: true
            ),
            .identity
        )
        XCTAssertEqual(
            MPURLRequestBuilder.requestKind(
                endpointHint: nil, message: "event", isSDKURLRequest: true
            ),
            .event
        )
        XCTAssertEqual(
            MPURLRequestBuilder.requestKind(
                endpointHint: nil, message: nil, isSDKURLRequest: true
            ),
            .config
        )
        XCTAssertEqual(
            MPURLRequestBuilder.requestKind(
                endpointHint: nil, message: "event", isSDKURLRequest: false
            ),
            .custom
        )
    }

    func testCustomRequestAppliesMethodBodyHeadersAndTransportProperties() throws {
        let body = Data("body".utf8)
        let headers = try JSONSerialization.data(withJSONObject: [
            "Authorization": "Bearer token",
            "X-Custom": "value"
        ])
        let builder = makeBuilder(kind: .custom, message: nil, httpMethod: nil)
            .withHttpMethod("POST")
            .withPostData(body)
            .withHeaderData(headers)

        let request = try XCTUnwrap(builder.build())

        XCTAssertEqual(request.url?.absoluteString, "https://outgoing.example/custom?source=outgoing")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, body)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.timeoutInterval, 12)
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Custom"), "value")
        XCTAssertNil(request.value(forHTTPHeaderField: "x-mp-signature"))
    }

    func testCustomRequestDefaultsNilMethodToGet() throws {
        let request = try XCTUnwrap(makeBuilder(kind: .custom, message: nil, httpMethod: nil).build())

        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testMalformedAndNonStringCustomHeadersAreIgnoredSafely() throws {
        var messages: [String] = []
        let logger = MPLog(logLevel: .warning)
        logger.customLogger = { messages.append($0) }

        let malformedRequest = try XCTUnwrap(
            makeBuilder(kind: .custom, message: nil, logger: logger)
                .withHeaderData(Data("not-json".utf8))
                .build()
        )
        let arrayRequest = try XCTUnwrap(
            makeBuilder(kind: .custom, message: nil, logger: logger)
                .withHeaderData(try JSONSerialization.data(withJSONObject: ["value"]))
                .build()
        )
        let mixedRequest = try XCTUnwrap(
            makeBuilder(kind: .custom, message: nil, logger: logger)
                .withHeaderData(try JSONSerialization.data(withJSONObject: [
                    "X-Valid": "value",
                    "X-Invalid": 42
                ]))
                .build()
        )

        XCTAssertTrue(malformedRequest.allHTTPHeaderFields?.isEmpty ?? true)
        XCTAssertTrue(arrayRequest.allHTTPHeaderFields?.isEmpty ?? true)
        XCTAssertEqual(mixedRequest.value(forHTTPHeaderField: "X-Valid"), "value")
        XCTAssertNil(mixedRequest.value(forHTTPHeaderField: "X-Invalid"))
        XCTAssertEqual(messages.filter { $0.contains("malformed") }.count, 2)
        XCTAssertTrue(messages.contains { $0.contains("non-string") })
    }

    func testAudienceSignsOutgoingPathAndQuery() throws {
        let request = try XCTUnwrap(makeBuilder(kind: .audience, message: nil).build())
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))
        let message = "GET\n\(date)\n/custom?source=outgoing"

        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-key"), "api-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "test-agent")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-signature"), signature(message))
    }

    func testAudienceAllowsQuerylessURLWithoutSigningTrailingQuestionMark() throws {
        let outgoingURL = URL(string: "https://outgoing.example/audience")!
        let request = try XCTUnwrap(
            makeBuilder(kind: .audience, message: nil, url: outgoingURL).build()
        )
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "x-mp-signature"),
            signature("GET\n\(date)\n/audience")
        )
    }

    func testAudienceRejectsOverlongOutgoingQuery() {
        let query = String(repeating: "a", count: 8193)
        let outgoingURL = URL(string: "https://outgoing.example/audience?\(query)")!

        XCTAssertNil(makeBuilder(kind: .audience, message: nil, url: outgoingURL).build())
    }

    func testIdentityAndAliasSignCanonicalPathAndPostData() throws {
        let body = Data(#"{"identity":"value"}"#.utf8)
        let request = try XCTUnwrap(
            makeBuilder(kind: .identity, message: "alias", httpMethod: "POST")
                .withPostData(body)
                .build()
        )
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))
        let bodyString = try XCTUnwrap(String(data: body, encoding: .utf8))
        let message = "POST\n\(date)\n/v1/api-key/identity\(bodyString)"

        XCTAssertEqual(request.url?.host, "outgoing.example")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-key"), "api-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-signature"), signature(message))
        XCTAssertEqual(request.httpBody, body)
    }

    func testIdentityRejectsNilAndInvalidUTF8PostData() {
        XCTAssertNil(makeBuilder(kind: .identity, message: nil).build())
        XCTAssertNil(
            makeBuilder(kind: .identity, message: nil)
                .withPostData(Data([0xFF, 0xFE]))
                .build()
        )
    }

    func testEventSignsUncompressedMessageAndSendsSuppliedBody() throws {
        let message = #"{"dt":"npe","events":[]}"#
        let compressedBody = Data([0x1F, 0x8B, 0x08, 0x00])
        let request = try XCTUnwrap(
            makeBuilder(kind: .event, message: message, httpMethod: "POST")
                .withPostData(compressedBody)
                .build()
        )
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))
        let signingMessage = "POST\n\(date)\n/v1/api-key/identity\(message)"

        XCTAssertEqual(request.httpBody, compressedBody)
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-signature"), signature(signingMessage))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Encoding"), "gzip")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-bundled-kits"), "1,2")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-kits"), "7")
        XCTAssertEqual(request.value(forHTTPHeaderField: "npe"), "npe")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "test-agent")
    }

    func testEventRejectsNilMessage() {
        XCTAssertNil(makeBuilder(kind: .event, message: nil).build())
    }

    func testConfigUsesCanonicalQueryAndConditionalETag() throws {
        let request = try XCTUnwrap(makeBuilder(kind: .config, message: nil).build())
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))
        let message = "GET\n\(date)\n/v1/api-key/identity?source=canonical"

        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-signature"), signature(message))
        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "etag-value")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-kits"), "1,2")
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-mp-env"), "1")
        XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), "test-agent")
        XCTAssertEqual(request.value(forHTTPHeaderField: "locale"), "en_US")
        XCTAssertEqual(request.value(forHTTPHeaderField: "timezone"), "GMT")
        XCTAssertEqual(request.value(forHTTPHeaderField: "secondsFromGMT"), "0")
    }

    func testConfigOmitsETagWithoutStoredConfiguration() throws {
        let context = makeContext(hasStoredConfiguration: false)
        let request = try XCTUnwrap(makeBuilder(kind: .config, message: nil, context: context).build())

        XCTAssertNil(request.value(forHTTPHeaderField: "If-None-Match"))
    }

    func testConfigAllowsQuerylessCanonicalURLWithoutSigningTrailingQuestionMark() throws {
        let canonicalURL = URL(string: "https://canonical.example/config")!
        let request = try XCTUnwrap(
            makeBuilder(kind: .config, message: nil, defaultURL: canonicalURL).build()
        )
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "x-mp-signature"),
            signature("GET\n\(date)\n/config")
        )
    }

    func testConfigRejectsOverlongCanonicalQuery() {
        let query = String(repeating: "a", count: 8193)
        let canonicalURL = URL(string: "https://canonical.example/config?\(query)")!

        XCTAssertNil(makeBuilder(kind: .config, message: nil, defaultURL: canonicalURL).build())
    }

    func testCustomSecretOverridesFallbackSecret() throws {
        let request = try XCTUnwrap(
            makeBuilder(kind: .audience, message: nil)
                .withSecret("override-secret")
                .build()
        )
        let date = try XCTUnwrap(request.value(forHTTPHeaderField: "Date"))
        let message = "GET\n\(date)\n/custom?source=outgoing"

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "x-mp-signature"),
            signature(message, secret: "override-secret")
        )
        XCTAssertNotEqual(request.value(forHTTPHeaderField: "x-mp-signature"), signature(message))
    }

    func testMissingSecretOmitsSignatureWithoutFailingRequest() throws {
        let context = makeContext(fallbackSecret: nil)
        let request = try XCTUnwrap(makeBuilder(kind: .audience, message: nil, context: context).build())

        XCTAssertNil(request.value(forHTTPHeaderField: "x-mp-signature"))
    }

    func testNilURLsFailInitializationAndLog() {
        var messages: [String] = []
        let logger = MPLog(logLevel: .error)
        logger.customLogger = { messages.append($0) }
        let context = makeContext(logger: logger)

        XCTAssertNil(
            MPURLRequestBuilder(
                url: nil,
                defaultURL: URL(string: "https://canonical.example")!,
                message: nil,
                httpMethod: "GET",
                requestKind: .custom,
                context: context
            )
        )
        XCTAssertNil(
            MPURLRequestBuilder(
                url: URL(string: "https://outgoing.example")!,
                defaultURL: nil,
                message: nil,
                httpMethod: "GET",
                requestKind: .custom,
                context: context
            )
        )
        XCTAssertEqual(messages.count, 2)
    }

    private func makeBuilder(
        kind: MPURLRequestKind,
        message: String?,
        httpMethod: String? = "GET",
        url: URL = URL(string: "https://outgoing.example/custom?source=outgoing")!,
        defaultURL: URL = URL(string: "https://canonical.example/v1/api-key/identity?source=canonical")!,
        context: MPURLRequestContext? = nil,
        logger: MPLog? = nil
    ) -> MPURLRequestBuilder {
        MPURLRequestBuilder(
            url: url,
            defaultURL: defaultURL,
            message: message,
            httpMethod: httpMethod,
            requestKind: kind,
            context: context ?? makeContext(logger: logger),
            now: { self.fixedDate },
            localeIdentifier: { "en_US" },
            timeZone: { self.utc }
        )!
    }

    private func makeContext(
        fallbackSecret: String? = "fallback-secret",
        hasStoredConfiguration: Bool = true,
        logger: MPLog? = nil
    ) -> MPURLRequestContext {
        MPURLRequestContext(
            apiKey: "api-key",
            fallbackSecret: fallbackSecret,
            userAgent: "test-agent",
            supportedKits: [1, 2],
            configuredKits: [7],
            eTag: "etag-value",
            hasStoredConfiguration: hasStoredConfiguration,
            environment: 1,
            requestTimeout: 12,
            networkPerformanceMessageType: "npe",
            logger: logger ?? MPLog(logLevel: .none)
        )
    }

    private func signature(_ message: String, secret: String = "fallback-secret") -> String? {
        MPRequestSigner.hmacSHA256Hex(message: message, key: secret)
    }
}
