import Foundation

@objc public extension NSDictionary {
    @objc(mp_retryDate)
    func mp_retryDate() -> Date? {
        guard let headerValue = self["Retry-After"] as? String else {
            return nil
        }

        return MPDateFormatter.date(fromStringRFC1123: headerValue)
    }

    @objc(mp_retrySeconds)
    func mp_retrySeconds() -> NSNumber? {
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
