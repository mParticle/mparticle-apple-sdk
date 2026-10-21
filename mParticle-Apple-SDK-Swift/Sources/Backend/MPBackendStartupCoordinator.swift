import Foundation
import UIKit

/// Starts the backend for an API key and records the app's launch: kit start-up, the first session,
/// the switch-of-workspace check, the first-run and launch messages, and Search Ads attribution.
@objc(MPBackendStartupCoordinator)
public final class MPBackendStartupCoordinator: NSObject {
    /// How long start-up waits for Search Ads attribution before it carries on without it; shortened
    /// by tests.
    var attributionTimeout: TimeInterval = 30

    private let host: MPBackendHost
    private weak var owner: MPBackendAssemblyOwner?
    private let state: MPBackendSessionState
    private let dependencies: MPBackendSessionDependencies
    private let writer: MPBackendMessageWriter
    private let sessions: MPBackendSessionCoordinator
    private let lifecycle: MPBackendLifecycleCoordinator
    private let attribution: MPSearchAdsAttribution
    private let launchLock = NSLock()
    private var storedLaunchNotification: Notification?

    init(
        host: MPBackendHost,
        owner: MPBackendAssemblyOwner,
        state: MPBackendSessionState,
        dependencies: MPBackendSessionDependencies,
        writer: MPBackendMessageWriter,
        sessions: MPBackendSessionCoordinator,
        lifecycle: MPBackendLifecycleCoordinator,
        attribution: MPSearchAdsAttribution
    ) {
        self.host = host
        self.owner = owner
        self.state = state
        self.dependencies = dependencies
        self.writer = writer
        self.sessions = sessions
        self.lifecycle = lifecycle
        self.attribution = attribution
        super.init()
    }

    /// The app's did-finish-launching notification, kept until start-up records the launch.
    @objc public var didFinishLaunchingNotification: Notification? {
        get { launchLock.lock(); defer { launchLock.unlock() }; return storedLaunchNotification }
        set { launchLock.lock(); storedLaunchNotification = newValue; launchLock.unlock() }
    }

    /// Starts the backend. `networkOptions` passes through to the stored upload settings untouched.
    /// The deferred work runs on the message queue and does nothing once the controller is gone, so
    /// a controller a reset or workspace switch replaced does not start up against its successor.
    @objc(startWithKey:secret:networkOptions:firstRun:installationType:startKitsAsync:completionHandler:)
    public func start(
        apiKey: String,
        secret: String,
        networkOptions: NSObject?,
        firstRun: Bool,
        installationType: MPInstallationTypeSwift,
        startKitsAsync: Bool,
        completionHandler: @escaping () -> Void
    ) {
        let logger = host.sdkLogger()
        logger?.debug(
            "Backend controller starting - firstRun: \(firstRun ? "YES" : "NO"), startKitsAsync: \(startKitsAsync ? "YES" : "NO")"
        )

        let host = self.host
        if !host.optOut() {
            logger?.debug("Dispatching kit initialization to message queue")
            host.messageQueue().async { host.initializeKits() }
        } else {
            logger?.warning("Skipping kit initialization - SDK is opted out")
        }

        let stateMachine = host.stateMachine()
        stateMachine.apiKey = apiKey
        stateMachine.secret = secret
        stateMachine.installationType = installationType.rawValue
        MPStateMachinePRIVATE.setRunningInBackground(false)

        let shouldBeginSession = !host.optOut() && host.shouldBeginSession()
        var date: Date?
        if shouldBeginSession {
            sessions.createTempSession()
            date = Date()
        }

        host.messageQueue().async { [weak self] in
            guard let self, let owner = self.owner else { return }
            owner.setPersistence(host.openPersistence())

            // A different API key than last time means a workspace switch: batch what is stored
            // under the old settings before starting, and drop the cached configuration. No stored
            // settings counts as different, and the batching is then asked for with nil settings.
            let lastUploadSettings = host.lastUploadSettings()
            if host.apiKey(ofUploadSettings: lastUploadSettings) != apiKey {
                owner.prepareBatches?(forUploadSettings: lastUploadSettings)
                host.deleteCachedConfiguration()
            }
            host.storeUploadSettings(apiKey: apiKey, secret: secret, networkOptions: networkOptions)
            host.restoreCachedConfiguration()

            if shouldBeginSession {
                sessions.beginSession(isManual: !host.automaticSessionTracking(), date: date)
            }

            let firstRunBuilder = MPMessageBuilderPRIVATE(
                messageType: MPMessageTypeSwift.firstRun.rawValue, session: state.session,
                messageInfo: nil, context: dependencies.makeMessageContext()
            )
            sessions.processOpenSessions(endingCurrent: false) {}
            lifecycle.beginUploadTimer()

            if firstRun {
                // The builder already marks a message for batching.
                writer.saveMessage(firstRunBuilder?.build(), updateSession: true)
                logger?.debug("Application First Run")
            }

            // The attribution request and the timeout both hold this block and the timeout is never
            // cancelled, so whichever finishes first wins. Recording the launch twice would forward
            // a second install or update and write a second launch message.
            let afterAttribution = MPSearchAdsAttribution.singleShot { [weak self] in
                guard let self, let owner = self.owner else { return }
                processDidFinishLaunching(didFinishLaunchingNotification)
                logger?.debug("Initiating config request and upload cycle")
                owner.upload(completionHandler: nil)
            }

            if host.collectSearchAdsAttribution() {
                host.messageQueue().asyncAfter(deadline: .now() + attributionTimeout, execute: afterAttribution)
                attribution.requestAttributionDetails(completion: afterAttribution, requestsCompleted: 0)
            } else {
                afterAttribution()
            }

            logger?.debug("SDK \(host.sdkVersion()) has started")
            completionHandler()
        }
    }

    /// Records the launch: forwards an install or update to kits, starts a session for one, and
    /// writes the launch message with the URL the app was opened from, if any.
    @objc(processDidFinishLaunching:)
    public func processDidFinishLaunching(_ notification: Notification?) {
        let stateMachine = host.stateMachine()
        var messageInfo: [AnyHashable: Any] = [:]
        var isInstallOrUpgrade = false
        if stateMachine.installationType == MPInstallationTypeSwift.knownInstall.rawValue {
            messageInfo["ifr"] = true
            owner?.backendDelegate()?.forwardLogInstall()
            isInstallOrUpgrade = true
        } else if stateMachine.installationType == MPInstallationTypeSwift.knownUpgrade.rawValue {
            messageInfo["iu"] = true
            owner?.backendDelegate()?.forwardLogUpdate()
            isInstallOrUpgrade = true
        }

        let activityDictionary = notification?
            .userInfo?[UIApplication.LaunchOptionsKey.userActivityDictionary] as? [AnyHashable: Any]
        if let activity = activityDictionary?["UIApplicationLaunchOptionsUserActivityKey"] as? NSUserActivity,
           let url = activity.webpageURL {
            stateMachine.launchInfo = MPLaunchInfo(URL: url, options: nil, logger: host.sdkLogger() ?? MPLog(logLevel: .none))
        }
        messageInfo[MessageKeys.kMPAppStateTransitionType] = "app_init"

        let host = self.host
        host.messageQueue().async { [self] in
            if isInstallOrUpgrade, host.automaticSessionTracking() {
                sessions.beginSession()
            }
            let builder = MPMessageBuilderPRIVATE(
                messageType: MPMessageTypeSwift.appStateTransition.rawValue, session: state.session,
                messageInfo: messageInfo, context: dependencies.makeMessageContext()
            )
            builder?.stateTransition(true, previousSession: nil, launchInfo: stateMachine.launchInfo)
            writer.saveMessage(builder?.build(), updateSession: true)
        }

        host.updateStoredVersionAndBuildNumbers()
        didFinishLaunchingNotification = nil
        host.sdkLogger()?.verbose("Application Did Finish Launching")
    }
}
