import Foundation

/// Assembles the two `MPMessageTypeCrashReport` payloads: the fatal report captured by a crash
/// handler and the handled error or exception reported through the public logging API.
///
/// Pure, like `MPBackendMessageInfo` alongside it — the caller reads persistence and writes the
/// result. That split matters here because the two paths deliberately save differently: a crash is
/// written straight to the store, while an error goes through the backend controller's save path
/// so the opt-out gate and the upload trigger still apply.
@objc(MPCrashMessageFactory)
public final class MPCrashMessageFactory: NSObject {
    /// Builds the fatal crash report, choosing the session the crash belongs to and truncating the
    /// embedded PL crash report so the assembled message fits the per-event byte limit.
    ///
    /// `possibleCrashSessions` is the recoverable session list; the crash is attributed to the
    /// first entry that is not `currentSession`, and to no session at all when there is none.
    ///
    /// The selector is left to the compiler: spelled out, it exceeds the line-length limit.
    @objc
    public static func crashMessage(
        message: String?,
        stackTrace: String?,
        plCrashReport: String?,
        maxPLReportLength: NSNumber?,
        breadcrumbs: [MPBreadcrumbPRIVATE]?,
        possibleCrashSessions: [MPSessionPRIVATE]?,
        currentSession: MPSessionPRIVATE?,
        context: MPMessageBuilderContext
    ) -> MPMessagePRIVATE? {
        var messageInfo: [AnyHashable: Any] = [
            MessageKeys.kMPCrashingSeverity: "fatal",
            MessageKeys.kMPCrashWasHandled: "false"
        ]

        if let message {
            messageInfo[MessageKeys.kMPErrorMessage] = message
        }

        let base64Report = MPBackendMessageInfo.base64CrashReport(plCrashReport, maxBytes: maxPLReportLength)
        if let base64Report {
            messageInfo[MessageKeys.kMPPLCrashReport] = base64Report
        }

        if let breadcrumbs {
            messageInfo[MessageKeys.kMPMessageTypeLeaveBreadcrumbs] = dictionaries(from: breadcrumbs)
        }

        if let stackTrace {
            messageInfo[MessageKeys.kMPStackTrace] = stackTrace
        }

        let crashSession = possibleCrashSessions?.first { !$0.isEqual(currentSession) }

        guard let builder = MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.crashReport.rawValue,
            session: crashSession,
            messageInfo: messageInfo,
            context: context
        ) else {
            return nil
        }

        let crashMessage = builder.build()

        // Measured against the assembled message, so this has to run after the build rather than
        // against the report on its own.
        let bytesToRetain = MPBackendMessageInfo.crashReportBytesToRetain(
            messageLength: crashMessage.messageData?.count ?? 0,
            maxBytes: MPPersistenceSchemaPRIVATE.maxBytesPerEvent(for: crashMessage.messageType),
            base64ReportLength: base64Report?.count ?? 0
        )
        if let bytesToRetain {
            crashMessage.truncateMessageDataProperty(MessageKeys.kMPPLCrashReport, toLength: bytesToRetain.intValue)
        }

        return crashMessage
    }

    /// Builds the handled error report. An exception supplies the message, class and stack trace
    /// and brings the breadcrumb trail with it; a bare string supplies only the message.
    ///
    /// `topmostContextClassName` is the caller's `[[topmostContext class] description]` — the class
    /// name, not the instance description.
    @objc(errorMessageWithMessage:exception:topmostContextClassName:eventInfo:breadcrumbs:currentSession:context:)
    public static func errorMessage(
        message: String?,
        exception: NSException?,
        topmostContextClassName: String?,
        eventInfo: [AnyHashable: Any]?,
        breadcrumbs: [MPBreadcrumbPRIVATE]?,
        currentSession: MPSessionPRIVATE?,
        context: MPMessageBuilderContext
    ) -> MPMessagePRIVATE? {
        var messageInfo: [AnyHashable: Any] = [
            MessageKeys.kMPCrashWasHandled: "true",
            MessageKeys.kMPCrashingSeverity: "error"
        ]

        if let exception {
            messageInfo[MessageKeys.kMPErrorMessage] = exception.reason
            messageInfo[MessageKeys.kMPCrashingClass] = exception.name.rawValue
            messageInfo[MessageKeys.kMPStackTrace] = exception.callStackSymbols.joined(separator: "\n")

            // Breadcrumbs ride along with an exception only; a bare message never carries them.
            if let breadcrumbs {
                messageInfo[MessageKeys.kMPMessageTypeLeaveBreadcrumbs] = dictionaries(from: breadcrumbs)
            }
        } else {
            messageInfo[MessageKeys.kMPErrorMessage] = message
        }

        if let topmostContextClassName {
            messageInfo[MessageKeys.kMPTopmostContext] = topmostContextClassName
        }

        if let eventInfo, !eventInfo.isEmpty {
            messageInfo[MessageKeys.kMPAttributesKey] = eventInfo
        }

        messageInfo.merge(MPApplication_PRIVATE.appImageInfo()) { _, new in new }

        return MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.crashReport.rawValue,
            session: currentSession,
            messageInfo: messageInfo,
            context: context
        )?.build()
    }

    /// An empty trail is distinct from a missing one: it still writes the key, as an empty array.
    private static func dictionaries(from breadcrumbs: [MPBreadcrumbPRIVATE]) -> [Any] {
        breadcrumbs.compactMap { $0.dictionaryRepresentation() }
    }
}
