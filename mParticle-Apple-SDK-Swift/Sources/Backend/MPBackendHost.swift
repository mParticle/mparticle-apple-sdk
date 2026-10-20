import Foundation

/// The SDK instance as the backend sees it: the values and Objective-C services the backend reads
/// from `MParticle.sharedInstance`, the public model types and build-time constants, none of which
/// this module can import.
///
/// The Objective-C module supplies the conformance and reads the SDK instance on every call, so a
/// value is resolved when the backend asks for it, and a test's stubs on those reads apply.
@objc(MPBackendHost)
public protocol MPBackendHost: NSObjectProtocol {
    @objc(dataPlanId) func dataPlanId() -> String?
    @objc(dataPlanVersion) func dataPlanVersion() -> NSNumber?
    /// The SDK's shared logger.
    @objc(sdkLogger) func sdkLogger() -> MPLog?
    @objc(stateMachine) func stateMachine() -> MPStateMachinePRIVATE
    @objc(lifetimeValueForMpid:) func lifetimeValue(forMpid mpid: NSNumber) -> NSNumber
    @objc(applicationInfoWithStateMachine:) func applicationInfo(stateMachine: MPStateMachinePRIVATE) -> NSDictionary
    @objc(deviceInfoForMpid:) func deviceInfo(forMpid mpid: NSNumber) -> NSDictionary
    @objc(advertiserIDForMpid:) func advertiserID(forMpid mpid: NSNumber) -> String?
    /// The user's consent state in its server form, or nil when there is none.
    @objc(consentForMpid:) func consent(forMpid mpid: NSNumber) -> NSDictionary?
    /// Runs the app's batch-creation callback, if it set one; otherwise returns `batch`.
    @objc(transformBatch:) func transformBatch(_ batch: NSDictionary) -> Any?
    @objc(sdkVersion) func sdkVersion() -> String
    @objc(mpId) func mpId() -> NSNumber
    @objc(automaticSessionTracking) func automaticSessionTracking() -> Bool
    /// Pins a session start to the current SDK instance; `isCurrentBackend` is true while that
    /// instance still uses `backend`.
    @objc(sessionStartContextForBackend:) func sessionStartContext(forBackend backend: AnyObject?)
        -> MPBackendSessionStartContext
    @objc(messageQueue) func messageQueue() -> DispatchQueue
    /// Runs `block` now when already on the message queue, otherwise asynchronously on it.
    @objc(executeOnMessage:) func executeOnMessage(_ block: @escaping () -> Void)
    @objc(executeOnMain:) func executeOnMain(_ block: @escaping () -> Void)
    @objc(persistenceMaxAge) func persistenceMaxAge() -> NSNumber?
    @objc(clearExpiredIdentityCache) func clearExpiredIdentityCache()
    @objc(userDefaults) func userDefaults() -> MPUserDefaults
    // These two are read through Objective-C, so a test's stub on the state machine applies.
    @objc(optOut) func optOut() -> Bool
    @objc(crashMaxPLReportLength) func crashMaxPLReportLength() -> NSNumber?
    @objc(nullUserAttributeValue) func nullUserAttributeValue() -> String
    @objc(shouldDelayUploadForKits) func shouldDelayUploadForKits() -> Bool
    @objc(shouldDelayUploadForWebView) func shouldDelayUploadForWebView() -> Bool
    @objc(currentUploadSettings) func currentUploadSettings() -> NSObject
    @objc(uploadBatchLimits) func uploadBatchLimits() -> MPUploadBatchLimits
    @objc(isDevelopmentEnvironment) func isDevelopmentEnvironment() -> Bool
    @objc(attributeKeyLengthLimit) func attributeKeyLengthLimit() -> Int
    @objc(attributeValueLengthLimit) func attributeValueLengthLimit() -> Int
    /// The App Store attribution token for this install, or nil when there is none: on tvOS, or
    /// when the system cannot create one.
    @objc(attributionToken) func attributionToken() -> String?
    @objc(shouldBeginSession) func shouldBeginSession() -> Bool
    @objc(collectSearchAdsAttribution) func collectSearchAdsAttribution() -> Bool
    @objc(initializeKits) func initializeKits()
    /// Opens the SDK's persistence if it is not open yet, and returns it.
    @objc(openPersistence) func openPersistence() -> MPBackendPersistence?
    /// The upload settings stored by the last start, or nil before the first.
    @objc(lastUploadSettings) func lastUploadSettings() -> NSObject?
    @objc(apiKeyOfUploadSettings:) func apiKey(ofUploadSettings settings: NSObject?) -> String?
    /// Stores the upload settings for this start, for the next start's workspace check.
    @objc(storeUploadSettingsWithApiKey:secret:networkOptions:)
    func storeUploadSettings(apiKey: String, secret: String, networkOptions: NSObject?)
    /// Drops the cached server configuration, after a workspace switch.
    @objc(deleteCachedConfiguration) func deleteCachedConfiguration()
    /// Restores the cached server configuration, if one is stored.
    @objc(restoreCachedConfiguration) func restoreCachedConfiguration()
    @objc(updateStoredVersionAndBuildNumbers) func updateStoredVersionAndBuildNumbers()
}

public extension MPMessageBuilderContext {
    @objc convenience init(host: MPBackendHost) {
        self.init(dataPlanId: host.dataPlanId(), dataPlanVersion: host.dataPlanVersion(), logger: host.sdkLogger())
    }
}

public extension MPUploadBuilderContext {
    @objc convenience init(host: MPBackendHost, persistence: @escaping () -> MPUploadEnrichmentPersistence) {
        self.init(
            stateMachine: { host.stateMachine() },
            lifetimeValue: { host.lifetimeValue(forMpid: $0) },
            persistence: persistence,
            applicationInfo: { host.applicationInfo(stateMachine: $0) },
            deviceInfo: { host.deviceInfo(forMpid: $0) },
            advertiserID: { host.advertiserID(forMpid: $0) },
            consent: { host.consent(forMpid: $0) },
            transformBatch: { host.transformBatch($0) },
            logger: { host.sdkLogger() },
            sdkVersion: host.sdkVersion()
        )
    }
}
