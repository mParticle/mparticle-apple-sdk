import Foundation

/// Log Levels
@objc
public enum MPILogLevel: UInt {
    /** No log messages are displayed on the console  */
    case none = 0
    /** Only error log messages are displayed on the console */
    case error
    /** Warning and error log messages are displayed on the console */
    case warning
    /** Debug, warning, and error log messages are displayed on the console */
    case debug
    /** Verbose, debug, warning, and error log messages are displayed on the console */
    case verbose
}

@objcMembers
public class MPLog: NSObject {
    public var logLevel: MPILogLevel
    public var customLogger: ((String) -> Void)?

    public init(logLevel: MPILogLevel) {
        self.logLevel = logLevel
    }

    private func log(loggerLevel: MPILogLevel, format: String, arguments: any CVarArg...) {
        if logLevel.rawValue >= loggerLevel.rawValue && loggerLevel != .none {
            let msg = String.localizedStringWithFormat("mParticle -> \(format)", arguments)
            if let customLogger = customLogger {
                customLogger(msg)
            } else {
                NSLog(msg)
            }
        }
    }

    public func error(_ message: String) {
        log(loggerLevel: .error, format: message)
    }

    public func warning(_ message: String) {
        log(loggerLevel: .warning, format: message)
    }

    public func debug(_ message: String) {
        log(loggerLevel: .debug, format: message)
    }

    public func verbose(_ message: String) {
        log(loggerLevel: .verbose, format: message)
    }
}
