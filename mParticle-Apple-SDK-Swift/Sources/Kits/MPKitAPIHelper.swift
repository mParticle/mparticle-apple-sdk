import Foundation

struct MPKitAttributionFailure {
    let message: String
    let includesUnderlyingError: Bool
}

@objc(MPKitAPIHelper)
public final class MPKitAPIHelper: NSObject {
    private static let attributionErrorMessage = "mParticle Kit Attribution Error"
    private static let missingResultMessage =
        "mParticle Kit Attribution handler was called with nil info and no error"

    // Mirrors mParticle-Apple-SDK/MPEnums.m:25,38,39. The Swift module cannot
    // import the ObjC module to read the real constants, so
    // MPKitAPITests asserts these against the ObjC ones.
    private static let errorDomain = "com.mparticle.kitapi"
    private static let errorMessageKey = "mParticle Kit API Error"
    private static let kitInstanceKey = "mParticleKitInstanceKey"

    /// Returns nil when the completion represents a success.
    static func attributionFailure(
        for error: NSError?,
        hasResult: Bool
    ) -> MPKitAttributionFailure? {
        guard error != nil || !hasResult else {
            return nil
        }

        // The ObjC assigned errorMessage twice, so a call carrying both an error
        // and no result reports the missing-result message while still
        // attaching the underlying error.
        let message = hasResult ? attributionErrorMessage : missingResultMessage
        return MPKitAttributionFailure(message: message, includesUnderlyingError: error != nil)
    }

    /// The NSError a failed kit attribution reports, or nil on success.
    @objc(attributionErrorForError:hasResult:kitCode:)
    public static func attributionError(
        for error: NSError?,
        hasResult: Bool,
        kitCode: NSNumber?
    ) -> NSError? {
        guard let failure = attributionFailure(for: error, hasResult: hasResult) else {
            return nil
        }

        var userInfo: [String: Any] = [:]
        if let kitCode {
            userInfo[kitInstanceKey] = kitCode
        }
        if failure.includesUnderlyingError, let error {
            userInfo[NSUnderlyingErrorKey] = error
        }
        userInfo[errorMessageKey] = failure.message

        return NSError(domain: errorDomain, code: 0, userInfo: userInfo)
    }

    /// Matches `[NSString stringWithFormat:@"%@ Kit: %@", kitName, message]`,
    /// including the "(null)" an unregistered kit code produces.
    static func logMessage(kitName: String?, message: String) -> String {
        "\(kitName ?? "(null)") Kit: \(message)"
    }

    /// The `MPILogger` macro (mParticle-Apple-SDK/Logger/MPILogger.h:6-14) for
    /// kit-originated messages.
    ///
    /// `currentLogLevel` stays a raw `UInt` deliberately: `MPLog.from(rawValue:)`
    /// clamps an unrecognised value to `.none`, which would silence a level the
    /// macro logs. The prefixed message is also built before the gate, because
    /// the ObjC wrapper rendered it at every level.
    @objc(emitKitLogWithKitName:message:messageLevel:currentLogLevel:customLogger:)
    public static func emitKitLog(
        kitName: String?,
        message: String,
        messageLevel: MPILogLevelSwift,
        currentLogLevel: UInt,
        customLogger: ((String) -> Void)?
    ) {
        let prefixed = logMessage(kitName: kitName, message: message)

        guard currentLogLevel >= messageLevel.rawValue,
              currentLogLevel != MPILogLevelSwift.none.rawValue
        else {
            return
        }

        let output = "mParticle -> \(prefixed)"
        if let customLogger {
            customLogger(output)
        } else {
            NSLog("%@", output)
        }
    }

    /// The per-call `MPLog`/`MPIHasher` assembly the ObjC wrapper used to do
    /// inline, now that both types are Swift. A fresh instance per call keeps
    /// this free of shared mutable state — kits call it from arbitrary threads,
    /// and inside loops.
    @objc(hashString:logLevel:customLogger:)
    public static func hashString(
        _ string: String,
        logLevel: UInt,
        customLogger: ((String) -> Void)?
    ) -> String {
        let logger = MPLog(logLevel: MPLog.from(rawValue: logLevel))
        logger.customLogger = customLogger

        return MPIHasher(logger: logger).hashString(string)
    }
}
