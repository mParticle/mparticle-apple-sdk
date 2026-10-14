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
