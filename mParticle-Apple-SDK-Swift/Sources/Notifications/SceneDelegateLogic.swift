import Foundation

/// The value mapping and log-message assembly behind SceneDelegateHandler.
///
/// The `.m` unwraps `UIOpenURLContext` and `NSUserActivity` into Foundation values,
/// calls in here, and emits the returned strings through `MPILogDebug` so console
/// output is unchanged.
@objc(MPSceneDelegateLogic) public final class SceneDelegateLogic: NSObject {
    /// The key UIKit uses in `application:openURL:options:`. Spelled out rather than
    /// referenced because `UIApplicationOpenURLOptionsSourceApplicationKey` is a UIKit
    /// symbol the ObjC original also hard-coded as a string literal.
    @objc public static let sourceApplicationKey = "UIApplicationOpenURLOptionsSourceApplicationKey"

    /// Builds the options dictionary forwarded to `openURL:options:`. A missing source
    /// application yields an empty dictionary rather than a nil entry, matching the
    /// `NSMutableDictionary` the ObjC version handed over.
    @objc(openURLOptionsWithSourceApplication:)
    public static func openURLOptions(sourceApplication: String?) -> [String: Any] {
        guard let sourceApplication = sourceApplication else {
            return [:]
        }
        return [sourceApplicationKey: sourceApplication]
    }

    @objc(isBrowsingWebActivityWithActivityType:)
    public static func isBrowsingWebActivity(activityType: String?) -> Bool {
        return activityType == NSUserActivityTypeBrowsingWeb
    }

    /// The four lines logged for an inbound URL context, in order. `eventAttribution` is
    /// passed in already resolved because it is gated on iOS 14.5 at the call site.
    @objc(urlContextLogLinesWithURL:sourceApplication:annotation:eventAttribution:openInPlace:)
    public static func urlContextLogLines(url: String?,
                                          sourceApplication: String?,
                                          annotation: String?,
                                          eventAttribution: String?,
                                          openInPlace: Bool) -> [String] {
        var lines = [
            "Opening URLContext URL: \(url ?? "(null)")",
            "Source: \(sourceApplication ?? "unknown")",
            "Annotation: \(annotation ?? "(null)")"
        ]

        if let eventAttribution = eventAttribution {
            lines.append("Event Attribution: \(eventAttribution)")
        }

        lines.append("Open in place: \(openInPlace ? "True" : "False")")
        return lines
    }

    /// The lines logged for an inbound user activity. The browsing-web URL line is only
    /// present for `NSUserActivityTypeBrowsingWeb`, as before.
    @objc(userActivityLogLinesWithActivityType:title:userInfoDescription:webpageURL:)
    public static func userActivityLogLines(activityType: String?,
                                            title: String?,
                                            userInfoDescription: String?,
                                            webpageURL: String?) -> [String] {
        var lines = [
            "User Activity Received",
            "User Activity Type: \(activityType ?? "(null)")",
            "User Activity Title: \(title ?? "")",
            "User Activity User Info: \(userInfoDescription ?? "{\n}")"
        ]

        if isBrowsingWebActivity(activityType: activityType) {
            lines.append("Opening UserActivity URL: \(webpageURL ?? "")")
        }

        return lines
    }
}
