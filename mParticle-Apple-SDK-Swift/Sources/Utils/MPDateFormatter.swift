import Foundation

@objc public class MPDateFormatter: NSObject {
    // MARK: - Serial queue for thread-safe access to DateFormatter instances

    // DateFormatter is NOT thread-safe, so we use a serial queue to synchronize access
    private static let formatterQueue = DispatchQueue(label: "com.mparticle.dateformatter")

    private static var dateFormatterRFC3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private static var dateFormatterRFC1123: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss z"
        return formatter
    }()

    private static var dateFormatterRFC850: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = dateFormatterRFC1123.locale
        formatter.timeZone = dateFormatterRFC1123.timeZone
        formatter.dateFormat = "EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z"
        return formatter
    }()

    @objc(dateFromString:) public static func date(from dateString: String) -> Date? {
        guard !dateString.isEmpty else {
            return nil
        }

        return formatterQueue.sync {
            if let date = dateFormatterRFC3339.date(from: dateString) {
                return date
            }

            if let date = dateFormatterRFC1123.date(from: dateString) {
                return date
            }

            return dateFormatterRFC850.date(from: dateString)
        }
    }

    @objc public static func date(fromStringRFC1123 dateString: String) -> Date? {
        guard !dateString.isEmpty else {
            return nil
        }

        return formatterQueue.sync {
            dateFormatterRFC1123.date(from: dateString)
        }
    }

    @objc public static func date(fromStringRFC3339 dateString: String) -> Date? {
        guard !dateString.isEmpty else {
            return nil
        }

        return formatterQueue.sync {
            dateFormatterRFC3339.date(from: dateString)
        }
    }

    @objc public static func string(fromDateRFC1123 date: Date) -> String? {
        return formatterQueue.sync {
            dateFormatterRFC1123.string(from: date)
        }
    }

    @objc public static func string(fromDateRFC3339 date: Date) -> String? {
        return formatterQueue.sync {
            dateFormatterRFC3339.string(from: date)
        }
    }
}
