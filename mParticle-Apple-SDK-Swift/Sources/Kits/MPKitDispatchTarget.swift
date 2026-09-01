import Foundation

/// Mirrors the optional `MPKitProtocol` selectors handled by the kit dispatch boundary.
///
/// The Foundation-only Swift module cannot import `MPKitProtocol` because the Objective-C module
/// depends on this module. Object parameters that use SDK-specific types are represented by
/// `AnyObject` or `Any`; scalar parameters retain their exact Objective-C representation.
@objc public protocol MPKitDispatchTarget {
    @objc(logBaseEvent:) optional func logBaseEvent(_ event: Any) -> AnyObject?
    @objc(logEvent:) optional func logEvent(_ event: Any) -> AnyObject?
    @objc(logScreen:) optional func logScreen(_ event: Any) -> AnyObject?
    @objc(leaveBreadcrumb:) optional func leaveBreadcrumb(_ event: Any) -> AnyObject?
    @objc(beginTimedEvent:) optional func beginTimedEvent(_ event: Any) -> AnyObject?
    @objc(endTimedEvent:) optional func endTimedEvent(_ event: Any) -> AnyObject?
    @objc(logCommerceEvent:) optional func logCommerceEvent(_ commerceEvent: Any) -> AnyObject?
    @objc(logLTVIncrease:event:) optional func logLTVIncrease(_ increaseAmount: Double, event: Any) -> AnyObject?

    @objc(beginSession) optional func beginSession() -> AnyObject?
    @objc(endSession) optional func endSession() -> AnyObject?

    @objc(logError:eventInfo:) optional func logError(_ message: String?, eventInfo: [AnyHashable: Any]?) -> AnyObject?
    @objc(logException:) optional func logException(_ exception: NSException) -> AnyObject?

    @objc(setOptOut:) optional func setOptOut(_ optOut: Bool) -> AnyObject?
    @objc(setATTStatus:withATTStatusTimestampMillis:)
    optional func setATTStatus(_ status: UInt, withATTStatusTimestampMillis timestampMillis: NSNumber?) -> AnyObject?
    @objc(setWrapperSdk:version:) optional func setWrapperSdk(_ wrapperSdk: UInt, version: String) -> AnyObject?
    @objc(surveyURLWithUserAttributes:)
    optional func surveyURL(withUserAttributes userAttributes: [AnyHashable: Any]) -> String?
    @objc(shouldDelayMParticleUpload) optional func shouldDelayMParticleUpload() -> Bool

    @objc(failedToRegisterForUserNotifications:)
    optional func failedToRegisterForUserNotifications(_ error: NSError?) -> AnyObject?
    @objc(setDeviceToken:) optional func setDeviceToken(_ deviceToken: Data) -> AnyObject?
    @objc(receivedUserNotification:)
    optional func receivedUserNotification(_ userInfo: [AnyHashable: Any]) -> AnyObject?
    @objc(handleActionWithIdentifier:forRemoteNotification:)
    optional func handleAction(withIdentifier identifier: String?,
                               forRemoteNotification userInfo: [AnyHashable: Any]) -> AnyObject?
    @objc(handleActionWithIdentifier:forRemoteNotification:withResponseInfo:)
    optional func handleAction(withIdentifier identifier: String?,
                               forRemoteNotification userInfo: [AnyHashable: Any],
                               withResponseInfo responseInfo: [AnyHashable: Any]) -> AnyObject?
    @objc(openURL:options:) optional func open(_ url: URL, options: [AnyHashable: Any]?) -> AnyObject?
    @objc(openURL:sourceApplication:annotation:)
    optional func open(_ url: URL, sourceApplication: String?, annotation: Any?) -> AnyObject?
    @objc(didUpdateUserActivity:) optional func didUpdateUserActivity(_ userActivity: NSUserActivity) -> AnyObject?
    @objc(continueUserActivity:restorationHandler:)
    optional func continueUserActivity(_ userActivity: NSUserActivity,
                                       restorationHandler: @escaping ([Any]?) -> Void) -> AnyObject?

    @objc(selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:)
    optional func selectPlacements(withIdentifier identifier: String?,
                                   attributes: [String: String],
                                   embeddedViews: [String: AnyObject]?,
                                   config: AnyObject?,
                                   onEvent: ((AnyObject) -> Void)?,
                                   filteredUser: AnyObject,
                                   options: AnyObject?) -> AnyObject?
    @objc(selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:)
    optional func selectShoppableAds(withIdentifier identifier: String,
                                     attributes: [String: String],
                                     config: AnyObject?,
                                     onEvent: ((AnyObject) -> Void)?,
                                     filteredUser: AnyObject) -> AnyObject?
    @objc(events:onEvent:) optional func events(_ identifier: String,
                                                onEvent: ((AnyObject) -> Void)?) -> AnyObject?
    @objc(globalEvents:) optional func globalEvents(_ onEvent: @escaping (AnyObject) -> Void) -> AnyObject?
    @objc(registerPaymentExtension:)
    optional func registerPaymentExtension(_ paymentExtension: AnyObject) -> AnyObject?
    @objc(purchaseFinalized:catalogItemId:success:)
    optional func purchaseFinalized(_ identifier: String,
                                    catalogItemId: String,
                                    success: NSNumber) -> AnyObject?

    @objc(close) optional func close() -> AnyObject?
    @objc(setSessionId:) optional func setSessionId(_ sessionId: String) -> AnyObject?
    @objc(clearSession) optional func clearSession() -> AnyObject?
}
