import Foundation

/// Message and crash limits supplied from the Objective-C constants at composition time.
@objc(MPUploadBatchLimits)
public final class MPUploadBatchLimits: NSObject {
    let maxMessages: Int
    let maxBatchBytes: Int
    let maxMessageBytes: Int
    let crashBatchBytes: Int
    let crashMessageBytes: Int

    @objc public init(
        maxMessages: Int,
        maxBatchBytes: Int,
        maxMessageBytes: Int,
        crashBatchBytes: Int,
        crashMessageBytes: Int
    ) {
        self.maxMessages = maxMessages
        self.maxBatchBytes = maxBatchBytes
        self.maxMessageBytes = maxMessageBytes
        self.crashBatchBytes = crashBatchBytes
        self.crashMessageBytes = crashMessageBytes
        super.init()
    }
}

/// Owns batch preparation on the existing SDK message queue. Callbacks provide the live backend
/// dependencies without importing the Objective-C SDK or retaining the backend itself.
@objc(MPBackendUploadCoordinator)
public final class MPBackendUploadCoordinator: NSObject {
    private let persistence: () -> MPBackendPersistence?
    private let stateMachine: () -> MPStateMachinePRIVATE
    private let makeContext: () -> MPUploadBuilderContext?
    private let makeBuilder: (MPUploadMessageGroup, [MPMessagePRIVATE], NSObject, MPUploadBuilderContext)
        -> MPUploadBuilderPRIVATE?
    private let clearDeletedAttributes: () -> Void
    private let limits: MPUploadBatchLimits
    private let dependencies: MPBackendUploadDependencies
    private let currentSettings: () -> NSObject

    @objc public init(
        persistence: @escaping () -> MPBackendPersistence?,
        stateMachine: @escaping () -> MPStateMachinePRIVATE,
        makeContext: @escaping () -> MPUploadBuilderContext?,
        makeBuilder: @escaping (MPUploadMessageGroup, [MPMessagePRIVATE], NSObject, MPUploadBuilderContext)
        -> MPUploadBuilderPRIVATE?,
        clearDeletedAttributes: @escaping () -> Void,
        limits: MPUploadBatchLimits,
        dependencies: MPBackendUploadDependencies,
        currentSettings: @escaping () -> NSObject
    ) {
        self.persistence = persistence
        self.stateMachine = stateMachine
        self.makeContext = makeContext
        self.makeBuilder = makeBuilder
        self.clearDeletedAttributes = clearDeletedAttributes
        self.limits = limits
        self.dependencies = dependencies
        self.currentSettings = currentSettings
        super.init()
    }

    // Access remains confined to the SDK message queue, as with the original file-static flag.
    private static var shouldSkipNextUpload = false

    @objc public func skipNextUpload() {
        Self.shouldSkipNextUpload = true
    }

    @objc(uploadBatchesWithCompletionHandler:)
    public func uploadBatches(completionHandler: @escaping (Bool) -> Void) {
        prepareBatches(forUpload: currentSettings())
        let persistence = persistence()
        if Self.shouldSkipNextUpload {
            Self.shouldSkipNextUpload = false
            completionHandler(true)
            return
        }
        guard let uploads = persistence?.objectiveCFetchUploads() as? [MPUploadPRIVATE], !uploads.isEmpty else {
            completionHandler(true)
            return
        }
        if stateMachine().dataRamped {
            for upload in uploads {
                persistence?.objectiveCDeleteUpload(upload)
            }
            persistence?.objectiveCDeleteNetworkPerformanceMessages()
            // Preserve the existing ramped-path behavior: no completion callback.
            return
        }
        dependencies.network()?.upload(uploads) { completionHandler(true) }
    }

    @objc(requestConfig:)
    public func requestConfig(_ completionHandler: ((Bool) -> Void)?) {
        dependencies.logger()?.debug("Requesting SDK configuration from server")
        dependencies.network()?.requestConfig(nil) { success in completionHandler?(success) }
    }

    @objc(checkForKitsAndUploadWithCompletionHandler:)
    public func checkForKitsAndUpload(completionHandler: ((Bool) -> Void)?) {
        requestConfig { [self] uploadBatch in
            guard uploadBatch else {
                dependencies.logger()?.debug("Config request returned uploadBatch: NO, skipping upload")
                completionHandler?(false)
                return
            }
            let shouldDelayForKits = dependencies.shouldDelayForKits()
            if shouldDelayForKits || dependencies.shouldDelayForWebView() {
                dependencies.logger()?
                    .warning(
                        "Delaying upload - kits still initializing (shouldDelayForKits: \(shouldDelayForKits ? "YES" : "NO"))"
                    )
                completionHandler?(true)
                return
            }
            uploadBatches { _ in completionHandler?(false) }
        }
    }

    @objc(waitForKitsAndUploadWithCompletionHandler:)
    public func waitForKitsAndUpload(completionHandler: (() -> Void)?) {
        checkForKitsAndUpload { [self] didShortCircuit in
            if didShortCircuit {
                dependencies.logger()?.verbose("Kits not ready, retrying upload check in 1 second")
                dependencies.schedule(1) { [self] in
                    waitForKitsAndUpload(completionHandler: completionHandler)
                }
            } else {
                completionHandler?()
            }
        }
    }

    @objc(prepareBatchesForUpload:)
    public func prepareBatches(forUpload settings: NSObject) {
        guard let persistence = persistence() else { return }
        if let context = makeContext() {
            let messages = persistence.objectiveCFetchMessagesForUploading() as? [AnyHashable: Any]
            for group in MPUploadGrouping.groups(fromStoredMessages: messages) {
                let batches = batchMessages(group.messages, limits: limits)
                var uploads: [MPUploadPRIVATE] = []
                for messages in batches {
                    makeBuilder(group, messages, settings, context)?.build { upload in
                        if let upload { uploads.append(upload) }
                    }
                }
                // Keep the transaction boundary and the original source group, including messages
                // intentionally omitted by size limits or a customer hook.
                let saved = persistence.objectiveCSaveUploads(
                    uploads, deleteMessages: group.messages, optedOut: stateMachine().optOut
                )
                // A rolled-back save leaves the source messages to be retried, so the pending
                // deletions have to survive until the transaction carrying them is durable.
                if saved {
                    clearDeletedAttributes()
                }
            }
        }
        persistence.objectiveCDeleteAllSessions(except: stateMachine().currentSession)
    }

    @objc(batchMessages:limits:)
    public func batchMessages(_ messages: [MPMessagePRIVATE], limits: MPUploadBatchLimits) -> [[MPMessagePRIVATE]] {
        let groups = MPMessageBatcher.batchIndexGroups(
            byteLengths: messages.map { $0.messageData?.count ?? 0 },
            isCrashReport: messages.map { $0.messageType == MessageKeys.kMPMessageTypeStringCrashReport },
            maxBatchMessages: limits.maxMessages, maxBatchBytes: limits.maxBatchBytes,
            maxMessageBytes: limits.maxMessageBytes, crashMaxBatchBytes: limits.crashBatchBytes,
            crashMaxMessageBytes: limits.crashMessageBytes
        )
        return groups.map { indices in indices.map { messages[$0] } }
    }
}
