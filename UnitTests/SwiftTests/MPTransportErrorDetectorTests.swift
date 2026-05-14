import XCTest
internal import mParticle_Apple_SDK_Swift

final class MPTransportErrorDetectorTests: XCTestCase {
    func test_isRetriableTransportError_returnsFalse_whenErrorIsNil() {
        XCTAssertFalse(MPTransportErrorDetector.isRetriableTransportError(nil))
    }

    func test_isRetriableTransportError_returnsTrue_whenNoConnectionCode() {
        let error = NSError(domain: "any-domain", code: 1)
        XCTAssertTrue(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsTrue_whenNSURLErrorIsRetriable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)
        XCTAssertTrue(MPTransportErrorDetector.isRetriableTransportError(error))
    }

    func test_isRetriableTransportError_returnsFalse_whenNSURLErrorIsNotRetriable() {
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)
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
}
