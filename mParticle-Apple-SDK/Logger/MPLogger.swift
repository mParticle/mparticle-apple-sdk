//
//  MPLogger.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 9/22/24.
//

import Foundation

public struct MPLogger {
    
    public static func MPLogger(loggerLevel: MPILogLevel, format: String, arguments: any CVarArg...) {
        if (MParticle.sharedInstance().logLevel.rawValue >= loggerLevel.rawValue && loggerLevel != .none) {
            let msg = String.localizedStringWithFormat(format, arguments)
// Custom Logger is marked as nonnull despite the fact that we expect it to be null if not set by the client
//         if let customLogger = MParticle.sharedInstance().customLogger {
//             customLogger(msg)
//         } else
            NSLog("%@", msg)
        }
    }
    
    public static func MPLogError(format: String, arguments: any CVarArg...) {
        MPLogger(loggerLevel: .error, format: format, arguments: arguments)
    }
    
    public static func MPLogWarning(format: String, arguments: any CVarArg...) {
        MPLogger(loggerLevel: .warning, format: format, arguments: arguments)
    }
    
    public static func MPLogDebug(format: String, arguments: any CVarArg...) {
        MPLogger(loggerLevel: .debug, format: format, arguments: arguments)
    }
    
    public static func MPLogVerbose(format: String, arguments: any CVarArg...) {
        MPLogger(loggerLevel: .verbose, format: format, arguments: arguments)
    }
}
