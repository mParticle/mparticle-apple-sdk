//
//  MPLogger.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 9/22/24.
//

import Foundation

public struct MPLog {
    
    private static func MPLogger(loggerLevel: MPILogLevel, format: String, arguments: any CVarArg...) {
        if (MParticle.sharedInstance().logLevel.rawValue >= loggerLevel.rawValue && loggerLevel != .none) {
            let msg = String.localizedStringWithFormat("mParticle -> \(format)", arguments)
            if let customLogger = MParticle.sharedInstance().customLogger {
                customLogger(msg)
            } else {
                NSLog(msg)
            }
        }
    }
    
    public static func error(_ format: String, _ arguments: any CVarArg...) {
        MPLogger(loggerLevel: .error, format: format, arguments: arguments)
    }
    
    public static func warning(_ format: String, _ arguments: any CVarArg...) {
        MPLogger(loggerLevel: .warning, format: format, arguments: arguments)
    }
    
    public static func debug(_ format: String, _ arguments: any CVarArg...) {
        MPLogger(loggerLevel: .debug, format: format, arguments: arguments)
    }
    
    public static func verbose(_ format: String, _ arguments: any CVarArg...) {
        MPLogger(loggerLevel: .verbose, format: format, arguments: arguments)
    }
}
