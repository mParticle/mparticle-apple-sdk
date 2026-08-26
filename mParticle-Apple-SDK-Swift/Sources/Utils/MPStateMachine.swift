import Darwin
import Foundation

@objc public final class MPStateMachinePRIVATE: NSObject {
    private static let environmentLock = NSLock()
    private static var runningEnvironment: UInt = 0
    private static var runningInBackgroundFlag = false

    private static let minUploadDateKey = "MinUploadDate"
    private static let minAliasDateKey = "MinAliasDate"
    private static let productionAPSEnvironment = "<key>aps-environment</key><string>production</string>"
    private static let developmentAPSEnvironment = "<key>aps-environment</key><string>development</string>"

    private let userDefaults: MPUserDefaults
    private var optOutSet = false
    private var storedOptOut = false
    private var storedSDKVersionValue: String?

    @objc public var apiKey: String?
    @objc public var secret: String?
    @objc public var exceptionHandlingMode: String? = RemoteConfig.kMPRemoteConfigExceptionHandlingModeAppDefined
    @objc public var crashMaxPLReportLength: NSNumber?
    @objc public var launchOptions: NSDictionary?
    @objc public var networkPerformanceMeasuringMode: String? = RemoteConfig.kMPRemoteConfigAppDefined
    @objc public var startTime: Date? = Date(timeIntervalSinceNow: -1)
    @objc public var launchInfo: MPLaunchInfo?
    @objc public var deviceTokenType: String?
    @objc public var firstSeenInstallation: NSNumber?
    @objc public var triggerEventTypes: NSArray?
    @objc public var triggerMessageTypes: NSArray?
    @objc public var logLevel: UInt = 0
    @objc public var installationType: Int = 0
    @objc public var backgrounded = false
    @objc public var dataRamped = false
    @objc public var attAuthorizationStatus: NSNumber?
    @objc public var attAuthorizationTimestamp: NSNumber?
    @objc public var aliasMaxWindow: NSNumber?
    @objc public var searchAdsInfo: NSDictionary?
    @objc public var automaticSessionTracking = false
    @objc public var allowASR = false
    @objc public var enableAudienceAPI = false
    @objc public var enableIdentityCaching = false
    @objc public var launchDate: Date? = Date()
    @objc public var pushNotificationModeValue: String?

    @objc public init(userDefaults: MPUserDefaults) {
        self.userDefaults = userDefaults
        super.init()
    }

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

    @objc public func optOut() -> Bool {
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

    @objc public func setOptOut(_ optOut: Bool) {
        storedOptOut = optOut
        optOutSet = true
        userDefaults[Miscellaneous.kMPOptOutStatus] = NSNumber(value: storedOptOut)
    }

    @objc public func loadAttAuthorizationStatus() -> NSNumber? {
        if attAuthorizationStatus != nil {
            return attAuthorizationStatus
        }
        if let authorizationState = userDefaults[Miscellaneous.kMPATT] as? NSNumber,
           authorizationState.intValue >= 0,
           authorizationState.intValue <= 3 {
            attAuthorizationStatus = authorizationState
        }
        return attAuthorizationStatus
    }

    @objc public func loadAttAuthorizationTimestamp() -> NSNumber? {
        if attAuthorizationTimestamp != nil {
            return attAuthorizationTimestamp
        }
        attAuthorizationTimestamp = userDefaults[Miscellaneous.kMPATTTimestamp] as? NSNumber
        return attAuthorizationTimestamp
    }

    @objc public func persistAttAuthorizationStatus(_ authorizationState: NSNumber?) -> Bool {
        let newValue = authorizationState?.intValue ?? -1
        guard newValue >= 0, newValue <= 3 else {
            return false
        }
        if let current = attAuthorizationStatus, current.intValue == newValue {
            return false
        }
        attAuthorizationStatus = authorizationState
        attAuthorizationTimestamp = NSNumber(value: trunc(Date().timeIntervalSince1970 * 1000))
        userDefaults[Miscellaneous.kMPATT] = attAuthorizationStatus
        userDefaults[Miscellaneous.kMPATTTimestamp] = attAuthorizationTimestamp
        return newValue != MPATTAuthorizationStatusSwift.authorized.rawValue
    }

    @objc public func persistAttAuthorizationTimestamp(_ timestamp: NSNumber?) {
        if timestamp?.doubleValue == attAuthorizationTimestamp?.doubleValue {
            return
        }
        attAuthorizationTimestamp = timestamp
        userDefaults[Miscellaneous.kMPATTTimestamp] = attAuthorizationTimestamp
    }

    @objc public func pushNotificationMode() -> String {
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

    @objc public func setPushNotificationMode(_ pushNotificationMode: String?) {
        if pushNotificationModeValue == pushNotificationMode {
            return
        }
        pushNotificationModeValue = pushNotificationMode
        userDefaults[RemoteConfig.kMPRemoteConfigPushNotificationModeKey] = pushNotificationModeValue
    }

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
