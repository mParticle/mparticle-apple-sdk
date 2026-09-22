import Foundation
import UIKit

/// Internal boundary used by scene-delegate handling to forward URLs and user activities.
///
/// The Objective-C selectors are fixed because `MPAppNotificationHandler` implements this
/// contract in the Objective-C core.
@objc(OpenURLHandlerProtocol)
public protocol OpenURLHandlerProtocolPRIVATE: NSObjectProtocol {
    @objc(openURL:options:)
    func open(_ url: URL, options: [String: Any]?)

    @objc(continueUserActivity:restorationHandler:)
    func `continue`(
        _ userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool
}

/// Shared value mapping and log-message assembly for `SceneDelegateHandlerPRIVATE`.
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
    public static func urlContextLogLines(
        url: String?,
        sourceApplication: String?,
        annotation: String?,
        eventAttribution: String?,
        openInPlace: Bool
    ) -> [String] {
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
    public static func userActivityLogLines(
        activityType: String?,
        title: String?,
        userInfoDescription: String?,
        webpageURL: String?
    ) -> [String] {
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

/// Handles scene-delegate callbacks while preserving the historical Objective-C runtime name.
///
/// `MParticle` supplies its shared logger so later log-level and custom-logger changes continue
/// to affect these messages.
@objc(SceneDelegateHandler)
public final class SceneDelegateHandlerPRIVATE: NSObject {
    private let appNotificationHandler: OpenURLHandlerProtocolPRIVATE

    @objc public var logger: MPLog?

    @objc(initWithAppNotificationHandler:)
    public init(appNotificationHandler: OpenURLHandlerProtocolPRIVATE) {
        self.appNotificationHandler = appNotificationHandler
        super.init()
    }

    #if os(iOS)
        @available(iOS 13.0, *)
        @objc(handleURLContext:)
        public func handleURLContext(_ urlContext: UIOpenURLContext) {
            var eventAttribution: String?
            if #available(iOS 14.5, *) {
                eventAttribution = urlContext.options.eventAttribution
                    .map { String(describing: $0) } ?? "(null)"
            }

            log(
                SceneDelegateLogic.urlContextLogLines(
                    url: String(describing: urlContext.url),
                    sourceApplication: urlContext.options.sourceApplication,
                    annotation: urlContext.options.annotation.map { String(describing: $0) },
                    eventAttribution: eventAttribution,
                    openInPlace: urlContext.options.openInPlace
                )
            )

            let options = SceneDelegateLogic.openURLOptions(
                sourceApplication: urlContext.options.sourceApplication
            )
            appNotificationHandler.open(urlContext.url, options: options)
        }
    #endif

    @objc(handleUserActivity:)
    public func handleUserActivity(_ userActivity: NSUserActivity) {
        log(
            SceneDelegateLogic.userActivityLogLines(
                activityType: userActivity.activityType,
                title: userActivity.title,
                userInfoDescription: (userActivity.userInfo as NSDictionary?)?.description
                    ?? NSDictionary().description,
                webpageURL: userActivity.webpageURL?.absoluteString
            )
        )

        _ = appNotificationHandler.continue(userActivity) { _ in }
    }

    private func log(_ lines: [String]) {
        for line in lines {
            logger?.debug(line)
        }
    }
}
