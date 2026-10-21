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
    var beginsSessions = true
    var collectsSearchAdsAttribution = false
    var persistenceValue: MPBackendPersistence?
    var lastUploadSettingsValue: NSObject?
    var networkCommunicationValue: MPBackendUploadNetworking?
    var uploadSettingsApiKeys: [ObjectIdentifier: String] = [:]
    private(set) var storedUploadSettings: [MPBackendStoredUploadSettings] = []
    private let callsLock = NSLock()
    private var recordedCalls: [String] = []
    /// Every request, in order. Start-up asks for some on the message queue while the test thread
    /// asks for others, so the list is guarded.
    var calls: [String] {
        callsLock.lock()
        defer { callsLock.unlock() }
        return recordedCalls
    }

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

    private func record(_ call: String) {
        callsLock.lock()
        recordedCalls.append(call)
        callsLock.unlock()
    }

    func dataPlanId() -> String? {
        record("dataPlanId")
        return planId
    }

    func dataPlanVersion() -> NSNumber? {
        record("dataPlanVersion")
        return planVersion
    }

    func sdkLogger() -> MPLog? {
        record("sdkLogger")
        return log
    }

    func stateMachine() -> MPStateMachinePRIVATE {
        record("stateMachine")
        return machine
    }

    func lifetimeValue(forMpid mpid: NSNumber) -> NSNumber {
        record("lifetimeValue:\(mpid)")
        return lifetimeValues[mpid] ?? 0
    }

    func applicationInfo(stateMachine: MPStateMachinePRIVATE) -> NSDictionary {
        record("applicationInfo")
        applicationInfoMachines.append(stateMachine)
        return applicationInfoValue
    }

    func deviceInfo(forMpid mpid: NSNumber) -> NSDictionary {
        record("deviceInfo:\(mpid)")
        return deviceInfoValue
    }

    func advertiserID(forMpid mpid: NSNumber) -> String? {
        record("advertiserID:\(mpid)")
        return advertiserIDs[mpid]
    }

    func consent(forMpid mpid: NSNumber) -> NSDictionary? {
        record("consent:\(mpid)")
        return consents[mpid]
    }

    func transformBatch(_ batch: NSDictionary) -> Any? {
        record("transformBatch")
        return batchTransform(batch)
    }

    func sdkVersion() -> String {
        record("sdkVersion")
        return version
    }

    func mpId() -> NSNumber {
        record("mpId")
        return currentUserId
    }

    func automaticSessionTracking() -> Bool {
        record("automaticSessionTracking")
        return tracksSessionsAutomatically
    }

    func sessionStartContext(forBackend backend: AnyObject?) -> MPBackendSessionStartContext {
        record("sessionStartContext")
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
        record("persistenceMaxAge")
        return maxAge
    }

    func clearExpiredIdentityCache() {
        record("clearExpiredIdentityCache")
    }

    func userDefaults() -> MPUserDefaults {
        defaults
    }

    func optOut() -> Bool {
        record("optOut")
        return isOptedOut
    }

    func crashMaxPLReportLength() -> NSNumber? {
        record("crashMaxPLReportLength")
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
        record("attributeKeyLengthLimit")
        return keyLengthLimit
    }

    func attributeValueLengthLimit() -> Int {
        record("attributeValueLengthLimit")
        return valueLengthLimit
    }

    func attributionToken() -> String? {
        record("attributionToken")
        return attributionTokenValue
    }

    func shouldBeginSession() -> Bool {
        beginsSessions
    }

    func collectSearchAdsAttribution() -> Bool {
        collectsSearchAdsAttribution
    }

    func initializeKits() {
        record("initializeKits")
    }

    func openPersistence() -> MPBackendPersistence? {
        record("openPersistence")
        return persistenceValue
    }

    func lastUploadSettings() -> NSObject? {
        lastUploadSettingsValue
    }

    func apiKey(ofUploadSettings settings: NSObject?) -> String? {
        settings.flatMap { uploadSettingsApiKeys[ObjectIdentifier($0)] }
    }

    func storeUploadSettings(apiKey: String, secret: String, networkOptions: NSObject?) {
        storedUploadSettings.append(MPBackendStoredUploadSettings(apiKey: apiKey, secret: secret, networkOptions: networkOptions))
    }

    func deleteCachedConfiguration() {
        record("deleteCachedConfiguration")
    }

    func restoreCachedConfiguration() {
        record("restoreCachedConfiguration")
    }

    func updateStoredVersionAndBuildNumbers() {
        record("updateStoredVersionAndBuildNumbers")
    }

    func makeNetworkCommunication() -> MPBackendUploadNetworking? {
        record("makeNetworkCommunication")
        return networkCommunicationValue
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

/// One call to `storeUploadSettings(apiKey:secret:networkOptions:)`.
struct MPBackendStoredUploadSettings {
    let apiKey: String
    let secret: String
    let networkOptions: NSObject?
}
