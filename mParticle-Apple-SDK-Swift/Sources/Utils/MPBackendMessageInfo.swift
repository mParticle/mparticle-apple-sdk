import Foundation

/// The push-registration decision derived from a device-token change: which
/// token to log and the reported enabled status, or `nil` when nothing changed.
@objc public final class MPPushRegistrationDecision: NSObject {
    @objc public let status: String
    @objc public let logToken: Data?

    init(status: String, logToken: Data?) {
        self.status = status
        self.logToken = logToken
        super.init()
    }
}

/// Pure computations for backend crash and push-registration messages. The
/// caller keeps every side effect — persistence, `MPMessageBuilder`, session
/// selection, and logging.
@objc public final class MPBackendMessageInfo: NSObject {
    /// Encodes a PL crash report as base64, truncating the UTF-8 bytes to
    /// `maxBytes` first when a limit is supplied. Returns `nil` for a nil report.
    @objc(base64CrashReport:maxBytes:)
    public static func base64CrashReport(_ plCrashReport: String?, maxBytes: NSNumber?) -> String? {
        guard let plCrashReport else { return nil }
        var data = Data(plCrashReport.utf8)
        if let maxBytes, data.count > maxBytes.intValue {
            data = data.prefix(maxBytes.intValue)
        }
        return data.base64EncodedString()
    }

    /// Decides how a device-token change is reported. Returns `nil` when both
    /// tokens are absent or unchanged. Otherwise a present new token logs as
    /// enabled ("true"); a cleared token logs the old token as disabled ("false").
    @objc(pushRegistrationForDeviceToken:oldDeviceToken:)
    public static func pushRegistration(deviceToken: Data?, oldDeviceToken: Data?) -> MPPushRegistrationDecision? {
        if (deviceToken == nil && oldDeviceToken == nil) || deviceToken == oldDeviceToken {
            return nil
        }

        if deviceToken != nil {
            return MPPushRegistrationDecision(status: "true", logToken: deviceToken)
        }
        return MPPushRegistrationDecision(status: "false", logToken: oldDeviceToken)
    }
}
