import Foundation

@objc public class MPTransportErrorDetector: NSObject {
    private static let maxRetryAfter: Double = 86400
    private static let maxErrorCountBeforeMaxRetry = 5
    private static let retryAfterSchedule: [Double] = [60, 300, 1800, 21600]
    private static var consecutiveTransportErrorCount = 0
    private static let backoffQueue = DispatchQueue(label: "com.mparticle.transport-error-backoff")
    private static let semaphoreTimeoutErrorDomain = "com.mparticle"
    private static let semaphoreTimeoutErrorCode = 0

    @objc(isRetriableTransportError:)
    public static func isRetriableTransportError(_ error: NSError?) -> Bool {
        guard let error else {
            return false
        }

        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorCannotLoadFromNetwork,
                NSURLErrorSecureConnectionFailed,
                NSURLErrorInternationalRoamingOff,
                NSURLErrorDataNotAllowed,
                NSURLErrorCallIsActive,
                NSURLErrorAppTransportSecurityRequiresSecureConnection:
                return true
            default:
                return false
            }
        }

        return error.domain == semaphoreTimeoutErrorDomain
            && error.code == semaphoreTimeoutErrorCode
    }

    @objc(calculateRetryTimeForTransportError)
    public static func calculateRetryTimeForTransportError() -> NSNumber {
        return backoffQueue.sync {
            consecutiveTransportErrorCount += 1

            if consecutiveTransportErrorCount >= maxErrorCountBeforeMaxRetry {
                return NSNumber(value: maxRetryAfter)
            }

            let scheduleIndex = max(0, consecutiveTransportErrorCount - 1)
            return NSNumber(value: retryAfterSchedule[scheduleIndex])
        }
    }

    @objc(resetTransportErrorCounter)
    public static func resetTransportErrorCounter() {
        backoffQueue.sync {
            consecutiveTransportErrorCount = 0
        }
    }
}
