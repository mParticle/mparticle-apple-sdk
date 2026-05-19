import Foundation

@objc public class MPTransportErrorDetector: NSObject {
    private static let maxRetryAfter: Double = 300
    private static let maxErrorCountBeforeMaxRetry = 5
    private static let retryAfterSchedule: [Double] = [5, 15, 60, 120, 300]
    private static var consecutiveTransportErrorCount = 0
    private static let backoffQueue = DispatchQueue(label: "com.mparticle.transport-error-backoff")
    private static let semaphoreTimeoutErrorDomainValue = "com.mparticle"
    private static let semaphoreTimeoutErrorCodeValue = 0

    @objc(semaphoreTimeoutErrorDomain)
    public static func semaphoreTimeoutErrorDomain() -> NSString {
        semaphoreTimeoutErrorDomainValue as NSString
    }

    @objc(semaphoreTimeoutErrorCode)
    public static func semaphoreTimeoutErrorCode() -> NSNumber {
        NSNumber(value: semaphoreTimeoutErrorCodeValue)
    }

    @objc(isRetriableTransportError:)
    public static func isRetriableTransportError(_ error: NSError?) -> Bool {
        guard let error else {
            return false
        }

        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNotConnectedToInternet,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorTimedOut,
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

        return error.domain == semaphoreTimeoutErrorDomainValue
            && error.code == semaphoreTimeoutErrorCodeValue
    }

    @objc(calculateRetryTimeForTransportError)
    public static func calculateRetryTimeForTransportError() -> NSNumber {
        return backoffQueue.sync {
            consecutiveTransportErrorCount += 1

            if consecutiveTransportErrorCount >= maxErrorCountBeforeMaxRetry {
                return NSNumber(value: maxRetryAfter)
            }

            guard !retryAfterSchedule.isEmpty else {
                return NSNumber(value: maxRetryAfter)
            }

            let scheduleIndex = min(
                max(0, consecutiveTransportErrorCount - 1),
                retryAfterSchedule.count - 1
            )
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
