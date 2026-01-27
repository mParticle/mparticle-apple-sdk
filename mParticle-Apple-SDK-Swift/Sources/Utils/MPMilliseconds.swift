import Foundation

public func MPMilliseconds(timestamp: Double) -> Double {
    return trunc(timestamp * 1000.0)
}
