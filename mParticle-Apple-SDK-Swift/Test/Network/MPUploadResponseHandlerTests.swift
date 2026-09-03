import XCTest
@testable import mParticle_Apple_SDK_Swift

private final class MockPersistence: MPUploadPersisting {
    var deleted: [MPUploadPRIVATE] = []
    func deleteUpload(_ upload: MPUploadPRIVATE) { deleted.append(upload) }
}

private final class MockKitBatch: MPKitBatchLogging {
    var logged: [String] = []
    func logKitBatch(_ uploadString: String) { logged.append(uploadString) }
}

final class MPUploadResponseHandlerTests: XCTestCase {
    private var persistence: MockPersistence!
    private var kitBatch: MockKitBatch!

    override func setUp() {
        super.setUp()
        persistence = MockPersistence()
        kitBatch = MockKitBatch()
    }

    private func makeUpload() -> MPUploadPRIVATE {
        MPUploadPRIVATE(sessionId: nil, uploadId: 1, uuid: "u", uploadData: Data(),
                        timestamp: 0, uploadType: 0, dataPlanId: nil, dataPlanVersion: nil,
                        uploadSettings: NSObject())
    }

    @discardableResult
    private func handle(_ statusCode: Int, error: NSError? = nil, uploadString: String? = "batch") -> MPUploadResponseOutcome {
        MPUploadResponseHandler.handleMessageResponse(
            statusCode: statusCode, transportError: error, headers: [:],
            uploadString: uploadString, upload: makeUpload(),
            persistence: persistence, kitBatchLogger: kitBatch)
    }

    func testSuccessDeletesLogsAndDoesNotRetry() {
        let outcome = handle(200)
        XCTAssertTrue(outcome.isSuccess)
        XCTAssertFalse(outcome.willRetry)
        XCTAssertFalse(outcome.shouldThrottle)
        XCTAssertEqual(persistence.deleted.count, 1)
        XCTAssertEqual(kitBatch.logged, ["batch"])
    }

    func testSuccessWithEmptyStringDoesNotLogKitBatch() {
        handle(200, uploadString: "")
        XCTAssertEqual(persistence.deleted.count, 1)
        XCTAssertTrue(kitBatch.logged.isEmpty)
    }

    func testInvalidCodeDeletesButDoesNotLogOrRetry() {
        let outcome = handle(400)
        XCTAssertFalse(outcome.isSuccess)
        XCTAssertFalse(outcome.willRetry)
        XCTAssertFalse(outcome.shouldThrottle)
        XCTAssertEqual(persistence.deleted.count, 1)
        XCTAssertTrue(kitBatch.logged.isEmpty)
    }

    func testTooManyRequestsThrottlesAndRetriesWithoutDeleting() {
        let outcome = handle(429)
        XCTAssertTrue(outcome.willRetry)
        XCTAssertTrue(outcome.shouldThrottle)
        XCTAssertTrue(persistence.deleted.isEmpty)
    }

    func testServiceUnavailableThrottlesAndRetriesWithoutDeleting() {
        let outcome = handle(503)
        XCTAssertTrue(outcome.willRetry)
        XCTAssertTrue(outcome.shouldThrottle)
        XCTAssertTrue(persistence.deleted.isEmpty)
    }

    func testServerErrorWithoutRetriableTransportRetriesWithoutThrottle() {
        let outcome = handle(500, error: nil)
        XCTAssertTrue(outcome.willRetry)
        XCTAssertFalse(outcome.shouldThrottle)
        XCTAssertTrue(persistence.deleted.isEmpty)
    }

    func testRetriableTransportErrorThrottlesAndRetries() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        let outcome = handle(0, error: error)
        XCTAssertTrue(outcome.willRetry)
        XCTAssertTrue(outcome.shouldThrottle)
    }
}
