import Foundation

@objc
public protocol OpenURLHandlerProtocol {
    func open(_ url: URL, options: [String: Any]?)
    func continueUserActivity(
        _ userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool
}

@objcMembers
public class SceneDelegateHandler: NSObject {
    private let logger: MPLog
    private let appNotificationHandler: OpenURLHandlerProtocol
    
    public init(logger: MPLog, appNotificationHandler: OpenURLHandlerProtocol) {
        self.logger = logger
        self.appNotificationHandler = appNotificationHandler
    }
    
    #if os(iOS)
    @available(iOS 13.0, *)
    @available(iOSApplicationExtension 13.0, *)
    public func handle(urlContext: UIOpenURLContext) {
        logger.debug("Opening URLContext URL: \(urlContext.url)")
        logger.debug("Source: \(String(describing: urlContext.options.sourceApplication ?? "unknown"))")
        logger.debug("Annotation: \(String(describing: urlContext.options.annotation))")
        if #available(iOS 14.5, *) {
            logger.debug("Event Attribution: \(String(describing: urlContext.options.eventAttribution))")
        }
        logger.debug("Open in place: \(urlContext.options.openInPlace ? "True" : "False")")

        let options = ["UIApplicationOpenURLOptionsSourceApplicationKey": urlContext.options.sourceApplication];
        
        self.appNotificationHandler.open(urlContext.url, options: options as [String: Any])
    }
    #endif
    
    public func handleUserActivity(_ userActivity: NSUserActivity) {
        logger.debug("User Activity Received")
        logger.debug("User Activity Type: \(userActivity.activityType)")
        logger.debug("User Activity Title: \(userActivity.title ?? "")")
        logger.debug("User Activity User Info: \(userActivity.userInfo ?? [:])")

        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            logger.debug("Opening UserActivity URL: \(userActivity.webpageURL?.absoluteString ?? "")")
        }

        _ = appNotificationHandler.continueUserActivity(
            userActivity,
            restorationHandler: { _ in }
        )
    }
}
