import Foundation

/// Live dependencies the error reporter needs beyond the shared backend session bag.
///
/// `crashMaxPLReportLength` is read through a closure rather than off
/// `MPBackendSessionDependencies.stateMachine()` on purpose. `MPStateMachine_PRIVATE` is a Swift
/// class, so Swift reads its properties directly instead of through `objc_msgSend`, and the
/// Objective-C tests that partial-mock the state machine would not be seen. Resolving the value on
/// the Objective-C side keeps the original dispatch.
@objc(MPBackendErrorDependencies)
public final class MPBackendErrorDependencies: NSObject {
    let maxBytesPerEvent: (String?) -> Int
    let crashMaxPLReportLength: () -> NSNumber?
    var appImageInfo: () -> [AnyHashable: Any] = { MPApplication_PRIVATE.appImageInfo() }

    @objc public init(
        maxBytesPerEvent: @escaping (String?) -> Int,
        crashMaxPLReportLength: @escaping () -> NSNumber?
    ) {
        self.maxBytesPerEvent = maxBytesPerEvent
        self.crashMaxPLReportLength = crashMaxPLReportLength
        super.init()
    }
}

/// Assembles and persists the handled-error and crash-report messages.
///
/// Both workflows return the message the caller echoes back to its completion handler; the
/// `MPExecStatus` that travels with it is declared in Objective-C, so the boundary keeps it.
@objc(MPBackendErrorReporter)
public final class MPBackendErrorReporter: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let writer: MPBackendMessageWriter
    private let errors: MPBackendErrorDependencies

    @objc public init(
        state: MPBackendSessionState,
        dependencies: MPBackendSessionDependencies,
        writer: MPBackendMessageWriter,
        errors: MPBackendErrorDependencies
    ) {
        self.state = state
        self.dependencies = dependencies
        self.writer = writer
        self.errors = errors
        super.init()
    }

    /// Records a handled error, from either a message or an exception, against the current session.
    ///
    /// `topmostContext` arrives already reduced to its class description: it is an untyped
    /// Objective-C object at the boundary, so the `.m` resolves the class before calling in.
    /// Returns the text the caller reports — the exception's name when there is one.
    @objc(logErrorWithMessage:exception:topmostContextDescription:eventInfo:)
    public func logError(
        message: String?,
        exception: NSException?,
        topmostContextDescription: String?,
        eventInfo: [AnyHashable: Any]?
    ) -> String? {
        var messageInfo: [AnyHashable: Any] = [
            kMPCrashWasHandled: "true",
            kMPCrashingSeverity: "error"
        ]

        if let exception {
            messageInfo[kMPErrorMessage] = exception.reason
            messageInfo[kMPCrashingClass] = exception.name.rawValue
            // `callStackSymbols` is declared nonnull but really is nil on an exception that was
            // never raised, and Swift imports it non-optional — so read it through KVC and keep
            // the original's behaviour of leaving the key out entirely.
            if let callStack = exception.value(forKey: "callStackSymbols") as? [String] {
                messageInfo[kMPStackTrace] = callStack.joined(separator: "\n")
            }
            if let breadcrumbs = breadcrumbDictionaries() {
                messageInfo[MessageKeys.kMPMessageTypeLeaveBreadcrumbs] = breadcrumbs
            }
        } else {
            messageInfo[kMPErrorMessage] = message
        }

        if let topmostContextDescription {
            messageInfo[kMPTopmostContext] = topmostContextDescription
        }
        if let eventInfo, !eventInfo.isEmpty {
            messageInfo[MessageKeys.kMPAttributesKey] = eventInfo
        }
        messageInfo.merge(errors.appImageInfo()) { _, new in new }

        let builder = MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.crashReport.rawValue,
            session: state.session,
            messageInfo: messageInfo,
            context: dependencies.makeMessageContext()
        )
        writer.saveMessage(builder?.build(), updateSession: true)

        return exception?.name.rawValue ?? message
    }

    /// Records a fatal crash report against the session the crash most likely belongs to.
    ///
    /// The report is base64-encoded, then truncated if the assembled message exceeds the
    /// per-event byte budget, and saved directly rather than through the message writer — a crash
    /// message must not update the current session or trigger an upload.
    /// Returns the text the caller reports.
    @objc(logCrashWithMessage:stackTrace:plCrashReport:)
    public func logCrash(
        message: String?,
        stackTrace: String?,
        plCrashReport: String?
    ) -> String? {
        var messageInfo: [AnyHashable: Any] = [
            kMPCrashingSeverity: "fatal",
            kMPCrashWasHandled: "false"
        ]
        if let message {
            messageInfo[kMPErrorMessage] = message
        }

        let base64Report = MPBackendMessageInfo.base64CrashReport(
            plCrashReport, maxBytes: errors.crashMaxPLReportLength()
        )
        if let base64Report {
            messageInfo[kMPPLCrashReport] = base64Report
        }
        if let breadcrumbs = breadcrumbDictionaries() {
            messageInfo[MessageKeys.kMPMessageTypeLeaveBreadcrumbs] = breadcrumbs
        }
        if let stackTrace {
            messageInfo[kMPStackTrace] = stackTrace
        }

        let builder = MPMessageBuilderPRIVATE(
            messageType: MPMessageTypeSwift.crashReport.rawValue,
            session: crashSession(),
            messageInfo: messageInfo,
            context: dependencies.makeMessageContext()
        )
        guard let crashMessage = builder?.build() else { return message ?? "Crash Report" }

        let bytesToRetain = MPBackendMessageInfo.crashReportBytesToRetain(
            messageLength: crashMessage.messageData?.count ?? 0,
            maxBytes: errors.maxBytesPerEvent(crashMessage.messageType),
            base64ReportLength: base64Report?.count ?? 0
        )
        if let bytesToRetain {
            crashMessage.truncateMessageDataProperty(kMPPLCrashReport, toLength: bytesToRetain.intValue)
        }
        dependencies.persistence()?.objectiveCSaveMessage(crashMessage)

        return message ?? "Crash Report"
    }

    /// The first recoverable session that is not the one running now, or `nil` when there is none.
    private func crashSession() -> MPSessionPRIVATE? {
        let sessions = dependencies.persistence()?.objectiveCFetchPossibleSessionsFromCrash()
        guard let sessions = sessions as? [MPSessionPRIVATE] else { return nil }
        return sessions.first { !$0.isEqual(state.session) }
    }

    /// `nil` when the store has no breadcrumb array at all, matching the original's nil check —
    /// an empty array still writes an empty list into the message.
    private func breadcrumbDictionaries() -> [NSDictionary]? {
        let fetched = dependencies.persistence()?.objectiveCFetchBreadcrumbs()
        guard let fetched = fetched as? [MPBreadcrumbPRIVATE] else { return nil }
        return fetched.compactMap { $0.dictionaryRepresentation() }
    }
}

// Wire keys mirrored from MPIConstants.m across the internal module boundary. The original wrote
// breadcrumbs under kMPMessageTypeStringBreadcrumb for a handled error and
// kMPMessageTypeLeaveBreadcrumbs for a crash; both are "bc", so MessageKeys covers each.
private let kMPCrashingSeverity = "s"
private let kMPCrashingClass = "c"
private let kMPCrashWasHandled = "eh"
private let kMPErrorMessage = "m"
private let kMPStackTrace = "st"
private let kMPTopmostContext = "tc"
private let kMPPLCrashReport = "plc"
