import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPAliasUploadOutcomeTests: XCTestCase {
    private let logger = MPLog(logLevel: .none)

    private func outcome(response: Any? = nil, statusCode: Int) throws -> MPAliasUploadOutcomePRIVATE {
        MPAliasUploadOutcomePRIVATE.outcome(
            responseData: try response.map { try JSONSerialization.data(withJSONObject: $0) },
            statusCode: statusCode,
            logger: logger
        )
    }

    // MARK: - Status classification

    func testPreservesObjectiveCRuntimeName() {
        XCTAssertEqual(NSStringFromClass(MPAliasUploadOutcomePRIVATE.self), "MPAliasUploadOutcomePRIVATE")
    }

    func testSuccessRangeBoundaries() throws {
        XCTAssertFalse(try outcome(statusCode: 199).isSuccessCode)
        XCTAssertTrue(try outcome(statusCode: 200).isSuccessCode)
        XCTAssertTrue(try outcome(statusCode: 299).isSuccessCode)
        XCTAssertFalse(try outcome(statusCode: 300).isSuccessCode)
    }

    func testSuccessCodeIsNeitherInvalidNorRetriable() throws {
        let outcome = try outcome(statusCode: 202)

        XCTAssertTrue(outcome.isSuccessCode)
        XCTAssertFalse(outcome.isInvalidCode)
        XCTAssertFalse(outcome.shouldRetry)
    }

    func testClientErrorsAreInvalidAndNotRetriable() throws {
        for statusCode in [400, 401, 404, 499] {
            let outcome = try outcome(statusCode: statusCode)
            XCTAssertFalse(outcome.isSuccessCode, "\(statusCode)")
            XCTAssertTrue(outcome.isInvalidCode, "\(statusCode)")
            XCTAssertFalse(outcome.shouldRetry, "\(statusCode)")
        }
    }

    func testTooManyRequestsAndServiceUnavailableRetryWithoutBeingInvalid() throws {
        for statusCode in [429, 503] {
            let outcome = try outcome(statusCode: statusCode)
            XCTAssertFalse(outcome.isSuccessCode, "\(statusCode)")
            XCTAssertFalse(outcome.isInvalidCode, "\(statusCode)")
            XCTAssertTrue(outcome.shouldRetry, "\(statusCode)")
        }
    }

    func testOtherServerErrorsAreNeitherInvalidNorRetriable() throws {
        let outcome = try outcome(statusCode: 500)

        XCTAssertFalse(outcome.isSuccessCode)
        XCTAssertFalse(outcome.isInvalidCode)
        XCTAssertFalse(outcome.shouldRetry)
    }

    // MARK: - Failure logging must not crash on any body

    func testFailureBodyIsLoggedWithoutAffectingClassification() throws {
        let outcome = try outcome(response: ["message": "Alias window too large", "code": 5], statusCode: 400)

        XCTAssertTrue(outcome.isInvalidCode)
    }

    func testMalformedFailureBodyIsTolerated() {
        let outcome = MPAliasUploadOutcomePRIVATE.outcome(
            responseData: Data("{ not json".utf8),
            statusCode: 400,
            logger: logger
        )

        XCTAssertTrue(outcome.isInvalidCode)
    }

    func testEmptyAndMissingFailureBodiesAreTolerated() throws {
        XCTAssertTrue(
            MPAliasUploadOutcomePRIVATE.outcome(responseData: Data(), statusCode: 400, logger: logger).isInvalidCode
        )
        XCTAssertTrue(try outcome(statusCode: 400).isInvalidCode)
    }

    func testNonDictionaryFailureBodyIsTolerated() throws {
        let outcome = try outcome(response: ["message"], statusCode: 400)

        XCTAssertTrue(outcome.isInvalidCode)
    }
}
