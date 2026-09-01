import Foundation

/// Log Levels
@objc
public enum MPILogLevelSwift: UInt {
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
    public var logLevel: MPILogLevelSwift
    public var customLogger: ((String) -> Void)?

    public init(logLevel: MPILogLevelSwift) {
        self.logLevel = logLevel
    }

    public static func from(rawValue: UInt) -> MPILogLevelSwift {
        return MPILogLevelSwift(rawValue: rawValue) ?? .none
    }

    private func log(loggerLevel: MPILogLevelSwift, message: String) {
        if logLevel.rawValue >= loggerLevel.rawValue && loggerLevel != .none {
            let msg = "mParticle -> \(message)"
            if let customLogger = customLogger {
                customLogger(msg)
            } else {
                NSLog("%@", msg)
            }
        }
    }

    public func error(_ message: String) {
        log(loggerLevel: .error, message: message)
    }

    public func warning(_ message: String) {
        log(loggerLevel: .warning, message: message)
    }

    public func debug(_ message: String) {
        log(loggerLevel: .debug, message: message)
    }

    public func verbose(_ message: String) {
        log(loggerLevel: .verbose, message: message)
    }
}
