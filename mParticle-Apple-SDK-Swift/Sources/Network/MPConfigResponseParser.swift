import Foundation

/// Pure parsing of the config request's HTTP response headers.
@objc public final class MPConfigResponseParser: NSObject {
    /// Parses the `max-age` seconds from a `Cache-Control` header value, clamped
    /// to `maxExpirationAge`. Returns `nil` when the header is absent or has no
    /// `max-age` directive. Matches the Objective-C `NSString.doubleValue`
    /// leading-number parse.
    @objc(maxAgeFromCacheControl:maxExpirationAge:)
    public static func maxAge(fromCacheControl cacheControl: String?, maxExpirationAge: TimeInterval) -> NSNumber? {
        guard let lower = cacheControl?.lowercased(), lower.contains("max-age=") else {
            return nil
        }
        let afterDirective = lower.components(separatedBy: "max-age=")[1]
        let value = afterDirective.components(separatedBy: ",")[0]
        return NSNumber(value: min((value as NSString).doubleValue, maxExpirationAge))
    }
}
