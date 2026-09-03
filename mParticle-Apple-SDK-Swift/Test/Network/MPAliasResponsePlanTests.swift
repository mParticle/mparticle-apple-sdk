import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPAliasResponsePlanTests: XCTestCase {
    private let logger = MPLog(logLevel: .none)

    private func data(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }

    private func plan(
        request: Any? = nil,
        response: Any? = nil,
        statusCode: Int
    ) throws -> MPAliasResponsePlanPRIVATE {
        MPAliasResponsePlanPRIVATE.plan(
            requestData: try request.map { try data($0) },
            responseData: try response.map { try data($0) },
            statusCode: statusCode,
            logger: logger
        )
    }

    // MARK: - Status classification

    func testSuccessCodePredicateCoversThe2xxRange() {
        XCTAssertFalse(MPAliasResponsePlanPRIVATE.isSuccessCode(199))
        XCTAssertTrue(MPAliasResponsePlanPRIVATE.isSuccessCode(200))
        XCTAssertTrue(MPAliasResponsePlanPRIVATE.isSuccessCode(299))
        XCTAssertFalse(MPAliasResponsePlanPRIVATE.isSuccessCode(300))
        XCTAssertEqual(NSStringFromClass(MPAliasResponsePlanPRIVATE.self), "MPAliasResponsePlanPRIVATE")
    }

    func testSuccessCodeIsNeitherInvalidNorRetriable() throws {
        let plan = try plan(statusCode: 202)

        XCTAssertTrue(plan.isSuccessCode)
        XCTAssertFalse(plan.isInvalidCode)
        XCTAssertFalse(plan.shouldRetry)
    }

    func testClientErrorsAreInvalidAndNotRetriable() throws {
        for statusCode in [400, 401, 404, 499] {
            let plan = try plan(statusCode: statusCode)
            XCTAssertFalse(plan.isSuccessCode, "\(statusCode)")
            XCTAssertTrue(plan.isInvalidCode, "\(statusCode)")
            XCTAssertFalse(plan.shouldRetry, "\(statusCode)")
        }
    }

    func testTooManyRequestsAndServiceUnavailableRetryWithoutBeingInvalid() throws {
        for statusCode in [429, 503] {
            let plan = try plan(statusCode: statusCode)
            XCTAssertFalse(plan.isSuccessCode, "\(statusCode)")
            XCTAssertFalse(plan.isInvalidCode, "\(statusCode)")
            XCTAssertTrue(plan.shouldRetry, "\(statusCode)")
        }
    }

    func testOtherServerErrorsAreNeitherInvalidNorRetriable() throws {
        let plan = try plan(statusCode: 500)

        XCTAssertFalse(plan.isSuccessCode)
        XCTAssertFalse(plan.isInvalidCode)
        XCTAssertFalse(plan.shouldRetry)
    }

    // MARK: - Request echo

    /// Mirrors the body `MPIdentityHTTPRequestBuilderPRIVATE.aliasDictionary` actually uploads:
    /// `request_id` at the top level, the alias window nested under `data`.
    func testRecoversRequestFieldsFromTheUploadedBody() throws {
        let request: [String: Any] = [
            "request_id": "04B0B49E-B2F1-48B5-81E6-A9F9FDB529F5",
            "request_type": "alias",
            "data": [
                "source_mpid": 111,
                "destination_mpid": 222,
                "start_unixtime_ms": 100_000,
                "end_unixtime_ms": 200_000
            ]
        ]

        let plan = try plan(request: request, statusCode: 202)

        XCTAssertEqual(plan.requestID, "04B0B49E-B2F1-48B5-81E6-A9F9FDB529F5")
        XCTAssertEqual(plan.sourceMPID, 111)
        XCTAssertEqual(plan.destinationMPID, 222)
        XCTAssertEqual(plan.startTime, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(plan.endTime, Date(timeIntervalSince1970: 200))
    }

    func testFallsBackToTopLevelAliasFields() throws {
        let request: [String: Any] = [
            "request_id": "abc",
            "source_mpid": 111,
            "destination_mpid": 222,
            "start_unixtime_ms": 100_000,
            "end_unixtime_ms": 200_000
        ]

        let plan = try plan(request: request, statusCode: 202)

        XCTAssertEqual(plan.sourceMPID, 111)
        XCTAssertEqual(plan.destinationMPID, 222)
        XCTAssertEqual(plan.startTime, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(plan.endTime, Date(timeIntervalSince1970: 200))
    }

    func testMissingTimestampsReadAsTheEpoch() throws {
        let plan = try plan(request: ["request_id": "abc", "data": [String: Any]()], statusCode: 202)

        XCTAssertEqual(plan.requestID, "abc")
        XCTAssertNil(plan.sourceMPID)
        XCTAssertNil(plan.destinationMPID)
        XCTAssertEqual(plan.startTime, Date(timeIntervalSince1970: 0))
        XCTAssertEqual(plan.endTime, Date(timeIntervalSince1970: 0))
    }

    func testMalformedRequestBodyLeavesFieldsEmpty() {
        let plan = MPAliasResponsePlanPRIVATE.plan(
            requestData: Data("{ not json".utf8),
            responseData: nil,
            statusCode: 202,
            logger: logger
        )

        XCTAssertNil(plan.requestID)
        XCTAssertNil(plan.sourceMPID)
        XCTAssertEqual(plan.startTime, Date(timeIntervalSince1970: 0))
    }

    // MARK: - Error body

    func testErrorMessageIsReadFromAFailedResponse() throws {
        let plan = try plan(response: ["message": "Alias window too large", "code": 5], statusCode: 400)

        XCTAssertEqual(plan.errorMessage, "Alias window too large")
    }

    func testErrorBodyIsIgnoredOnSuccess() throws {
        let plan = try plan(response: ["message": "ignored"], statusCode: 202)

        XCTAssertNil(plan.errorMessage)
    }

    func testMalformedErrorBodyYieldsNoMessage() {
        let plan = MPAliasResponsePlanPRIVATE.plan(
            requestData: nil,
            responseData: Data("{ not json".utf8),
            statusCode: 400,
            logger: logger
        )

        XCTAssertNil(plan.errorMessage)
    }

    func testEmptyErrorBodyYieldsNoMessage() {
        let plan = MPAliasResponsePlanPRIVATE.plan(
            requestData: nil,
            responseData: Data(),
            statusCode: 400,
            logger: logger
        )

        XCTAssertNil(plan.errorMessage)
    }
}
