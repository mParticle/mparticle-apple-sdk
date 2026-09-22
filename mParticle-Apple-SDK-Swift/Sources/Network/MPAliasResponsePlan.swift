import Foundation

/// Everything derivable from an alias upload's HTTP status, request body, and response body.
///
/// Objective-C owns the side effects — deleting the upload, throttling, and building the public
/// `MPAliasResponse`/`MPAliasRequest` pair — because those touch SDK types this module cannot see.
@objc(MPAliasResponsePlanPRIVATE)
public final class MPAliasResponsePlanPRIVATE: NSObject {
    /// Whether the status code is in the 2xx range.
    @objc public let isSuccessCode: Bool

    /// Whether the status code is a non-retriable client error (4xx other than 429).
    @objc public let isInvalidCode: Bool

    /// Whether the SDK will re-send the request (429 or 503).
    @objc public let shouldRetry: Bool

    /// The GUID the SDK generated for this alias request, echoed back from the uploaded body.
    @objc public let requestID: String?

    /// Source MPID, read back from the uploaded body.
    @objc public let sourceMPID: NSNumber?

    /// Destination MPID, read back from the uploaded body.
    @objc public let destinationMPID: NSNumber?

    /// Alias window start, converted from the uploaded body's millisecond timestamp.
    @objc public let startTime: Date

    /// Alias window end, converted from the uploaded body's millisecond timestamp.
    @objc public let endTime: Date

    /// The server's human-readable failure message, when the response carried one.
    @objc public let errorMessage: String?

    init(
        isSuccessCode: Bool,
        isInvalidCode: Bool,
        shouldRetry: Bool,
        requestID: String?,
        sourceMPID: NSNumber?,
        destinationMPID: NSNumber?,
        startTime: Date,
        endTime: Date,
        errorMessage: String?
    ) {
        self.isSuccessCode = isSuccessCode
        self.isInvalidCode = isInvalidCode
        self.shouldRetry = shouldRetry
        self.requestID = requestID
        self.sourceMPID = sourceMPID
        self.destinationMPID = destinationMPID
        self.startTime = startTime
        self.endTime = endTime
        self.errorMessage = errorMessage
        super.init()
    }

    /// The single definition of an alias success code, shared with `MPAliasResponse.isSuccessful`.
    @objc(isSuccessCode:)
    public static func isSuccessCode(_ statusCode: Int) -> Bool {
        statusCode >= 200 && statusCode < 300
    }

    /// Classifies an alias upload's outcome and recovers the request fields from the uploaded body.
    @objc(planFromRequestData:responseData:statusCode:logger:)
    public static func plan(
        requestData: Data?,
        responseData: Data?,
        statusCode: Int,
        logger: MPLog
    ) -> MPAliasResponsePlanPRIVATE {
        let isSuccessCode = isSuccessCode(statusCode)
        let isInvalidCode = statusCode != HTTPStatusCode.tooManyRequests.rawValue
            && statusCode >= 400
            && statusCode < 500
        let shouldRetry = statusCode == HTTPStatusCode.serviceUnavailable.rawValue
            || statusCode == HTTPStatusCode.tooManyRequests.rawValue

        let request = jsonDictionary(from: requestData)
        // `MPIdentityHTTPRequestBuilderPRIVATE.aliasDictionary` nests the alias window under
        // `data` and leaves `request_id` at the top level. The Objective-C implementation read
        // every field from the top level, so it always recovered a nil source/destination MPID and
        // an epoch window; nothing consumed the result, which is why that went unnoticed.
        let aliasFields = (request?[IdentityHTTPKeys.data] as? [String: Any]) ?? request

        var errorMessage: String?
        if !isSuccessCode, let responseData, !responseData.isEmpty {
            if let response = jsonDictionary(from: responseData) {
                let message = response[IdentityHTTPKeys.message] as? String
                let code = response[IdentityHTTPKeys.code]
                logger.error("Alias request failed - \(describe(code)) \(describe(message))")
                errorMessage = message
            }
        }

        return MPAliasResponsePlanPRIVATE(
            isSuccessCode: isSuccessCode,
            isInvalidCode: isInvalidCode,
            shouldRetry: shouldRetry,
            requestID: request?[IdentityHTTPKeys.requestId] as? String,
            sourceMPID: aliasFields?[IdentityHTTPKeys.sourceMPID] as? NSNumber,
            destinationMPID: aliasFields?[IdentityHTTPKeys.destinationMPID] as? NSNumber,
            startTime: date(fromMilliseconds: aliasFields?[IdentityHTTPKeys.startUnixTime]),
            endTime: date(fromMilliseconds: aliasFields?[IdentityHTTPKeys.endUnixTime]),
            errorMessage: errorMessage
        )
    }

    private static func jsonDictionary(from data: Data?) -> [String: Any]? {
        guard let data, !data.isEmpty else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    /// Matches the Objective-C conversion, which read a missing timestamp as 0 rather than nil.
    private static func date(fromMilliseconds milliseconds: Any?) -> Date {
        let value = (milliseconds as? NSNumber)?.doubleValue ?? 0
        return Date(timeIntervalSince1970: value/1000)
    }

    /// Reproduces `%@` formatting of a nil value, which Objective-C printed as `(null)`.
    private static func describe(_ value: Any?) -> String {
        guard let value else { return "(null)" }
        return "\(value)"
    }
}
