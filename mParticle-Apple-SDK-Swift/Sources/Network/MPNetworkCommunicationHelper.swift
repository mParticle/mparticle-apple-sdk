import Foundation

@objc public final class MPNetworkCommunicationHelper: NSObject {
    @objc(calculateRetryTimeForHeaders:)
    public static func calculateRetryTime(for headers: NSDictionary) -> NSNumber {
        let retryAfterDate = headers.retryDate()
        let retryAfterSeconds = headers.retrySeconds()
        let defaultRetryAfter: Double = 7200
        let maxRetryAfter: Double = 86400

        if let retryAfterDate {
            let now = Date()
            let retryAfter = min(retryAfterDate.timeIntervalSince1970 - now.timeIntervalSince1970, maxRetryAfter)
            return NSNumber(value: retryAfter > 0 ? retryAfter : defaultRetryAfter)
        }

        if let retryAfterSeconds {
            return NSNumber(value: min(retryAfterSeconds.doubleValue, maxRetryAfter))
        }

        return NSNumber(value: defaultRetryAfter)
    }
}
