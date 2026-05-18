import Foundation

@objc public extension NSDictionary {
    func retryDate() -> Date? {
        guard let headerValue = self["Retry-After"] as? String else {
            return nil
        }

        return MPDateFormatter.date(fromStringRFC1123: headerValue)
    }

    func retrySeconds() -> NSNumber? {
        let headerValue = self["Retry-After"]

        if let number = headerValue as? NSNumber {
            return NSNumber(value: number.doubleValue)
        }
        if let string = headerValue as? String {
            return Double(string).map { NSNumber(value: $0) }
        }

        return nil
    }
}
