import Foundation
import UIKit

/// What the backend's collaborators call back on the controller that owns them. Each call goes
/// through the Objective-C runtime, so an Objective-C test's partial mock of the controller sees it.
@objc(MPBackendAssemblyOwner)
public protocol MPBackendAssemblyOwner: NSObjectProtocol {
    @objc(persistence) func persistence() -> MPBackendPersistence?
    @objc(messageBuilderContext) func messageBuilderContext() -> MPMessageBuilderContext
    @objc(uploadBuilderContext) func uploadBuilderContext() -> MPUploadBuilderContext
    /// Waits for kits, then uploads.
    @objc(uploadFromBackendWithCompletionHandler:) func upload(completionHandler: (() -> Void)?)
    @objc(requestConfigFromBackend) func requestConfig()
    @objc(uploadNetworking) func uploadNetworking() -> MPBackendUploadNetworking?
    @objc(createPendingSessionWithUUID:) func createPendingSession(uuid: String)
    @objc(setPendingSessionStartTime:) func setPendingSessionStartTime(_ timestamp: Double)
    @objc(clearPendingSession) func clearPendingSession()
    @objc(backendDelegate) func backendDelegate() -> MPBackendControllerDelegate?
    @objc(setPersistence:) func setPersistence(_ persistence: MPBackendPersistence?)
    /// Batches the stored messages under `settings`, through the controller, which takes them as
    /// they were stored, including none.
    @objc(prepareBatchesForUploadSettings:) func prepareBatches(forUploadSettings settings: NSObject?)
    @objc(clearEmptyTimedEvents) func clearEmptyTimedEvents()
    /// The session attribution requests use; a test substitutes one that never reaches the network.
    @objc(attributionURLSession) func attributionURLSession() -> URLSession
}

/// Builds the backend controller's collaborators once, with the controller. Callbacks hold the
/// controller weakly and reach the SDK instance through the host.
@objc(MPBackendAssembly)
public final class MPBackendAssembly: NSObject {
    @objc public let sessionDependencies: MPBackendSessionDependencies
    @objc public let messageWriter: MPBackendMessageWriter
    @objc public let userAttributeWriter: MPBackendUserAttributeWriter
    @objc public let identityWriter: MPBackendIdentityWriter
    @objc public let sessionAttributeWriter: MPBackendSessionAttributeWriter
    @objc public let searchAdsAttribution: MPSearchAdsAttribution
    @objc public let startupCoordinator: MPBackendStartupCoordinator
    @objc public let errorReporter: MPBackendErrorReporter
    @objc public let sessionLifecycleDependencies: MPBackendSessionLifecycleDependencies
    @objc public let sessionCoordinator: MPBackendSessionCoordinator
    @objc public let lifecycleCoordinator: MPBackendLifecycleCoordinator
    @objc public let uploadCoordinator: MPBackendUploadCoordinator

    @objc public init(state: MPBackendSessionState, host: MPBackendHost, owner: MPBackendAssemblyOwner) {
        let dependencies = MPBackendSessionDependencies(
            persistence: { [weak owner] in owner?.persistence() },
            stateMachine: { host.stateMachine() },
            makeMessageContext: { [weak owner] in
                owner?.messageBuilderContext() ?? MPMessageBuilderContext(dataPlanId: nil, dataPlanVersion: nil, logger: nil)
            },
            runningInBackground: { MPStateMachinePRIVATE.runningInBackground() },
            // Queued work takes a strong reference when it is queued, so the controller lives until the
            // work runs, and skips the work if the controller was already gone.
            enqueueOnMessage: { [weak owner] block in
                let backend = owner
                host.messageQueue().async { if backend != nil { block() } }
            },
            upload: { [weak owner] completion in owner?.upload(completionHandler: completion) },
            logger: { host.sdkLogger() }
        )
        let writer = MPBackendMessageWriter(state: state, dependencies: dependencies)
        let attributes = MPBackendUserAttributeDependencies(
            userDefaults: { host.userDefaults() },
            currentUserId: { host.mpId() },
            optOut: { host.optOut() },
            nullSentinel: host.nullUserAttributeValue(),
            validateAndLogAttribute: { MPBackendAttributeValidation.validate(key: $0, value: $1, host: host) }
        )
        let attributeWriter = MPBackendUserAttributeWriter(
            state: state, dependencies: dependencies, writer: writer, attributes: attributes
        )
        let identities = MPBackendIdentityWriter(state: state, dependencies: dependencies, writer: writer, host: host)
        let errors = MPBackendErrorDependencies(
            maxBytesPerEvent: { MPPersistenceSchemaPRIVATE.maxBytesPerEvent(for: $0) },
            crashMaxPLReportLength: { host.crashMaxPLReportLength() }
        )
        let sessionLifecycle = MPBackendSessionLifecycleDependencies(
            automaticSessionTracking: { host.automaticSessionTracking() },
            sessionStartContext: { [weak owner] in host.sessionStartContext(forBackend: owner) },
            currentUserID: { host.mpId() },
            applicationInfo: { host.applicationInfo(stateMachine: host.stateMachine()) },
            deviceInfo: { host.deviceInfo(forMpid: $0) },
            executeOnMessage: { [weak owner] block in
                let backend = owner
                host.executeOnMessage { if backend != nil { block() } }
            },
            schedule: { [weak owner] delay, block in
                let backend = owner
                host.messageQueue().asyncAfter(deadline: .now() + delay) { if backend != nil { block() } }
            },
            createPendingSession: { [weak owner] in owner?.createPendingSession(uuid: $0) },
            setPendingSessionStartTime: { [weak owner] in owner?.setPendingSessionStartTime($0) },
            clearPendingSession: { [weak owner] in owner?.clearPendingSession() },
            // The delegate is read on the main thread, and the controller is held until then.
            broadcastBegin: { [weak owner] session in
                let backend = owner
                host.executeOnMain { backend?.backendDelegate()?.sessionDidBegin(session) }
            },
            broadcastEnd: { [weak owner] session in
                let backend = owner
                host.executeOnMain { backend?.backendDelegate()?.sessionDidEnd(session) }
            },
            clearEmptyTimedEvents: { [weak owner] in owner?.clearEmptyTimedEvents() }
        )
        let sessions = MPBackendSessionCoordinator(
            state: state, dependencies: dependencies, lifecycle: sessionLifecycle, writer: writer
        )
        let lifecycle = MPBackendLifecycleCoordinator(
            state: state,
            dependencies: dependencies,
            sessionDependencies: sessionLifecycle,
            lifecycle: MPBackendLifecycleDependencies(
                persistenceMaxAge: { host.persistenceMaxAge() },
                setRunningInBackground: { MPStateMachinePRIVATE.setRunningInBackground($0) },
                clearIdentityCache: { host.clearExpiredIdentityCache() },
                requestConfig: { [weak owner] in owner?.requestConfig() }
            ),
            sessions: sessions,
            writer: writer,
            scheduling: MPBackendAssembly.scheduling(host: host)
        )
        let uploads = MPBackendUploadCoordinator(
            persistence: { [weak owner] in owner?.persistence() },
            stateMachine: { host.stateMachine() },
            makeContext: { [weak owner] in owner?.uploadBuilderContext() },
            makeBuilder: { [weak owner] group, messages, settings, context in
                guard owner != nil else { return nil }
                let builder = MPUploadBuilderPRIVATE(
                    mpid: group.mpid, sessionId: group.sessionId, messages: messages,
                    sessionTimeout: lifecycle.sessionTimeout, uploadInterval: lifecycle.uploadInterval,
                    dataPlanId: group.dataPlanId, dataPlanVersion: group.dataPlanVersion,
                    uploadSettings: settings, context: context
                )
                let userAttributes = attributeWriter.userAttributes(forUserId: group.mpid) as? [String: Any] ?? [:]
                _ = builder?.withUserAttributes(userAttributes, deletedUserAttributes: attributeWriter.deletedUserAttributes)
                _ = builder?.withUserIdentities(identities.userIdentities(forUserId: group.mpid) as? [NSDictionary] ?? [])
                return builder
            },
            clearDeletedAttributes: { attributeWriter.clearDeletedUserAttributes() },
            limits: host.uploadBatchLimits(),
            dependencies: MPBackendUploadDependencies(
                network: { [weak owner] in owner?.uploadNetworking() },
                shouldDelayForKits: { host.shouldDelayUploadForKits() },
                shouldDelayForWebView: { host.shouldDelayUploadForWebView() },
                schedule: { delay, block in host.messageQueue().asyncAfter(deadline: .now() + delay, execute: block) },
                logger: { host.sdkLogger() }
            ),
            currentSettings: { host.currentUploadSettings() }
        )

        sessionDependencies = dependencies
        messageWriter = writer
        userAttributeWriter = attributeWriter
        identityWriter = identities
        sessionAttributeWriter = MPBackendSessionAttributeWriter(dependencies: dependencies, host: host)
        let attribution = MPSearchAdsAttribution(host: host, owner: owner)
        searchAdsAttribution = attribution
        startupCoordinator = MPBackendStartupCoordinator(
            host: host, owner: owner, state: state, dependencies: dependencies, writer: writer,
            sessions: sessions, lifecycle: lifecycle, attribution: attribution
        )
        errorReporter = MPBackendErrorReporter(state: state, dependencies: dependencies, writer: writer, errors: errors)
        sessionLifecycleDependencies = sessionLifecycle
        sessionCoordinator = sessions
        lifecycleCoordinator = lifecycle
        uploadCoordinator = uploads
        super.init()
    }

    /// UIApplication access for background-task handling. A missing application (an app extension,
    /// or before launch) answers 0, the invalid task identifier, as Objective-C messaging nil did.
    private static func scheduling(host: MPBackendHost) -> MPBackendLifecycleSchedulingDependencies {
        MPBackendLifecycleSchedulingDependencies(
            messageQueue: { host.messageQueue() },
            executeOnMain: { host.executeOnMain($0) },
            executeOnMainSync: { DispatchQueue.main.sync(execute: $0) },
            makeApplication: {
                let application = MPApplication_PRIVATE.sharedUIApplication()
                return MPBackendBackgroundApplication(
                    applicationState: { MPApplication_PRIVATE.sharedUIApplication()?.applicationState.rawValue ?? 0 },
                    timeRemaining: { application?.backgroundTimeRemaining ?? 0 }
                )
            },
            beginBackgroundTask: { expiration in
                let identifier = MPApplication_PRIVATE.sharedUIApplication()?.beginBackgroundTask(expirationHandler: expiration)
                return UInt(bitPattern: identifier?.rawValue ?? UIBackgroundTaskIdentifier.invalid.rawValue)
            },
            endBackgroundTask: { identifier in
                MPApplication_PRIVATE.sharedUIApplication()?
                    .endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: Int(bitPattern: identifier)))
            },
            isAppExtension: { MPStateMachinePRIVATE.isAppExtension() },
            isDevelopment: { host.isDevelopmentEnvironment() },
            invalidBackgroundTask: UInt(bitPattern: UIBackgroundTaskIdentifier.invalid.rawValue)
        )
    }
}
