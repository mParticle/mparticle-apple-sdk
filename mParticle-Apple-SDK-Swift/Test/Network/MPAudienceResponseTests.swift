import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPAudienceResponseTests: XCTestCase {
    private let logger = MPLog(logLevel: .none)

    private func body(_ object: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }

    private func decode(_ object: Any, statusCode: Int = 200) throws -> MPAudienceResponsePRIVATE {
        MPAudienceResponsePRIVATE.response(from: try body(object), statusCode: statusCode, logger: logger)
    }

    // MARK: - Keys must stay identical to the exported Objective-C constants

    func testWireKeysMatchObjectiveCConstants() {
        XCTAssertEqual(AudienceKeys.membership, "audience_memberships")
        XCTAssertEqual(AudienceKeys.audienceID, "audience_id")
        XCTAssertEqual(NSStringFromClass(MPAudienceResponsePRIVATE.self), "MPAudienceResponsePRIVATE")
    }

    // MARK: - Missing body

    func testNilDataProducesNotEnabledError() throws {
        let response = MPAudienceResponsePRIVATE.response(from: nil, statusCode: 404, logger: logger)

        XCTAssertFalse(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
        let error = try XCTUnwrap(response.error)
        XCTAssertEqual(error.domain, "mParticle Audiences")
        XCTAssertEqual(error.code, 404)
        XCTAssertEqual(error.userInfo["message"] as? String, "Audiences may not be enabled for this org.")
    }

    func testEmptyDataIsNotSuccess() {
        let response = MPAudienceResponsePRIVATE.response(from: Data(), statusCode: 200, logger: logger)

        XCTAssertFalse(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
        XCTAssertNil(response.error)
    }

    // MARK: - Successful decoding

    func testDecodesAudienceIdentifiersInResponseOrder() throws {
        let payload = ["audience_memberships": [["audience_id": 3], ["audience_id": 1], ["audience_id": 2]]]

        let response = try decode(payload)

        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.audienceIDs, [3, 1, 2])
        XCTAssertNil(response.error)
    }

    func testAcceptedStatusCodeIsSuccess() throws {
        let response = try decode(["audience_memberships": [["audience_id": 7]]], statusCode: 202)

        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.audienceIDs, [7])
    }

    func testUnhandledSuccessCodeIsNotSuccessAndSkipsDecoding() throws {
        let response = try decode(["audience_memberships": [["audience_id": 7]]], statusCode: 204)

        XCTAssertFalse(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
    }

    // MARK: - Bodies that decode to nothing

    func testEmptyMembershipArrayYieldsNoIdentifiers() throws {
        let response = try decode(["audience_memberships": []])

        XCTAssertTrue(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
    }

    func testMissingMembershipKeyYieldsNoIdentifiers() throws {
        let response = try decode(["something_else": 1])

        XCTAssertTrue(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
    }

    func testNonDictionaryBodyYieldsNoIdentifiersWithoutCrashing() throws {
        let response = try decode([["audience_id": 1]])

        XCTAssertTrue(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
    }

    func testMalformedJSONIsNotSuccess() {
        let data = Data("{ not json".utf8)

        let response = MPAudienceResponsePRIVATE.response(from: data, statusCode: 200, logger: logger)

        XCTAssertFalse(response.isSuccess)
        XCTAssertTrue(response.audienceIDs.isEmpty)
    }

    // MARK: - Identifier validation

    func testNonNumericAndNullIdentifiersAreSkipped() throws {
        let payload: [String: Any] = ["audience_memberships": [
            ["audience_id": 1],
            ["audience_id": "not-a-number"],
            ["audience_id": NSNull()],
            ["no_id_at_all": 9],
            "not-even-a-dictionary",
            ["audience_id": 2]
        ]]

        let response = try decode(payload)

        XCTAssertTrue(response.isSuccess)
        XCTAssertEqual(response.audienceIDs, [1, 2])
    }

    // MARK: - Forbidden

    func testForbiddenProducesNotEnabledError() throws {
        let response = MPAudienceResponsePRIVATE.response(from: Data("{}".utf8), statusCode: 403, logger: logger)

        XCTAssertFalse(response.isSuccess)
        let error = try XCTUnwrap(response.error)
        XCTAssertEqual(error.domain, "mParticle Audiences")
        XCTAssertEqual(error.code, 403)
        XCTAssertEqual(error.userInfo["message"] as? String, "Audiences not enabled for this org.")
    }
}
