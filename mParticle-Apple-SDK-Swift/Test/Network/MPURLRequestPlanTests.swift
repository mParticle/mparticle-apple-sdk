import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPURLRequestPlanTests: XCTestCase {
    private let date = "Thu, 27 Aug 2026 12:00:00 GMT"
    private let utcLocaleHeaders = MPLocaleHeaders(
        deviceLocale: "en_US", timeZoneName: "UTC", secondsFromGMT: 0
    )

    // MARK: - Audience

    func testAudiencePlanHeaders() {
        let plan = MPURLRequestPlan.audiencePlan(
            target: target(method: "GET", path: "/v1/key/audience"),
            query: "mpid=12",
            apiKey: "key",
            userAgent: "agent"
        )

        XCTAssertNil(plan.failureReason)
        XCTAssertEqual(plan.signatureMessage, "GET\n\(date)\n/v1/key/audience?mpid=12")
        XCTAssertEqual(plan.headers["Date"], date)
        XCTAssertEqual(plan.headers["x-mp-key"], "key")
        XCTAssertEqual(plan.headers["User-Agent"], "agent")
    }

    func testAudiencePlanSendsNoGzipOrContentTypeHeaders() {
        let plan = audiencePlan()

        XCTAssertNil(plan.headers["Accept-Encoding"])
        XCTAssertNil(plan.headers["Content-Encoding"])
        XCTAssertNil(plan.headers["Content-Type"])
        XCTAssertNil(plan.headers["locale"])
        XCTAssertNil(plan.headers["timezone"])
    }

    func testAudiencePlanOmitsUserAgentWhenNil() {
        let plan = MPURLRequestPlan.audiencePlan(
            target: target(method: "GET", path: "/p"),
            query: nil,
            apiKey: "key",
            userAgent: nil
        )

        XCTAssertNil(plan.failureReason)
        XCTAssertNil(plan.headers["User-Agent"])
    }

    func testAudiencePlanFailsForNilRelativePath() {
        let plan = MPURLRequestPlan.audiencePlan(
            target: target(method: "GET", path: nil), query: nil,
            apiKey: "key", userAgent: nil
        )

        XCTAssertEqual(plan.failureReason, "audience relative path is nil")
        XCTAssertTrue(plan.headers.isEmpty)
    }

    func testAudiencePlanFailsForOverlongQuery() {
        let plan = MPURLRequestPlan.audiencePlan(
            target: target(method: "GET", path: "/p"),
            query: String(repeating: "a", count: 8193),
            apiKey: "key", userAgent: nil
        )

        XCTAssertEqual(plan.failureReason, "audience query exceeds max supported length")
    }

    // MARK: - Identity

    func testIdentityPlanHeaders() {
        let plan = identityPlan(postData: Data(#"{"a":1}"#.utf8))

        XCTAssertNil(plan.failureReason)
        XCTAssertEqual(plan.signatureMessage, "POST\n\(date)\n/v1/identify{\"a\":1}")
        XCTAssertEqual(plan.headers["x-mp-key"], "key")
        XCTAssertEqual(plan.headers["Content-Type"], "application/json")
        XCTAssertEqual(plan.headers["locale"], "en_US")
        XCTAssertEqual(plan.headers["timezone"], "America/New_York")
        XCTAssertEqual(plan.headers["secondsFromGMT"], "-14400")
        XCTAssertEqual(plan.headers["Date"], date)
    }

    func testIdentityPlanAdvertisesGzipButDoesNotClaimAGzippedBody() {
        let plan = identityPlan(postData: Data("{}".utf8))

        XCTAssertEqual(plan.headers["Accept-Encoding"], "gzip")
        XCTAssertNil(plan.headers["Content-Encoding"])
    }

    func testIdentityPlanSendsNoUserAgentOrKitHeaders() {
        let plan = identityPlan(postData: Data("{}".utf8))

        XCTAssertNil(plan.headers["User-Agent"])
        XCTAssertNil(plan.headers["x-mp-kits"])
        XCTAssertNil(plan.headers["x-mp-bundled-kits"])
    }

    func testIdentityPlanFailsForNilPostData() {
        XCTAssertEqual(
            identityPlan(postData: nil).failureReason,
            "post data is nil for identity request"
        )
    }

    func testIdentityPlanFailsForNonUTF8PostData() {
        XCTAssertEqual(
            identityPlan(postData: Data([0xFF, 0xFE])).failureReason,
            "failed to encode post data as UTF-8"
        )
    }

    func testIdentityPlanFailsForNilRelativePath() {
        let plan = MPURLRequestPlan.identityPlan(
            target: target(method: "POST", path: nil),
            postData: Data("{}".utf8), apiKey: "key",
            localeHeaders: utcLocaleHeaders
        )

        XCTAssertEqual(plan.failureReason, "relative path is nil")
    }

    // MARK: - Events

    func testEventPlanUsesConfiguredKitsForKitsHeaderAndSupportedKitsForBundledKits() {
        let plan = eventPlan(
            supportedKits: [NSNumber(value: 1), NSNumber(value: 2)],
            configuredKits: [NSNumber(value: 7)]
        )

        XCTAssertEqual(plan.headers["x-mp-bundled-kits"], "1,2")
        XCTAssertEqual(plan.headers["x-mp-kits"], "7")
    }

    func testEventPlanOmitsKitHeadersForNilKitLists() {
        let plan = eventPlan(supportedKits: nil, configuredKits: nil)

        XCTAssertNil(plan.headers["x-mp-bundled-kits"])
        XCTAssertNil(plan.headers["x-mp-kits"])
    }

    func testEventPlanSendsEmptyKitHeadersForEmptyKitLists() {
        let plan = eventPlan(supportedKits: [], configuredKits: [])

        XCTAssertEqual(plan.headers["x-mp-bundled-kits"], "")
        XCTAssertEqual(plan.headers["x-mp-kits"], "")
    }

    func testEventPlanEchoesNetworkPerformanceMessageType() {
        let plan = eventPlan(message: #"{"dt":"npe"}"#)

        XCTAssertEqual(plan.headers["npe"], "npe")
    }

    func testEventPlanOmitsNetworkPerformanceHeaderForOtherMessages() {
        XCTAssertNil(eventPlan(message: #"{"dt":"e"}"#).headers["npe"])
    }

    func testEventPlanClaimsAGzippedBody() {
        let plan = eventPlan()

        XCTAssertEqual(plan.headers["Accept-Encoding"], "gzip")
        XCTAssertEqual(plan.headers["Content-Encoding"], "gzip")
        XCTAssertEqual(plan.headers["Content-Type"], "application/json")
    }

    func testEventPlanSignsTheMessageBody() {
        let plan = eventPlan(message: "BODY")

        XCTAssertEqual(plan.signatureMessage, "POST\n\(date)\n/v2/key/eventsBODY")
    }

    func testEventPlanSendsNoAPIKeyHeader() {
        XCTAssertNil(eventPlan().headers["x-mp-key"])
    }

    // MARK: - Config

    func testConfigPlanHeaders() {
        let plan = configPlan(eTag: nil, hasStoredConfiguration: false)

        XCTAssertNil(plan.failureReason)
        XCTAssertEqual(plan.headers["Content-Type"], "application/x-www-form-urlencoded")
        XCTAssertEqual(plan.headers["x-mp-env"], "1")
        XCTAssertEqual(plan.headers["Accept-Encoding"], "gzip")
        XCTAssertEqual(plan.headers["Content-Encoding"], "gzip")
        XCTAssertEqual(plan.signatureMessage, "GET\n\(date)\n/v4/key/config?av=1.0")
    }

    func testConfigPlanUsesSupportedKitsForKitsHeader() {
        let plan = configPlan(supportedKits: [NSNumber(value: 3), NSNumber(value: 4)])

        XCTAssertEqual(plan.headers["x-mp-kits"], "3,4")
        XCTAssertNil(plan.headers["x-mp-bundled-kits"])
    }

    func testConfigPlanSendsIfNoneMatchOnlyWithBothETagAndStoredConfiguration() {
        XCTAssertEqual(
            configPlan(eTag: "tag", hasStoredConfiguration: true).headers["If-None-Match"],
            "tag"
        )
        XCTAssertNil(configPlan(eTag: "tag", hasStoredConfiguration: false).headers["If-None-Match"])
        XCTAssertNil(configPlan(eTag: nil, hasStoredConfiguration: true).headers["If-None-Match"])
    }

    func testConfigPlanFailsForOverlongQuery() {
        let plan = configPlan(query: String(repeating: "a", count: 8193))

        XCTAssertEqual(plan.failureReason, "config query exceeds max supported length")
    }

    func testConfigPlanOmitsQuestionMarkForNilQuery() {
        XCTAssertEqual(configPlan(query: nil).signatureMessage, "GET\n\(date)\n/v4/key/config")
    }

    func testNoPlanSetsTheSignatureHeaderItself() {
        for headers in [audiencePlan().headers,
                        identityPlan(postData: Data("{}".utf8)).headers,
                        eventPlan().headers,
                        configPlan().headers] {
            XCTAssertNil(headers["x-mp-signature"])
        }
    }

    // MARK: - Helpers

    private func target(method: String, path: String?) -> MPRequestSigningTarget {
        MPRequestSigningTarget(httpMethod: method, date: date, relativePath: path)
    }

    private func audiencePlan() -> MPURLRequestPlan {
        MPURLRequestPlan.audiencePlan(
            target: target(method: "GET", path: "/v1/key/audience"), query: "mpid=12",
            apiKey: "key", userAgent: "agent"
        )
    }

    private func identityPlan(postData: Data?) -> MPURLRequestPlan {
        MPURLRequestPlan.identityPlan(
            target: target(method: "POST", path: "/v1/identify"),
            postData: postData, apiKey: "key",
            localeHeaders: MPLocaleHeaders(
                deviceLocale: "en_US", timeZoneName: "America/New_York", secondsFromGMT: -14400
            )
        )
    }

    private func eventPlan(
        message: String = "{}",
        supportedKits: [NSNumber]? = nil,
        configuredKits: [NSNumber]? = nil
    ) -> MPURLRequestPlan {
        MPURLRequestPlan.eventPlan(
            target: target(method: "POST", path: "/v2/key/events"), message: message,
            supportedKits: supportedKits, configuredKits: configuredKits,
            userAgent: "agent", localeHeaders: utcLocaleHeaders,
            networkPerformanceMessageType: "npe"
        )
    }

    private func configPlan(
        query: String? = "av=1.0",
        supportedKits: [NSNumber]? = nil,
        eTag: String? = nil,
        hasStoredConfiguration: Bool = false
    ) -> MPURLRequestPlan {
        MPURLRequestPlan.configPlan(
            target: target(method: "GET", path: "/v4/key/config"), query: query,
            supportedKits: supportedKits, eTag: eTag,
            hasStoredConfiguration: hasStoredConfiguration, userAgent: "agent",
            localeHeaders: utcLocaleHeaders, environment: 1
        )
    }
}
