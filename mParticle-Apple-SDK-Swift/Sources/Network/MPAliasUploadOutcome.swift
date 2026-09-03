import Foundation

/// How the upload loop should treat an alias request's HTTP status.
///
/// Objective-C owns the side effects the classification drives — deleting the upload, resetting the
/// transport-error counter, and throttling — because those touch SDK types this module cannot see.
@objc(MPAliasUploadOutcomePRIVATE)
public final class MPAliasUploadOutcomePRIVATE: NSObject {
    /// Whether the status code is in the 2xx range.
    @objc public let isSuccessCode: Bool

    /// Whether the status code is a non-retriable client error (4xx other than 429).
    @objc public let isInvalidCode: Bool

    /// Whether the SDK will re-send the request (429 or 503).
    @objc public let shouldRetry: Bool

    init(isSuccessCode: Bool, isInvalidCode: Bool, shouldRetry: Bool) {
        self.isSuccessCode = isSuccessCode
        self.isInvalidCode = isInvalidCode
        self.shouldRetry = shouldRetry
        super.init()
    }

    /// Classifies the status code and logs the server's failure message when the body carries one.
    @objc(outcomeFromResponseData:statusCode:logger:)
    public static func outcome(responseData: Data?, statusCode: Int, logger: MPLog) -> MPAliasUploadOutcomePRIVATE {
        let isSuccessCode = statusCode >= 200 && statusCode < 300
        let isInvalidCode = statusCode != HTTPStatusCode.tooManyRequests.rawValue
            && statusCode >= 400
            && statusCode < 500
        let shouldRetry = statusCode == HTTPStatusCode.serviceUnavailable.rawValue
            || statusCode == HTTPStatusCode.tooManyRequests.rawValue

        if !isSuccessCode {
            logFailure(responseData: responseData, logger: logger)
        }

        return MPAliasUploadOutcomePRIVATE(
            isSuccessCode: isSuccessCode,
            isInvalidCode: isInvalidCode,
            shouldRetry: shouldRetry
        )
    }

    private static func logFailure(responseData: Data?, logger: MPLog) {
        guard let responseData, !responseData.isEmpty,
              let body = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any]
        else { return }
        let message = body[IdentityHTTPKeys.message]
        let code = body[IdentityHTTPKeys.code]
        logger.error("Alias request failed - \(describe(code)) \(describe(message))")
    }

    /// Reproduces `%@` formatting of a nil value, which Objective-C printed as `(null)`.
    private static func describe(_ value: Any?) -> String {
        guard let value else { return "(null)" }
        return "\(value)"
    }
}
