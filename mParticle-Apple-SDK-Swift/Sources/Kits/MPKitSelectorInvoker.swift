import Foundation

/// Describes the result of forwarding a selector to a kit.
@objc public enum MPKitInvocationOutcome: Int {
    /// The kit returned a value for the selector.
    case returnedStatus
    /// The selector completed and does not return a kit status.
    case completedWithoutStatus
    /// The kit does not implement the selector.
    case notImplemented
    /// The selector is outside the supported dispatch contract.
    case unknownSelector
    /// A required selector argument was unavailable or invalid.
    case missingArguments
}

/// Contains the outcome and optional return value from a forwarded kit call.
@objc(MPKitInvocationResult) public final class MPKitInvocationResult: NSObject {
    /// The result category for the invocation.
    @objc public let outcome: MPKitInvocationOutcome
    /// The object returned by the kit, when the selector returns one.
    @objc public let returnedObject: AnyObject?

    fileprivate init(_ outcome: MPKitInvocationOutcome, returnedObject: AnyObject? = nil) {
        self.outcome = outcome
        self.returnedObject = returnedObject
        super.init()
    }
}

/// Forwards supported selectors through the typed `MPKitDispatchTarget` contract.
@objc(MPKitSelectorInvoker) public final class MPKitSelectorInvoker: NSObject {
    private typealias RestorationBlock = @convention(block) (NSArray?) -> Void
    private typealias RoktEventBlock = @convention(block) (AnyObject) -> Void

    private static let blockClass: AnyClass? = NSClassFromString("NSBlock")

    private let logger: MPLog

    /// Creates an invoker that reports unsupported selectors through the supplied logger.
    @objc public init(logger: MPLog) {
        self.logger = logger
        super.init()
    }

    private func isBlock(_ value: Any?) -> Bool {
        guard let value, let blockClass = Self.blockClass else { return false }
        return (value as AnyObject).isKind(of: blockClass)
    }

    private func restorationHandler(_ value: Any?) -> (([Any]?) -> Void)? {
        guard isBlock(value), let value else { return nil }
        let block = unsafeBitCast(value as AnyObject, to: RestorationBlock.self)
        return { objects in block(objects as NSArray?) }
    }

    private func roktEventHandler(_ value: Any?) -> ((AnyObject) -> Void)? {
        guard isBlock(value), let value else { return nil }
        let block = unsafeBitCast(value as AnyObject, to: RoktEventBlock.self)
        return { event in block(event) }
    }

    /// Invokes a supported selector when the kit implements it and its required arguments exist.
    @objc public func invoke(_ kit: MPKitDispatchTarget?,
                             selectorName: String,
                             event: Any?,
                             filteredUser: AnyObject?,
                             parameters: MPForwardQueueParameters?) -> MPKitInvocationResult {
        guard let kit else { return MPKitInvocationResult(.notImplemented) }

        func argument(_ index: Int) -> Any? { parameters?[index] }
        func returned(_ value: AnyObject?) -> MPKitInvocationResult {
            MPKitInvocationResult(.returnedStatus, returnedObject: value)
        }

        switch selectorName {
        case "logBaseEvent:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.logBaseEvent else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "logEvent:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.logEvent else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "logScreen:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.logScreen else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "leaveBreadcrumb:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.leaveBreadcrumb else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "beginTimedEvent:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.beginTimedEvent else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "endTimedEvent:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.endTimedEvent else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "logCommerceEvent:":
            guard let event else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.logCommerceEvent else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(event))

        case "logLTVIncrease:event:":
            guard let amount = argument(0) as? NSNumber, let event else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.logLTVIncrease else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(amount.doubleValue, event))

        case "beginSession":
            guard let call = kit.beginSession else { return MPKitInvocationResult(.notImplemented) }
            return returned(call())

        case "endSession":
            guard let call = kit.endSession else { return MPKitInvocationResult(.notImplemented) }
            return returned(call())

        case "logError:eventInfo:":
            guard let call = kit.logError else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(argument(0) as? String, argument(1) as? [AnyHashable: Any]))

        case "logException:":
            guard let exception = argument(0) as? NSException else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.logException else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(exception))

        case "setOptOut:":
            guard let call = kit.setOptOut else { return MPKitInvocationResult(.notImplemented) }
            return returned(call((argument(0) as? NSNumber)?.boolValue ?? false))

        case "setATTStatus:withATTStatusTimestampMillis:":
            guard let statusValue = argument(0) as? NSNumber else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.setATTStatus else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(statusValue.uintValue, argument(1) as? NSNumber))

        case "setWrapperSdk:version:":
            guard let wrapperSdk = argument(0) as? NSNumber,
                  let version = argument(1) as? String else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.setWrapperSdk else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(wrapperSdk.uintValue, version))

        case "surveyURLWithUserAttributes:":
            guard let attributes = argument(0) as? [AnyHashable: Any] else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.surveyURL else { return MPKitInvocationResult(.notImplemented) }
            _ = call(attributes)
            return MPKitInvocationResult(.completedWithoutStatus)

        case "shouldDelayMParticleUpload":
            guard let call = kit.shouldDelayMParticleUpload else { return MPKitInvocationResult(.notImplemented) }
            _ = call()
            return MPKitInvocationResult(.completedWithoutStatus)

        case "failedToRegisterForUserNotifications:":
            guard let call = kit.failedToRegisterForUserNotifications else {
                return MPKitInvocationResult(.notImplemented)
            }
            return returned(call(argument(0) as? NSError))

        case "setDeviceToken:":
            guard let token = argument(0) as? Data else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.setDeviceToken else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(token))

        case "receivedUserNotification:":
            guard let userInfo = argument(0) as? [AnyHashable: Any] else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.receivedUserNotification else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(userInfo))

        case "handleActionWithIdentifier:forRemoteNotification:":
            guard let userInfo = argument(1) as? [AnyHashable: Any] else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.handleAction(withIdentifier:forRemoteNotification:) else {
                return MPKitInvocationResult(.notImplemented)
            }
            return returned(call(argument(0) as? String, userInfo))

        case "handleActionWithIdentifier:forRemoteNotification:withResponseInfo:":
            guard let userInfo = argument(1) as? [AnyHashable: Any],
                  let responseInfo = argument(2) as? [AnyHashable: Any] else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.handleAction(withIdentifier:forRemoteNotification:withResponseInfo:) else {
                return MPKitInvocationResult(.notImplemented)
            }
            return returned(call(argument(0) as? String, userInfo, responseInfo))

        case "openURL:options:":
            guard let url = argument(0) as? URL else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.open(_:options:) else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(url, argument(1) as? [AnyHashable: Any]))

        case "openURL:sourceApplication:annotation:":
            guard let url = argument(0) as? URL else { return MPKitInvocationResult(.missingArguments) }
            guard let call = kit.open(_:sourceApplication:annotation:) else {
                return MPKitInvocationResult(.notImplemented)
            }
            return returned(call(url, argument(1) as? String, argument(2)))

        case "didUpdateUserActivity:":
            guard let activity = argument(0) as? NSUserActivity else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.didUpdateUserActivity else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(activity))

        case "continueUserActivity:restorationHandler:":
            guard let activity = argument(0) as? NSUserActivity,
                  let handler = restorationHandler(argument(1)) else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.continueUserActivity else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(activity, handler))

        case "selectPlacementsWithIdentifier:attributes:embeddedViews:config:onEvent:filteredUser:options:":
            let rawHandler = argument(4)
            guard let attributes = argument(1) as? [String: String],
                  let filteredUser,
                  rawHandler == nil || isBlock(rawHandler) else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.selectPlacements else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(argument(0) as? String,
                                 attributes,
                                 argument(2) as? [String: AnyObject],
                                 argument(3) as AnyObject?,
                                 roktEventHandler(rawHandler),
                                 filteredUser,
                                 argument(5) as AnyObject?))

        case "selectShoppableAdsWithIdentifier:attributes:config:onEvent:filteredUser:":
            let rawHandler = argument(3)
            guard let identifier = argument(0) as? String,
                  let attributes = argument(1) as? [String: String],
                  let filteredUser,
                  rawHandler == nil || isBlock(rawHandler) else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.selectShoppableAds else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(identifier,
                                 attributes,
                                 argument(2) as AnyObject?,
                                 roktEventHandler(rawHandler),
                                 filteredUser))

        case "events:onEvent:":
            let rawHandler = argument(1)
            guard let identifier = argument(0) as? String,
                  rawHandler == nil || isBlock(rawHandler) else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.events else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(identifier, roktEventHandler(rawHandler)))

        case "globalEvents:":
            guard let handler = roktEventHandler(argument(0)) else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.globalEvents else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(handler))

        case "registerPaymentExtension:":
            guard let paymentExtension = argument(0) as AnyObject? else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.registerPaymentExtension else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(paymentExtension))

        case "purchaseFinalized:catalogItemId:success:":
            guard let identifier = argument(0) as? String,
                  let catalogItemId = argument(1) as? String,
                  let success = argument(2) as? NSNumber else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.purchaseFinalized else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(identifier, catalogItemId, success))

        case "close":
            guard let call = kit.close else { return MPKitInvocationResult(.notImplemented) }
            return returned(call())

        case "setSessionId:":
            guard let sessionId = argument(0) as? String else {
                return MPKitInvocationResult(.missingArguments)
            }
            guard let call = kit.setSessionId else { return MPKitInvocationResult(.notImplemented) }
            return returned(call(sessionId))

        case "clearSession":
            guard let call = kit.clearSession else { return MPKitInvocationResult(.notImplemented) }
            return returned(call())

        default:
            logger.error("Forwarded selector \(selectorName) is not supported by the typed dispatcher.")
            return MPKitInvocationResult(.unknownSelector)
        }
    }
}
