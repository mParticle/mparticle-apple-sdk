import Darwin
import Foundation
import UIKit

// Keeps the MPStateMachineProtocol Objective-C name the deleted header declared, so
// Include/MPUploadSettings.h's `id<MPStateMachineProtocol>` parameter and mParticle.m's property
// keep compiling unchanged. Reference MPStateMachineProtocolPRIVATE from Swift.
//
// apiKey and secret are non-optional here. The deleted Objective-C wrapper declared them nonnull
// over a Swift optional, so every caller already assumed a value; an empty string is what they
// assumed nil would behave as.
@objc(MPStateMachineProtocol)
public protocol MPStateMachineProtocolPRIVATE: NSObjectProtocol {
    var optOut: Bool { get set }
    var logLevel: UInt { get set }
    var consumerInfo: MPConsumerInfoPRIVATE { get set }
    var automaticSessionTracking: Bool { get set }
    var currentSession: MPSessionPRIVATE? { get set }
    var attAuthorizationStatus: NSNumber? { get set }
    var attAuthorizationTimestamp: NSNumber? { get set }
    var apiKey: String { get set }
    var secret: String { get set }
}

// Keeps the MPStateMachine_PRIVATE Objective-C runtime name the deleted wrapper had, so the ~37
// Objective-C files that name the type keep compiling and nothing that reads it by name changes.
// Reference MPStateMachinePRIVATE from Swift, MPStateMachine_PRIVATE from Objective-C.
@objc(MPStateMachine_PRIVATE)
public final class MPStateMachinePRIVATE: NSObject,
    MPStateMachineProtocolPRIVATE,
    MPApplicationStateMachineProtocol {
    private static let environmentLock = NSLock()
    private static var runningEnvironment: UInt = 0
    private static var runningInBackgroundFlag = false

    private static let minUploadDateKey = "MinUploadDate"
    private static let minAliasDateKey = "MinAliasDate"
    private static let productionAPSEnvironment = "<key>aps-environment</key><string>production</string>"
    private static let developmentAPSEnvironment = "<key>aps-environment</key><string>development</string>"

    private let userDefaults: MPUserDefaults
    private let connector: MPUserDefaultsConnectorProtocol
    private let messageQueue: DispatchQueue
    private let deploymentTarget: Int
    private let buildSDK: Int

    private var optOutSet = false
    private var storedOptOut = false
    private var storedSDKVersionValue: String?
    private var storedConsumerInfo: MPConsumerInfoPRIVATE?
    private var storedAttAuthorizationStatus: NSNumber?
    private var storedAttAuthorizationTimestamp: NSNumber?

    // The deleted wrapper guarded these three with @synchronized(self); the stress test in
    // MPStateMachineTests.testApiKeySecretThreadSafety reads them from four concurrent queues while
    // a fifth writes, so the lock has to come with them.
    private let accessLock = NSLock()
    private var storedApiKey = ""
    private var storedSecret = ""
    private var storedLogLevel: UInt = 0

    @objc public var apiKey: String {
        get { locked { storedApiKey } }
        set { locked { storedApiKey = newValue } }
    }

    @objc public var secret: String {
        get { locked { storedSecret } }
        set { locked { storedSecret = newValue } }
    }

    @objc public var logLevel: UInt {
        get { locked { storedLogLevel } }
        set { locked { storedLogLevel = newValue } }
    }

    // NSLock.withLock needs iOS 16; this module targets iOS 15.
    private func locked<T>(_ body: () -> T) -> T {
        accessLock.lock()
        defer { accessLock.unlock() }
        return body()
    }

    @objc public var exceptionHandlingMode: String? = RemoteConfig.kMPRemoteConfigExceptionHandlingModeAppDefined
    @objc public var crashMaxPLReportLength: NSNumber?
    @objc public var launchOptions: NSDictionary?
    @objc public var networkPerformanceMeasuringMode: String? = RemoteConfig.kMPRemoteConfigAppDefined
    @objc public var launchInfo: MPLaunchInfo?
    @objc public var triggerEventTypes: NSArray?
    @objc public var triggerMessageTypes: NSArray?
    @objc public var backgrounded = false
    @objc public var dataRamped = false
    @objc public var aliasMaxWindow: NSNumber?
    @objc public var automaticSessionTracking = false
    @objc public var allowASR = false
    @objc public var enableAudienceAPI = false
    @objc public var enableIdentityCaching = false
    @objc public var launchDate: Date? = Date()
    @objc public var pushNotificationModeValue: String?
    @objc public var customModules: [CustomModule]?

    // Held weakly, as the deleted wrapper's weak property did - the backend controller owns the
    // session and clears this when it ends.
    @objc public weak var currentSession: MPSessionPRIVATE?

    // Non-optional because MPApplicationStateMachineProtocol requires it and because the deleted
    // wrapper substituted a boxed NO for a nil store.
    @objc public var firstSeenInstallation: NSNumber = false

    /// Non-optional for the same reason. Written by the Ad Services attribution response and read
    /// by `MPApplication_PRIVATE`.
    @objc public var searchAdsInfo: [AnyHashable: Any] = [:]

    /// Lazily seeded from the last value the wrapper's `-startTime` getter would have installed.
    @objc public var startTime: Date = .init(timeIntervalSinceNow: -1)

    @objc public init(userDefaults: MPUserDefaults,
                      connector: MPUserDefaultsConnectorProtocol,
                      messageQueue: DispatchQueue,
                      sdkVersion: String,
                      deploymentTarget: Int,
                      buildSDK: Int) {
        self.userDefaults = userDefaults
        self.connector = connector
        self.messageQueue = messageQueue
        self.deploymentTarget = deploymentTarget
        self.buildSDK = buildSDK
        super.init()

        // Deferred to the main queue exactly as the deleted wrapper's -init was. Reading the launch
        // counts touches user defaults, which the SDK keeps off the calling thread during start-up.
        DispatchQueue.main.async { [self] in
            persistStoredSDKVersion(sdkVersion)

            let center = NotificationCenter.default
            center.addObserver(self,
                               selector: #selector(handleApplicationDidEnterBackground(_:)),
                               name: UIApplication.didEnterBackgroundNotification,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(handleApplicationWillEnterForeground(_:)),
                               name: UIApplication.willEnterForegroundNotification,
                               object: nil)
            center.addObserver(self,
                               selector: #selector(handleApplicationWillTerminate(_:)),
                               name: UIApplication.willTerminateNotification,
                               object: nil)

            MPApplication_PRIVATE.markInitialLaunchTime(userDefaults: userDefaults)
            MPApplication_PRIVATE.updateLaunchCountsAndDates(userDefaults: userDefaults)
        }
    }

    // MARK: - Notification handlers

    // @objc so UnitTests/ObjCTests/MPStateMachineTests.m can keep driving them directly, as it does
    // through a category on the deleted wrapper.
    @objc public func handleApplicationDidEnterBackground(_: Notification?) {
        let launchDate = launchDate
        messageQueue.async {
            MPApplication_PRIVATE.updateLastUseDate(launchDate, userDefaults: self.userDefaults)
        }
        backgrounded = true
        launchInfo = nil
    }

    @objc public func handleApplicationWillEnterForeground(_: Notification?) {
        backgrounded = false
    }

    @objc public func handleApplicationWillTerminate(_: Notification?) {
        MPApplication_PRIVATE.updateLastUseDate(launchDate, userDefaults: userDefaults)
    }

    @objc public func resetRampPercentage() {
        if dataRamped {
            dataRamped = false
        }
    }

    // MARK: - Lazily derived state

    /// Fetched once from persistence, created and saved when absent. The fetch goes through the
    /// connector because the persistence adapter is an Objective-C type this module cannot import.
    @objc public var consumerInfo: MPConsumerInfoPRIVATE {
        get {
            if let storedConsumerInfo {
                return storedConsumerInfo
            }
            let fetched = connector.fetchOrCreateConsumerInfo()
            storedConsumerInfo = fetched
            return fetched
        }
        set { storedConsumerInfo = newValue }
    }

    @objc public var deviceTokenType: String? {
        get {
            if let storedDeviceTokenType {
                return storedDeviceTokenType
            }
            storedDeviceTokenType = MPStateMachinePRIVATE.deviceTokenType(
                fromProvisioningProfile: MPStateMachinePRIVATE.provisioningProfileString()
            )
            return storedDeviceTokenType
        }
        set { storedDeviceTokenType = newValue }
    }

    private var storedDeviceTokenType: String?

    /// Autodetects on first read by comparing the running version and build against the stored
    /// ones, then caches the verdict. `deploymentTarget` and `buildSDK` are injected because they
    /// come from the `__IPHONE_OS_VERSION_*` macros, which only the Objective-C side can see.
    @objc public var installationType: Int {
        get {
            if storedInstallationType != MPInstallationTypeSwift.autodetect.rawValue {
                return storedInstallationType
            }

            let application = MPApplication_PRIVATE(stateMachine: self,
                                                    userDefaults: userDefaults,
                                                    environment: Int(MPStateMachinePRIVATE.environment()),
                                                    deploymentTarget: deploymentTarget,
                                                    buildSDK: buildSDK)

            if application.storedVersion != nil || application.storedBuild != nil {
                if application.version != application.storedVersion
                    || application.build != application.storedBuild {
                    storedInstallationType = MPInstallationTypeSwift.knownUpgrade.rawValue
                } else {
                    storedInstallationType = MPInstallationTypeSwift.knownSameVersion.rawValue
                }
            } else {
                storedInstallationType = MPInstallationTypeSwift.knownInstall.rawValue
                firstSeenInstallation = true
            }

            return storedInstallationType
        }
        set {
            storedInstallationType = newValue
            firstSeenInstallation = NSNumber(
                value: newValue == MPInstallationTypeSwift.knownInstall.rawValue
            )
        }
    }

    private var storedInstallationType = MPInstallationTypeSwift.autodetect.rawValue

    @objc public var optOut: Bool {
        get {
            if optOutSet {
                return storedOptOut
            }
            if let optOutNumber = userDefaults[Miscellaneous.kMPOptOutStatus] as? NSNumber {
                storedOptOut = optOutNumber.boolValue
            } else {
                storedOptOut = false
                userDefaults[Miscellaneous.kMPOptOutStatus] = NSNumber(value: storedOptOut)
            }
            optOutSet = true
            return storedOptOut
        }
        set {
            storedOptOut = newValue
            optOutSet = true
            userDefaults[Miscellaneous.kMPOptOutStatus] = NSNumber(value: storedOptOut)
        }
    }

    /// Setting a status that moves away from `authorized` clears every user's advertiser id. The
    /// clearing hops through the connector: it needs the identity API and `MParticleUser`, both
    /// Objective-C contract types.
    @objc public var attAuthorizationStatus: NSNumber? {
        get { loadAttAuthorizationStatus() }
        set {
            if persistAttAuthorizationStatus(newValue) {
                connector.clearAdvertiserIdForAllUsers()
            }
        }
    }

    @objc public var attAuthorizationTimestamp: NSNumber? {
        get { loadAttAuthorizationTimestamp() }
        set { persistAttAuthorizationTimestamp(newValue) }
    }

    @objc public var pushNotificationMode: String {
        get {
            if let pushNotificationModeValue {
                return pushNotificationModeValue
            }
            if let stored = userDefaults[RemoteConfig.kMPRemoteConfigPushNotificationModeKey] as? String {
                pushNotificationModeValue = stored
            } else {
                pushNotificationModeValue = RemoteConfig.kMPRemoteConfigAppDefined
            }
            return pushNotificationModeValue ?? RemoteConfig.kMPRemoteConfigAppDefined
        }
        set {
            if pushNotificationModeValue == newValue {
                return
            }
            pushNotificationModeValue = newValue
            userDefaults[RemoteConfig.kMPRemoteConfigPushNotificationModeKey] = pushNotificationModeValue
        }
    }

    // MARK: - Environment

    @objc(environment)
    public static func environment() -> UInt {
        environmentLock.lock()
        defer { environmentLock.unlock() }
        if runningEnvironment != 0 {
            return runningEnvironment
        }
        runningEnvironment = detectEnvironment()
        return runningEnvironment
    }

    @objc public static func setEnvironment(_ environment: UInt) {
        environmentLock.lock()
        runningEnvironment = environment
        environmentLock.unlock()
    }

    @objc public static func detectEnvironment() -> UInt {
        #if targetEnvironment(simulator)
        return 1
        #else
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var info = kinfo_proc()
        info.kp_proc.p_flag = 0
        var infoSize = MemoryLayout<kinfo_proc>.size
        _ = name.withUnsafeMutableBufferPointer { buffer in
            sysctl(buffer.baseAddress, 4, &info, &infoSize, nil, 0)
        }
        let isDebuggerRunning = (info.kp_proc.p_flag & P_TRACED) != 0
        if isDebuggerRunning {
            return 1
        }
        return provisioningProfileString() == nil ? 2 : 1
        #endif
    }

    @objc public static func provisioningProfileString() -> String? {
        guard let provisioningProfilePath = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            return nil
        }
        guard let provisioningProfileData = NSData(contentsOfFile: provisioningProfilePath) else {
            return nil
        }
        let bytes = provisioningProfileData.bytes.bindMemory(to: CChar.self, capacity: provisioningProfileData.length)
        let profile = NSMutableString(capacity: provisioningProfileData.length)
        for index in 0..<provisioningProfileData.length {
            profile.appendFormat("%c", bytes[index])
        }
        let whitespace = CharacterSet.whitespacesAndNewlines
        return (profile as String)
            .components(separatedBy: whitespace)
            .joined()
    }

    @objc public static func runningInBackground() -> Bool {
        environmentLock.lock()
        defer { environmentLock.unlock() }
        return runningInBackgroundFlag
    }

    @objc public static func setRunningInBackground(_ background: Bool) {
        environmentLock.lock()
        runningInBackgroundFlag = background
        environmentLock.unlock()
    }

    @objc public static func isAppExtension() -> Bool {
        AppEnvironmentProvider().isAppExtension()
    }

    @objc(deviceTokenTypeFromProvisioningProfile:)
    public static func deviceTokenType(fromProvisioningProfile profile: String?) -> String {
        guard let profile else {
            return ""
        }
        if profile.range(of: productionAPSEnvironment) != nil {
            return Miscellaneous.kMPDeviceTokenTypeProduction
        }
        if profile.range(of: developmentAPSEnvironment) != nil {
            return Miscellaneous.kMPDeviceTokenTypeDevelopment
        }
        return ""
    }

    @objc public static func minDefaultsKey(forUploadType uploadType: UInt) -> String? {
        switch uploadType {
        case 0:
            return minUploadDateKey
        case 1:
            return minAliasDateKey
        default:
            return nil
        }
    }

    @objc(dataRampedApplyingRampPercentage:deviceIdentifier:)
    public static func dataRamped(
        applyingRampPercentage rampPercentage: Any?,
        deviceIdentifier: String?
    ) -> Bool {
        if MPSwiftIsNull(rampPercentage) {
            return false
        }
        let rampValue = (rampPercentage as? NSNumber)?.intValue ?? 0
        guard rampValue > 0 else {
            return rampValue == 0
        }
        guard let deviceIdentifier, let rampData = deviceIdentifier.data(using: .utf8) else {
            return true
        }
        let hasher = MPIHasher(logger: MPLog(logLevel: .none))
        let rampHash = UInt64(bitPattern: hasher.hashFNV1a(rampData))
        return rampHash % 100 > UInt64(rampValue)
    }

    @objc(searchAdsInfoFromAdAttribution:)
    public static func searchAdsInfo(fromAdAttribution dictionary: Any?) -> NSDictionary? {
        guard let dictionary = dictionary as? NSDictionary, !MPSwiftIsNull(dictionary) else {
            return nil
        }
        let mapped: [String: Any?] = [
            "iad-attribution": dictionary["attribution"],
            "iad-org-id": stringValue(dictionary["orgId"]),
            "iad-campaign-id": stringValue(dictionary["campaignId"]),
            "iad-conversion-type": dictionary["conversionType"],
            "iad-click-date": dictionary["clickDate"],
            "iad-adgroup-id": stringValue(dictionary["adGroupId"]),
            "iad-country-or-region": dictionary["countryOrRegion"],
            "iad-keyword-id": stringValue(dictionary["keywordId"]),
            "iad-ad-id": stringValue(dictionary["adId"])
        ]
        let inner = NSMutableDictionary()
        for (key, value) in mapped {
            if let value, !MPSwiftIsNull(value) {
                inner[key] = value
            }
        }
        return ["Version4.0": inner]
    }

    // MARK: - Remote configuration

    @objc public func applyTriggers(_ triggerDictionary: Any?) -> Bool {
        var dictionary = triggerDictionary
        if MPSwiftIsNull(dictionary) {
            let messageCount = triggerMessageTypes?.count ?? 0
            if messageCount > 1 {
                resetTriggers()
            } else if messageCount == 1 {
                return false
            }
            dictionary = nil
        }

        let eventTypes = (dictionary as? NSDictionary)?[RemoteConfig.kMPRemoteConfigTriggerEventsKey]
        if MPSwiftIsNull(eventTypes) {
            triggerEventTypes = nil
        } else if let eventTypes = eventTypes as? NSArray, triggerEventTypes?.isEqual(eventTypes) != true {
            triggerEventTypes = eventTypes
        }

        let messageTypes = NSMutableArray(object: MessageKeys.kMPMessageTypeStringCommerceEvent)
        if let configMessageTypes = (dictionary as? NSDictionary)?[RemoteConfig.kMPRemoteConfigTriggerMessageTypesKey],
           !MPSwiftIsNull(configMessageTypes),
           let configMessageTypes = configMessageTypes as? NSArray {
            messageTypes.addObjects(from: configMessageTypes as [AnyObject] as [Any])
        }
        triggerMessageTypes = messageTypes
        return true
    }

    @objc public func resetTriggers() {
        triggerEventTypes = nil
        triggerMessageTypes = nil
    }

    @objc public func configureAliasMaxWindow(_ aliasMaxWindow: Any?) {
        if MPSwiftIsNull(aliasMaxWindow) {
            self.aliasMaxWindow = 90
            return
        }
        self.aliasMaxWindow = aliasMaxWindow as? NSNumber
    }

    /// Builds the custom modules for a configuration response. The connector is both the source of
    /// the stored preferences and the object `MPCustomModule` needs, so it is passed straight in.
    @objc(configureCustomModules:)
    public func configureCustomModules(_ customModuleSettings: Any?) {
        guard let customModuleSettings = customModuleSettings as? [[AnyHashable: Any]] else {
            return
        }

        let modules = customModuleSettings.compactMap {
            CustomModule(dictionary: $0, connector: connector)
        }
        customModules = modules.isEmpty ? nil : modules
    }

    // MARK: - Upload windows

    @objc(minUploadDateForUploadType:)
    public func minUploadDate(forUploadType uploadType: UInt) -> Date {
        guard let defaultsKey = MPStateMachinePRIVATE.minDefaultsKey(forUploadType: uploadType) else {
            return Date.distantPast
        }
        guard let minUploadDate = userDefaults[defaultsKey] as? Date else {
            return Date.distantPast
        }
        if minUploadDate.compare(Date()) == .orderedDescending {
            return minUploadDate
        }
        return Date.distantPast
    }

    @objc(setMinUploadDate:uploadType:)
    public func setMinUploadDate(_ minUploadDate: Date?, uploadType: UInt) {
        guard let defaultsKey = MPStateMachinePRIVATE.minDefaultsKey(forUploadType: uploadType) else {
            return
        }
        if let minUploadDate, minUploadDate.compare(Date()) == .orderedDescending {
            userDefaults[defaultsKey] = minUploadDate
        } else if userDefaults[defaultsKey] != nil {
            userDefaults.removeMPObject(forKey: defaultsKey)
        }
    }

    // MARK: - App Tracking Transparency

    @objc public func loadAttAuthorizationStatus() -> NSNumber? {
        if storedAttAuthorizationStatus != nil {
            return storedAttAuthorizationStatus
        }
        if let authorizationState = userDefaults[Miscellaneous.kMPATT] as? NSNumber,
           authorizationState.intValue >= 0,
           authorizationState.intValue <= 3 {
            storedAttAuthorizationStatus = authorizationState
        }
        return storedAttAuthorizationStatus
    }

    @objc public func loadAttAuthorizationTimestamp() -> NSNumber? {
        if storedAttAuthorizationTimestamp != nil {
            return storedAttAuthorizationTimestamp
        }
        storedAttAuthorizationTimestamp = userDefaults[Miscellaneous.kMPATTTimestamp] as? NSNumber
        return storedAttAuthorizationTimestamp
    }

    /// Returns whether the caller should clear every user's advertiser id.
    @objc public func persistAttAuthorizationStatus(_ authorizationState: NSNumber?) -> Bool {
        let newValue = authorizationState?.intValue ?? -1
        guard newValue >= 0, newValue <= 3 else {
            return false
        }
        if let current = storedAttAuthorizationStatus, current.intValue == newValue {
            return false
        }
        storedAttAuthorizationStatus = authorizationState
        storedAttAuthorizationTimestamp = NSNumber(value: trunc(Date().timeIntervalSince1970 * 1000))
        userDefaults[Miscellaneous.kMPATT] = storedAttAuthorizationStatus
        userDefaults[Miscellaneous.kMPATTTimestamp] = storedAttAuthorizationTimestamp
        return newValue != MPATTAuthorizationStatusSwift.authorized.rawValue
    }

    @objc public func persistAttAuthorizationTimestamp(_ timestamp: NSNumber?) {
        if timestamp?.doubleValue == storedAttAuthorizationTimestamp?.doubleValue {
            return
        }
        storedAttAuthorizationTimestamp = timestamp
        userDefaults[Miscellaneous.kMPATTTimestamp] = storedAttAuthorizationTimestamp
    }

    // MARK: - Stored SDK version

    @objc public func loadStoredSDKVersion() -> String? {
        if let storedSDKVersionValue {
            return storedSDKVersionValue
        }
        storedSDKVersionValue = userDefaults["storedSDKVersion"] as? String
        return storedSDKVersionValue
    }

    @objc public func persistStoredSDKVersion(_ storedSDKVersion: String?) {
        if let current = loadStoredSDKVersion(), let storedSDKVersion, current == storedSDKVersion {
            return
        }
        storedSDKVersionValue = storedSDKVersion
        if MPSwiftIsNull(storedSDKVersionValue) {
            userDefaults.removeMPObject(forKey: "storedSDKVersion")
        } else {
            userDefaults["storedSDKVersion"] = storedSDKVersionValue
        }
    }

    private static func stringValue(_ value: Any?) -> Any? {
        if MPSwiftIsNull(value) {
            return nil
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return value
    }
}
