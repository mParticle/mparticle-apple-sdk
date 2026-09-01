import XCTest
@testable import mParticle_Apple_SDK_Swift

final class MPRequestSignerTests: XCTestCase {
    func testHmacMatchesObjCReferenceVector() {
        let hex = MPRequestSigner.hmacSHA256Hex(
            message: "The Quick Brown Fox Jumps Over The Lazy Dog.",
            key: "unit-test-key"
        )

        XCTAssertEqual(hex, "89d8de8ab8d91aaf359ba160921cc15b0621216964e3766860e0788c7f8f62e2")
    }

    func testHmacIsLowercaseHexOf32Bytes() {
        let hex = MPRequestSigner.hmacSHA256Hex(message: "message", key: "key")

        XCTAssertEqual(hex?.count, 64)
        XCTAssertEqual(hex, hex?.lowercased())
    }

    func testHmacReturnsNilForNilMessage() {
        XCTAssertNil(MPRequestSigner.hmacSHA256Hex(message: nil, key: "key"))
    }

    func testHmacReturnsNilForNilKey() {
        XCTAssertNil(MPRequestSigner.hmacSHA256Hex(message: "message", key: nil))
    }

    func testHmacEncodesEmptyMessage() {
        XCTAssertNotNil(MPRequestSigner.hmacSHA256Hex(message: "", key: "key"))
    }

    func testHmacTruncatesMessageAtEmbeddedNUL() {
        let truncated = MPRequestSigner.hmacSHA256Hex(message: "abc\0def", key: "key")
        let reference = MPRequestSigner.hmacSHA256Hex(message: "abc", key: "key")

        XCTAssertEqual(truncated, reference)
    }

    func testHmacTruncatesKeyAtEmbeddedNUL() {
        let truncated = MPRequestSigner.hmacSHA256Hex(message: "message", key: "abc\0def")
        let reference = MPRequestSigner.hmacSHA256Hex(message: "message", key: "abc")

        XCTAssertEqual(truncated, reference)
    }

    func testSignatureMessageWithQueryJoinsWithQuestionMark() {
        let signature = MPRequestSigner.signatureMessage(
            httpMethod: "GET",
            date: "Thu, 27 Aug 2026 12:00:00 GMT",
            relativePath: "/v4/key/config",
            query: "av=1.0&sv=9.0.0"
        )

        XCTAssertEqual(signature, "GET\nThu, 27 Aug 2026 12:00:00 GMT\n/v4/key/config?av=1.0&sv=9.0.0")
    }

    func testSignatureMessageOmitsQuestionMarkForNilQuery() {
        let signature = MPRequestSigner.signatureMessage(
            httpMethod: "GET",
            date: "Thu, 27 Aug 2026 12:00:00 GMT",
            relativePath: "/v4/key/config",
            query: nil
        )

        XCTAssertEqual(signature, "GET\nThu, 27 Aug 2026 12:00:00 GMT\n/v4/key/config")
    }

    func testSignatureMessageKeepsEmptyQueryQuestionMark() {
        let signature = MPRequestSigner.signatureMessage(
            httpMethod: "GET",
            date: "d",
            relativePath: "/p",
            query: ""
        )

        XCTAssertEqual(signature, "GET\nd\n/p?")
    }

    func testSignatureMessageWithBodyConcatenatesWithoutSeparator() {
        let signature = MPRequestSigner.signatureMessage(
            httpMethod: "POST",
            date: "Thu, 27 Aug 2026 12:00:00 GMT",
            relativePath: "/v1/identify",
            body: "{\"mpid\":1}"
        )

        XCTAssertEqual(signature, "POST\nThu, 27 Aug 2026 12:00:00 GMT\n/v1/identify{\"mpid\":1}")
    }

    func testExceedsMaxQueryLengthAtBoundary() {
        XCTAssertFalse(MPRequestSigner.exceedsMaxQueryLength(String(repeating: "a", count: 8192)))
        XCTAssertTrue(MPRequestSigner.exceedsMaxQueryLength(String(repeating: "a", count: 8193)))
    }

    func testExceedsMaxQueryLengthIsFalseForNilAndEmpty() {
        XCTAssertFalse(MPRequestSigner.exceedsMaxQueryLength(nil))
        XCTAssertFalse(MPRequestSigner.exceedsMaxQueryLength(""))
    }

    func testExceedsMaxQueryLengthCountsUTF16Units() {
        XCTAssertTrue(MPRequestSigner.exceedsMaxQueryLength(String(repeating: "😀", count: 4097)))
        XCTAssertFalse(MPRequestSigner.exceedsMaxQueryLength(String(repeating: "😀", count: 4096)))
    }
}
