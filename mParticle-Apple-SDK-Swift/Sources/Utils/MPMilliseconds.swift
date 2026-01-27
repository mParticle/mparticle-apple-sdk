import Foundation

public func MPMilliseconds(timestamp: Double) -> Double {
    return trunc(timestamp * 1000.0)
}

@objc public class MPTimeUtils: NSObject {
    @objc public static func milliseconds(timestamp: Double) -> Double {
        return MPMilliseconds(timestamp: timestamp)
    }
}
