import XCTest
internal import mParticle_Apple_SDK_Swift

final class MPTransportErrorDetectorTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MPTransportErrorDetector.resetTransportErrorCounter()
    }

    func test_isRetriableTransportError_returnsFalse_whenErrorIsNil() {
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(nil))
    }

    func test_isRetriableTransportError_returnsFalse_whenNoConnectionCode() {
        let error = NSError(domain: "any-domain", code: 1)
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsTrue_whenNSURLErrorIsRetriable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost)
        XCTAssertTrue(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsFalse_whenNSURLErrorIsNotRetriable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsFalse_whenNSURLErrorIsNotConnectedToInternet() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsFalse_whenNSURLErrorIsTimedOut() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsTrue_forMParticleTimeoutError() {
        let error = NSError(domain: "com.mparticle", code: 0)
        XCTAssertTrue(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsFalse_forUnknownError() {
        let error = NSError(domain: "custom-domain", code: 42)
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_calculateRetryTimeForTransportError_usesSmallValueForFirstError() {
        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 60)
    }

    func test_calculateRetryTimeForTransportError_reachesMaxAtFiveErrors() {
        for _ in 0..<4 {
            _ = MPTransportErrorDetector.calculateRetryTimeForTransportError()
        }

        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 86400)
    }

    func test_calculateRetryTimeForTransportError_usesExpectedBackoffSchedule() {
        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 60)
        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 300)
        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 1800)
        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 21600)
        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 86400)
    }

    func test_calculateRetryTimeForTransportError_staysAtMaxAfterThreshold() {
        for _ in 0..<5 {
            _ = MPTransportErrorDetector.calculateRetryTimeForTransportError()
        }

        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 86400)
    }

    func test_resetTransportErrorCounter_resetsBackoff() {
        _ = MPTransportErrorDetector.calculateRetryTimeForTransportError()
        _ = MPTransportErrorDetector.calculateRetryTimeForTransportError()
        MPTransportErrorDetector.resetTransportErrorCounter()

        XCTAssertEqual(MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue, 60)
    }
}
