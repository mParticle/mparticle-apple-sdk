import Foundation
@testable import mParticle_Apple_SDK_Swift

/// A backend host that answers from settable values and records each request, so a test can
/// assert which value a workflow asked for and with which user ID.
final class MPBackendFakeHost: NSObject, MPBackendHost {
    let defaults: MPUserDefaults
    let machine: MPStateMachinePRIVATE
    var planId: String?
    var planVersion: NSNumber?
    var log: MPLog? = MPLog(logLevel: .none)
    var lifetimeValues: [NSNumber: NSNumber] = [:]
    var applicationInfoValue: NSDictionary = ["app": "info"]
    var deviceInfoValue: NSDictionary = ["device": "info"]
    var advertiserIDs: [NSNumber: String] = [:]
    var consents: [NSNumber: NSDictionary] = [:]
    var batchTransform: (NSDictionary) -> Any? = { $0 }
    var version = "0.0.0-test"
    var currentUserId: NSNumber = 1
    var tracksSessionsAutomatically = true
    var queue = DispatchQueue(label: "com.mparticle.tests.fake-host")
    var maxAge: NSNumber?
    var isOptedOut = false
    var crashReportLimit: NSNumber?
    var nullValue = "null"
    var delaysForKits = false
    var delaysForWebView = false
    var uploadSettings = NSObject()
    var limits = MPUploadBatchLimits(
        maxMessages: 100, maxBatchBytes: 102_400, maxMessageBytes: 102_400,
        crashBatchBytes: 102_400, crashMessageBytes: 102_400
    )
    var isDevelopment = false
    var keyLengthLimit = 256
    var valueLengthLimit = 4096
    var attributionTokenValue: String?
    private(set) var calls: [String] = []
    private(set) var sessionStartBackends: [AnyObject?] = []
    private(set) var applicationInfoMachines: [MPStateMachinePRIVATE] = []

    /// `defaults` replaces the simulator's real user defaults, for a test that must not share them.
    init(defaults: MPUserDefaults? = nil) {
        let connector = MPUserDefaultsConnectorMock()
        let defaults = defaults ?? MPUserDefaults(connector: connector)
        self.defaults = defaults
        machine = MPStateMachinePRIVATE(
            userDefaults: defaults, connector: connector, messageQueue: .main,
            sdkVersion: "0.0.0", deploymentTarget: 0, buildSDK: 0
        )
        super.init()
    }

    deinit { defaults.resetDefaults() }

    func dataPlanId() -> String? {
        calls.append("dataPlanId")
        return planId
    }

    func dataPlanVersion() -> NSNumber? {
        calls.append("dataPlanVersion")
        return planVersion
    }

    func sdkLogger() -> MPLog? {
        calls.append("sdkLogger")
        return log
    }

    func stateMachine() -> MPStateMachinePRIVATE {
        calls.append("stateMachine")
        return machine
    }

    func lifetimeValue(forMpid mpid: NSNumber) -> NSNumber {
        calls.append("lifetimeValue:\(mpid)")
        return lifetimeValues[mpid] ?? 0
    }

    func applicationInfo(stateMachine: MPStateMachinePRIVATE) -> NSDictionary {
        calls.append("applicationInfo")
        applicationInfoMachines.append(stateMachine)
        return applicationInfoValue
    }

    func deviceInfo(forMpid mpid: NSNumber) -> NSDictionary {
        calls.append("deviceInfo:\(mpid)")
        return deviceInfoValue
    }

    func advertiserID(forMpid mpid: NSNumber) -> String? {
        calls.append("advertiserID:\(mpid)")
        return advertiserIDs[mpid]
    }

    func consent(forMpid mpid: NSNumber) -> NSDictionary? {
        calls.append("consent:\(mpid)")
        return consents[mpid]
    }

    func transformBatch(_ batch: NSDictionary) -> Any? {
        calls.append("transformBatch")
        return batchTransform(batch)
    }

    func sdkVersion() -> String {
        calls.append("sdkVersion")
        return version
    }

    func mpId() -> NSNumber {
        calls.append("mpId")
        return currentUserId
    }

    func automaticSessionTracking() -> Bool {
        calls.append("automaticSessionTracking")
        return tracksSessionsAutomatically
    }

    func sessionStartContext(forBackend backend: AnyObject?) -> MPBackendSessionStartContext {
        calls.append("sessionStartContext")
        sessionStartBackends.append(backend)
        let machine = machine
        return MPBackendSessionStartContext(
            automaticSessionTracking: { [unowned self] in tracksSessionsAutomatically },
            stateMachine: { machine },
            isCurrentBackend: { backend != nil }
        )
    }

    func messageQueue() -> DispatchQueue {
        queue
    }

    func executeOnMessage(_ block: @escaping () -> Void) {
        queue.async(execute: block)
    }

    func executeOnMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    func persistenceMaxAge() -> NSNumber? {
        calls.append("persistenceMaxAge")
        return maxAge
    }

    func clearExpiredIdentityCache() {
        calls.append("clearExpiredIdentityCache")
    }

    func userDefaults() -> MPUserDefaults {
        defaults
    }

    func optOut() -> Bool {
        calls.append("optOut")
        return isOptedOut
    }

    func crashMaxPLReportLength() -> NSNumber? {
        calls.append("crashMaxPLReportLength")
        return crashReportLimit
    }

    func nullUserAttributeValue() -> String {
        nullValue
    }

    func shouldDelayUploadForKits() -> Bool {
        delaysForKits
    }

    func shouldDelayUploadForWebView() -> Bool {
        delaysForWebView
    }

    func currentUploadSettings() -> NSObject {
        uploadSettings
    }

    func uploadBatchLimits() -> MPUploadBatchLimits {
        limits
    }

    func isDevelopmentEnvironment() -> Bool {
        isDevelopment
    }

    func attributeKeyLengthLimit() -> Int {
        calls.append("attributeKeyLengthLimit")
        return keyLengthLimit
    }

    func attributeValueLengthLimit() -> Int {
        calls.append("attributeValueLengthLimit")
        return valueLengthLimit
    }

    func attributionToken() -> String? {
        calls.append("attributionToken")
        return attributionTokenValue
    }
}

/// User defaults kept in memory. The simulator's real user defaults are shared by every test
/// process on it, and other suites reset them while tests run, so a test that asserts on what it
/// stored uses this instead.
final class MPBackendMemoryUserDefaults: MPUserDefaults {
    private var values: [String: Any] = [:]

    init() {
        super.init(connector: MPUserDefaultsConnectorMock())
    }

    override func mpObject(forKey key: String, userId: NSNumber) -> Any? {
        values["\(userId):\(key)"]
    }

    override func setMPObject(_ value: Any?, forKey key: String, userId: NSNumber) {
        values["\(userId):\(key)"] = value
    }

    override func removeMPObject(forKey key: String, userId: NSNumber) {
        values["\(userId):\(key)"] = nil
    }

    override func synchronize() {}

    override func resetDefaults() {
        values.removeAll()
    }
}
