import Foundation

/// Side-effect seam for logging a completed message-upload batch to kits.
/// The concrete conformer forwards to `MParticle.sharedInstance.logKitBatch:`.
@objc public protocol MPKitBatchLogging: AnyObject {
    @objc func logKitBatch(_ uploadString: String)
}

/// The result of handling a message-upload response. `willRetry` is what the
/// caller returns to stop/continue the upload loop; `shouldThrottle` +
/// `throttleRetryAfter` are the state-machine throttle for the caller to apply;
/// `isSuccess` drives the caller's response-body config parse (kept in ObjC as it
/// touches persistence).
@objc public final class MPUploadResponseOutcome: NSObject {
    @objc public let isSuccess: Bool
    @objc public let willRetry: Bool
    @objc public let shouldThrottle: Bool
    @objc public let throttleRetryAfter: TimeInterval

    init(isSuccess: Bool, willRetry: Bool, shouldThrottle: Bool, throttleRetryAfter: TimeInterval) {
        self.isSuccess = isSuccess
        self.willRetry = willRetry
        self.shouldThrottle = shouldThrottle
        self.throttleRetryAfter = throttleRetryAfter
        super.init()
    }
}

@objc public final class MPUploadResponseHandler: NSObject {
    /// Applies the message-upload response effects that belong in Swift —
    /// success/invalid classification, transport-error-counter reset, upload
    /// deletion (via the persistence seam), and kit-batch logging — then returns
    /// the throttle/retry decision for the ObjC caller to apply.
    @objc(handleMessageResponseWithStatusCode:transportError:headers:uploadString:upload:persistence:kitBatchLogger:)
    public static func handleMessageResponse(statusCode: Int,
                                             transportError: NSError?,
                                             headers: NSDictionary,
                                             uploadString: String?,
                                             upload: MPUploadPRIVATE,
                                             persistence: MPUploadPersisting,
                                             kitBatchLogger: MPKitBatchLogging) -> MPUploadResponseOutcome {
        let isSuccess = (200..<300).contains(statusCode)
        let isInvalid = statusCode != 429 && (400..<500).contains(statusCode)

        if isSuccess {
            MPTransportErrorDetector.resetTransportErrorCounter()
        }
        if isSuccess || isInvalid {
            persistence.deleteUpload(upload)
            if isSuccess, let uploadString, !uploadString.isEmpty {
                kitBatchLogger.logKitBatch(uploadString)
            }
        }

        // 429 / 503 → throttle from the Retry-After headers.
        if statusCode == 503 || statusCode == 429 {
            let retryAfter = MPNetworkCommunicationHelper.calculateRetryTime(for: headers).doubleValue
            return MPUploadResponseOutcome(isSuccess: isSuccess, willRetry: true,
                                           shouldThrottle: true, throttleRetryAfter: retryAfter)
        }

        // 5xx / 0 / -1 / transport errors → throttle only when retriable.
        if !isSuccess, !isInvalid {
            if MPTransportErrorDetector.isRetriableTransportError(transportError) {
                let retryAfter = MPTransportErrorDetector.calculateRetryTimeForTransportError().doubleValue
                return MPUploadResponseOutcome(isSuccess: isSuccess, willRetry: true,
                                               shouldThrottle: true, throttleRetryAfter: retryAfter)
            }
            return MPUploadResponseOutcome(isSuccess: isSuccess, willRetry: true,
                                           shouldThrottle: false, throttleRetryAfter: 0)
        }

        return MPUploadResponseOutcome(isSuccess: isSuccess, willRetry: false,
                                       shouldThrottle: false, throttleRetryAfter: 0)
    }
}
