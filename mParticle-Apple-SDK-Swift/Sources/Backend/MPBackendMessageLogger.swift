import Foundation

/// Writes the opt-out, network-performance, push-registration and push-notification messages, and
/// requests the current user's audiences.
///
/// Messages are saved through the controller, so an Objective-C test's partial mock of it sees
/// them. Work queued on the message queue keeps the controller until it runs.
@objc(MPBackendMessageLogger)
public final class MPBackendMessageLogger: NSObject {
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let host: MPBackendHost
    private weak var owner: MPBackendAssemblyOwner?

    init(
        state: MPBackendSessionState,
        dependencies: MPBackendSessionDependencies,
        host: MPBackendHost,
        owner: MPBackendAssemblyOwner
    ) {
        self.state = state
        self.dependencies = dependencies
        self.host = host
        self.owner = owner
        super.init()
    }

    /// Stores the opt-out choice and saves the opt-out message on the message queue, then reports
    /// the choice to `completionHandler` there.
    @objc(setOptOut:completionHandler:)
    public func setOptOut(_ optOut: Bool, completionHandler: @escaping (Bool, MPExecStatus) -> Void) {
        let backend = owner
        host.messageQueue().async { [self] in
            host.stateMachine().optOut = optOut
            save(.optOut, [Miscellaneous.kMPOptOutStatus: optOut ? "true" : "false"], through: backend, updateSession: true)
            completionHandler(optOut, .success)
        }
    }

    /// Saves the network-performance message for `networkPerformance`.
    @objc(logNetworkPerformanceMeasurement:completionHandler:)
    public func logNetworkPerformance(
        _ networkPerformance: MPNetworkPerformance,
        completionHandler: ((MPNetworkPerformance, MPExecStatus) -> Void)?
    ) {
        save(
            .networkPerformance,
            networkPerformance.dictionaryRepresentation() as? [AnyHashable: Any] ?? [:],
            through: owner,
            updateSession: true
        )
        completionHandler?(networkPerformance, .success)
    }

    /// Saves the push-registration message for a device-token change on the message queue. A
    /// change whose new and old tokens are both absent, or equal, saves nothing.
    @objc(handleDeviceTokenNotification:)
    public func handleDeviceTokenNotification(_ notification: Notification) {
        let backend = owner
        host.messageQueue().async { [self] in
            let deviceToken = notification.userInfo?[Notifications.kMPRemoteNotificationDeviceTokenKey.rawValue] as? Data
            let oldDeviceToken = notification.userInfo?[Notifications.kMPRemoteNotificationOldDeviceTokenKey.rawValue] as? Data
            guard let decision = MPBackendMessageInfo.pushRegistration(deviceToken: deviceToken, oldDeviceToken: oldDeviceToken)
                else {
                return
            }

            var messageInfo: [AnyHashable: Any] = [PushMessageKey.status: decision.status]
            if let token = decision.logToken.flatMap(MPUserDefaults.stringFromDeviceToken) {
                messageInfo[PushMessageKey.deviceToken] = token
            }
            if let tokenType = host.stateMachine().deviceTokenType, !tokenType.isEmpty {
                messageInfo[Miscellaneous.kMPDeviceTokenTypeKey] = tokenType
            }
            save(.pushRegistration, messageInfo, through: backend, updateSession: true)

            if let deviceToken {
                host.sdkLogger()?.debug("Set Device Token: \(describe(MPUserDefaults.stringFromDeviceToken(deviceToken)))")
            } else {
                host.sdkLogger()?
                    .debug("Reset Device Token: \(describe(oldDeviceToken.flatMap(MPUserDefaults.stringFromDeviceToken)))")
            }
        }
    }

    /// Saves the push-notification message for `userNotification` on the message queue, with the
    /// device token the SDK has stored.
    @objc(logUserNotification:)
    public func logUserNotification(_ userNotification: MParticleUserNotificationPRIVATE) {
        let backend = owner
        host.executeOnMessage { [self] in
            var messageInfo: [AnyHashable: Any] = [
                PushMessageKey.notificationState: userNotification.state,
                PushMessageKey.provider: PushMessageKey.providerValue,
                PushMessageKey.messageType: userNotification.type
            ]
            let storedToken = DeviceTokenStore.shared.adopt(
                persistedToken: host.userDefaults()[PushMessageKey.deviceToken] as? Data
            )
            if let token = storedToken.flatMap(MPUserDefaults.stringFromDeviceToken) {
                messageInfo[PushMessageKey.deviceToken] = token
            }
            if let payload = userNotification.redactedUserNotificationString {
                messageInfo[PushMessageKey.payload] = payload
            }
            if let actionTitle = userNotification.actionTitle {
                messageInfo[PushMessageKey.actionTitle] = actionTitle
            }
            if let actionIdentifier = userNotification.actionIdentifier {
                messageInfo[PushMessageKey.actionIdentifier] = actionIdentifier
            }
            if userNotification.behavior > 0 {
                messageInfo[PushMessageKey.behavior] = NSNumber(value: userNotification.behavior)
            }
            save(.pushNotification, messageInfo, through: backend, updateSession: state.session != nil)
        }
    }

    /// Requests the current user's audiences, logs how the request went, and hands the audience IDs
    /// and error to `completionHandler` as the network layer reported them.
    @objc(fetchAudiencesWithCompletionHandler:)
    public func fetchAudiences(completionHandler: @escaping ([Any]?, Error?) -> Void) {
        owner?.uploadNetworking()?.requestAudiences { [host] success, audiences, error in
            let logger = host.sdkLogger()
            if success {
                logger?.verbose("Audiences Request Succesful: \nCurrent Audiences: \(describe(audiences.map { $0 as NSArray }))")
            } else if let error {
                logger?.error("Audience request failed with error: \(error)")
            } else {
                logger?.error("Audience request failed without error")
            }
            completionHandler(audiences, error)
        }
    }

    // MARK: - Helpers

    private func save(
        _ type: MPMessageTypeSwift,
        _ messageInfo: [AnyHashable: Any],
        through backend: MPBackendAssemblyOwner?,
        updateSession: Bool
    ) {
        let builder = MPMessageBuilderPRIVATE(
            messageType: type.rawValue,
            session: state.session,
            messageInfo: messageInfo,
            context: dependencies.makeMessageContext()
        )
        guard let message = builder?.build() else { return }
        backend?.saveMessage(message, updateSession: updateSession)
    }
}

/// The keys of the push-registration and push-notification messages.
private enum PushMessageKey {
    static let deviceToken = "to"
    static let status = "r"
    static let messageType = "t"
    static let provider = "n"
    static let providerValue = "apn"
    static let payload = "pay"
    static let notificationState = "as"
    static let actionIdentifier = "aid"
    static let behavior = "bhv"
    static let actionTitle = "an"
}

/// How `%@` prints a value: its description, or "(null)" for none.
private func describe(_ value: Any?) -> String {
    guard let value else { return "(null)" }
    return String(describing: value)
}
