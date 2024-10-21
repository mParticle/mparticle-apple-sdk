//
//  MPLogger.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 9/22/24.
//

import Foundation

private func MPLogger(loggerLevel: MPILogLevel, format: String, arguments: Any...) {
    if MParticle.sharedInstance().logLevel.rawValue >= loggerLevel.rawValue && loggerLevel != .none {
        let msg = String.localizedStringWithFormat(format, arguments)
        if let customLogger = MParticle.sharedInstance().customLogger {
            customLogger(msg)
        } else {
            print(msg)
        }
    }
}

public func MPLogError(_ format: String, _ arguments: Any...) {
    MPLogger(loggerLevel: .error, format: format, arguments: arguments)
}

public func MPLogWarning(_ format: String, _ arguments: Any...) {
    MPLogger(loggerLevel: .warning, format: format, arguments: arguments)
}

public func MPLogDebug(_ format: String, _ arguments: Any...) {
    MPLogger(loggerLevel: .debug, format: format, arguments: arguments)
}

public func MPLogVerbose(_ format: String, _ arguments: Any...) {
    MPLogger(loggerLevel: .verbose, format: format, arguments: arguments)
}
