import Foundation
import MachO
import UIKit

/// State-machine surface `MPApplication_PRIVATE` needs. The ObjC `MPStateMachine_PRIVATE`
/// satisfies this by duck typing at the injection boundary (Swift cannot import the ObjC module).
@objc public protocol MPApplicationStateMachineProtocol {
    var firstSeenInstallation: NSNumber { get }
    var searchAdsInfo: [AnyHashable: Any] { get }
    var launchDate: Date? { get }
    var allowASR: Bool { get }
}

/// `MPUserDefaults` surface `MPApplication_PRIVATE` needs.
@objc public protocol MPApplicationMPUserDefaultsProtocol {
    @objc subscript(key: String) -> Any? { get set }
    func removeMPObject(forKey key: String)
    func sideloadedKitsCount() -> UInt
}

/// Wire-format keys for the app-info payload. Canonical copies live here on the Swift side;
/// ObjC callers reference them as `MPApplicationKeys.k...`.
@objc(MPApplicationKeys) public class MPApplicationKeys: NSObject {
    @objc public static var kMPApplicationInformationKey: String { "ai" }
    @objc public static var kMPApplicationNameKey: String { "an" }
    @objc public static var kMPApplicationVersionKey: String { "av" }
    @objc public static var kMPAppPackageNameKey: String { "apn" }
    @objc public static var kMPAppInitialLaunchTimeKey: String { "ict" }
    @objc public static var kMPAppBuildNumberKey: String { "abn" }
    @objc public static var kMPAppBuildUUIDKey: String { "bid" }
    @objc public static var kMPAppArchitectureKey: String { "arc" }
    @objc public static var kMPAppPiratedKey: String { "pir" }
    @objc public static var kMPAppDeploymentTargetKey: String { "tsv" }
    @objc public static var kMPAppBuildSDKKey: String { "bsv" }
    @objc public static var kMPAppUpgradeDateKey: String { "ud" }
    @objc public static var kMPAppLaunchCountKey: String { "lc" }
    @objc public static var kMPAppLaunchCountSinceUpgradeKey: String { "lcu" }
    @objc public static var kMPAppLastUseDateKey: String { "lud" }
    @objc public static var kMPAppStoredVersionKey: String { "asv" }
    @objc public static var kMPAppStoredBuildKey: String { "asb" }
    @objc public static var kMPAppEnvironmentKey: String { "env" }
    @objc public static var kMPAppStoreReceiptKey: String { "asr" }
    @objc public static var kMPAppImageBaseAddressKey: String { "iba" }
    @objc public static var kMPAppImageSizeKey: String { "is" }
    @objc public static var kMPAppSideloadKitsCountKey: String { "sideloaded_kits_count" }
}

// swiftlint:disable:next type_name - name mirrors the pre-existing ObjC class identity used by all callers
@objc(MPApplication_PRIVATE) public class MPApplication_PRIVATE: NSObject, NSCopying {
    // Keys that live in MPIConstants on the ObjC side; duplicated here because Swift cannot
    // import the ObjC module (same pattern as MPDevice's `Device` enum).
    private static let firstSeenInstallationKey = "fi"
    private static let searchAdsAttributionKey = "asaa"

    private let stateMachine: MPApplicationStateMachineProtocol
    private var userDefaults: MPApplicationMPUserDefaultsProtocol
    private let infoProvider: MPApplicationInfoProvider
    private let environmentValue: Int
    private let deploymentTarget: Int
    private let buildSDK: Int

    private var appInfo: [AnyHashable: Any]?
    private var cachedArchitecture: String?
    private var cachedBuildUUID: String?
    private var cachedInitialLaunchTime: NSNumber?

    // deploymentTarget / buildSDK are the ObjC preprocessor constants
    // __IPHONE_OS_VERSION_MIN_REQUIRED / __IPHONE_OS_VERSION_MAX_ALLOWED, injected by the
    // ObjC caller because Swift cannot read Clang build-time macros.
    @objc public init(stateMachine: MPApplicationStateMachineProtocol,
                      userDefaults: MPApplicationMPUserDefaultsProtocol,
                      environment: Int,
                      deploymentTarget: Int,
                      buildSDK: Int,
                      infoProvider: MPApplicationInfoProvider) {
        self.stateMachine = stateMachine
        self.userDefaults = userDefaults
        self.environmentValue = environment
        self.deploymentTarget = deploymentTarget
        self.buildSDK = buildSDK
        self.infoProvider = infoProvider
        super.init()
    }

    @objc public convenience init(stateMachine: MPApplicationStateMachineProtocol,
                                  userDefaults: MPApplicationMPUserDefaultsProtocol,
                                  environment: Int,
                                  deploymentTarget: Int,
                                  buildSDK: Int) {
        self.init(stateMachine: stateMachine,
                  userDefaults: userDefaults,
                  environment: environment,
                  deploymentTarget: deploymentTarget,
                  buildSDK: buildSDK,
                  infoProvider: MPApplicationInfoProvider())
    }

    // MARK: - NSCopying

    @objc public func copy(with _: NSZone? = nil) -> Any {
        let copyObject = MPApplication_PRIVATE(stateMachine: stateMachine,
                                               userDefaults: userDefaults,
                                               environment: environmentValue,
                                               deploymentTarget: deploymentTarget,
                                               buildSDK: buildSDK,
                                               infoProvider: infoProvider)
        copyObject.cachedArchitecture = cachedArchitecture
        copyObject.cachedBuildUUID = cachedBuildUUID
        copyObject.cachedInitialLaunchTime = cachedInitialLaunchTime
        return copyObject
    }

    // MARK: - Bundle-derived accessors

    @objc public var architecture: String {
        if let cachedArchitecture { return cachedArchitecture }
        let name = NXGetLocalArchInfo().pointee.name.map { String(cString: $0) } ?? ""
        cachedArchitecture = name
        return name
    }

    @objc public var build: String? { infoProvider.build }
    @objc public var bundleIdentifier: String? { infoProvider.bundleIdentifier }
    @objc public var name: String? { infoProvider.name }
    @objc public var version: String? { infoProvider.version }
    @objc public var pirated: NSNumber { NSNumber(value: infoProvider.pirated) }

    @objc public var buildUUID: String? {
        #if targetEnvironment(simulator)
        return "00000000-0000-0000-0000-000000000000"
        #else
        if let cachedBuildUUID { return cachedBuildUUID }
        cachedBuildUUID = MPApplication_PRIVATE.mainExecutableUUIDString()
        return cachedBuildUUID
        #endif
    }

    // MARK: - State-machine-derived accessors

    @objc public var firstSeenInstallation: NSNumber { stateMachine.firstSeenInstallation }
    @objc public var environment: Int { environmentValue }
    @objc public var searchAdsAttribution: [AnyHashable: Any] { stateMachine.searchAdsInfo }

    // MARK: - UserDefaults-backed accessors

    @objc public var initialLaunchTime: NSNumber {
        if let cachedInitialLaunchTime { return cachedInitialLaunchTime }
        if let stored = userDefaults[MPApplicationKeys.kMPAppInitialLaunchTimeKey] as? NSNumber {
            cachedInitialLaunchTime = stored
            return stored
        }
        let now = MPApplication_PRIVATE.currentEpochMilliseconds()
        cachedInitialLaunchTime = now
        userDefaults[MPApplicationKeys.kMPAppInitialLaunchTimeKey] = now
        return now
    }

    @objc public var lastUseDate: NSNumber {
        get {
            if let stored = userDefaults[MPApplicationKeys.kMPAppLastUseDateKey] as? NSNumber {
                return stored
            }
            let interval = stateMachine.launchDate?.timeIntervalSince1970 ?? 0
            return NSNumber(value: MPMilliseconds(timestamp: interval))
        }
        set { userDefaults[MPApplicationKeys.kMPAppLastUseDateKey] = newValue }
    }

    @objc public var launchCount: NSNumber? {
        get { userDefaults[MPApplicationKeys.kMPAppLaunchCountKey] as? NSNumber }
        set { userDefaults[MPApplicationKeys.kMPAppLaunchCountKey] = newValue }
    }

    @objc public var launchCountSinceUpgrade: NSNumber? {
        get { userDefaults[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] as? NSNumber }
        set { userDefaults[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] = newValue }
    }

    @objc public var upgradeDate: NSNumber? {
        get { userDefaults[MPApplicationKeys.kMPAppUpgradeDateKey] as? NSNumber }
        set { userDefaults[MPApplicationKeys.kMPAppUpgradeDateKey] = newValue }
    }

    @objc public var storedBuild: String? {
        get { userDefaults[MPApplicationKeys.kMPAppStoredBuildKey] as? String }
        set {
            if let newValue {
                userDefaults[MPApplicationKeys.kMPAppStoredBuildKey] = newValue
            } else {
                userDefaults.removeMPObject(forKey: MPApplicationKeys.kMPAppStoredBuildKey)
            }
        }
    }

    @objc public var storedVersion: String? {
        get { userDefaults[MPApplicationKeys.kMPAppStoredVersionKey] as? String }
        set {
            if let newValue {
                userDefaults[MPApplicationKeys.kMPAppStoredVersionKey] = newValue
            } else {
                userDefaults.removeMPObject(forKey: MPApplicationKeys.kMPAppStoredVersionKey)
            }
        }
    }

    @objc public var sideloadedKitsCount: NSNumber { NSNumber(value: userDefaults.sideloadedKitsCount()) }

    // MARK: - App Store receipt

    private static var cachedAppStoreReceipt: String?

    @objc public static func appStoreReceipt() -> String? {
        if cachedAppStoreReceipt == nil {
            cachedAppStoreReceipt = MPApplicationInfoProvider().appStoreReceipt()
        }
        return cachedAppStoreReceipt
    }

    // MARK: - Launch bookkeeping (class methods, userDefaults injected by caller)

    @objc public static func markInitialLaunchTime(userDefaults: MPApplicationMPUserDefaultsProtocol) {
        if userDefaults[MPApplicationKeys.kMPAppInitialLaunchTimeKey] == nil {
            userDefaults[MPApplicationKeys.kMPAppInitialLaunchTimeKey] = currentEpochMilliseconds()
        }
    }

    @objc public static func updateLastUseDate(_ date: Date?, userDefaults: MPApplicationMPUserDefaultsProtocol) {
        let interval = date?.timeIntervalSince1970 ?? 0
        userDefaults[MPApplicationKeys.kMPAppLastUseDateKey] =
            NSNumber(value: MPMilliseconds(timestamp: interval))
    }

    @objc public static func updateLaunchCountsAndDates(userDefaults: MPApplicationMPUserDefaultsProtocol) {
        let provider = MPApplicationInfoProvider()

        let launchCount = (userDefaults[MPApplicationKeys.kMPAppLaunchCountKey] as? NSNumber)?.intValue ?? 0
        userDefaults[MPApplicationKeys.kMPAppLaunchCountKey] = NSNumber(value: launchCount + 1)

        let storedVersion = userDefaults[MPApplicationKeys.kMPAppStoredVersionKey] as? String
        let storedBuild = userDefaults[MPApplicationKeys.kMPAppStoredBuildKey] as? String
        if provider.version != storedVersion || provider.build != storedBuild {
            userDefaults[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] = NSNumber(value: 1)
            userDefaults[MPApplicationKeys.kMPAppUpgradeDateKey] = currentEpochMilliseconds()
        } else {
            let sinceUpgrade = (userDefaults[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] as? NSNumber)?.intValue ?? 0
            userDefaults[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] = NSNumber(value: sinceUpgrade + 1)
        }
    }

    @objc public static func updateStoredVersionAndBuildNumbers(userDefaults: MPApplicationMPUserDefaultsProtocol) {
        let provider = MPApplicationInfoProvider()
        if let version = provider.version {
            userDefaults[MPApplicationKeys.kMPAppStoredVersionKey] = version
        } else {
            userDefaults.removeMPObject(forKey: MPApplicationKeys.kMPAppStoredVersionKey)
        }
        if let build = provider.build {
            userDefaults[MPApplicationKeys.kMPAppStoredBuildKey] = build
        } else {
            userDefaults.removeMPObject(forKey: MPApplicationKeys.kMPAppStoredBuildKey)
        }
    }

    // MARK: - UIApplication (extension-safe)

    private static var mockUIApplication: Any?

    @objc public static func setMockApplication(_ mockApplication: Any?) {
        mockUIApplication = mockApplication
    }

    @objc public static func sharedUIApplication() -> UIApplication? {
        if let mockUIApplication {
            return mockUIApplication as? UIApplication
        }
        // `UIApplication.shared` is unavailable when built with APPLICATION_EXTENSION_API_ONLY,
        // so resolve it dynamically (matches the prior ObjC performSelector path).
        let selector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: selector) else { return nil }
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }

    // MARK: - App image info (synchronous dyld walk; the prior async dyld-callback list was

    // never read from a signal context here, so an on-demand walk is equivalent and Swift-safe)

    @objc public static func appImageInfo() -> [AnyHashable: Any] {
        var imageBaseAddress: UInt = 0
        var imageSize: UInt64 = 0

        for index in 0..<_dyld_image_count() {
            guard let header = _dyld_get_image_header(index) else { continue }
            let (base, cmdSize) = imageMetrics(header)
            if imageBaseAddress == 0 {
                imageBaseAddress = base
            }
            imageSize += UInt64(cmdSize)
        }

        return [MPApplicationKeys.kMPAppImageBaseAddressKey: NSNumber(value: imageBaseAddress),
                MPApplicationKeys.kMPAppImageSizeKey: NSNumber(value: imageSize)]
    }

    // MARK: - Dictionary representation

    @objc public func dictionaryRepresentation() -> [AnyHashable: Any] {
        if let appInfo {
            var mutableAppInfo = appInfo
            let searchAds = searchAdsAttribution
            if !searchAds.isEmpty {
                mutableAppInfo[MPApplication_PRIVATE.searchAdsAttributionKey] = searchAds
            }
            return mutableAppInfo
        }

        var applicationInfo: [AnyHashable: Any] = [
            MPApplicationKeys.kMPAppPiratedKey: pirated,
            MPApplicationKeys.kMPAppInitialLaunchTimeKey: initialLaunchTime,
            MPApplicationKeys.kMPAppDeploymentTargetKey: String(format: "%i", deploymentTarget),
            MPApplicationKeys.kMPAppBuildSDKKey: String(format: "%i", buildSDK),
            MPApplicationKeys.kMPAppEnvironmentKey: NSNumber(value: environmentValue),
            MPApplication_PRIVATE.firstSeenInstallationKey: NSNumber(value: firstSeenInstallation.boolValue),
            MPApplicationKeys.kMPAppSideloadKitsCountKey: sideloadedKitsCount
        ]

        let searchAds = searchAdsAttribution
        if !searchAds.isEmpty {
            applicationInfo[MPApplication_PRIVATE.searchAdsAttributionKey] = searchAds
        }
        if let bundleIdentifier { applicationInfo[MPApplicationKeys.kMPAppPackageNameKey] = bundleIdentifier }
        if let buildUUID { applicationInfo[MPApplicationKeys.kMPAppBuildUUIDKey] = buildUUID }
        applicationInfo[MPApplicationKeys.kMPAppArchitectureKey] = architecture
        if let name { applicationInfo[MPApplicationKeys.kMPApplicationNameKey] = name }
        if let upgradeDate { applicationInfo[MPApplicationKeys.kMPAppUpgradeDateKey] = upgradeDate }
        if let launchCount { applicationInfo[MPApplicationKeys.kMPAppLaunchCountKey] = launchCount }
        if let launchCountSinceUpgrade {
            applicationInfo[MPApplicationKeys.kMPAppLaunchCountSinceUpgradeKey] = launchCountSinceUpgrade }
        applicationInfo[MPApplicationKeys.kMPAppLastUseDateKey] = lastUseDate
        if let version { applicationInfo[MPApplicationKeys.kMPApplicationVersionKey] = version }
        if let build { applicationInfo[MPApplicationKeys.kMPAppBuildNumberKey] = build }

        if stateMachine.allowASR, let receipt = MPApplication_PRIVATE.appStoreReceipt() {
            applicationInfo[MPApplicationKeys.kMPAppStoreReceiptKey] = receipt
        }

        appInfo = applicationInfo
        return applicationInfo
    }

    // MARK: - Helpers

    private static func currentEpochMilliseconds() -> NSNumber {
        NSNumber(value: MPMilliseconds(timestamp: Date().timeIntervalSince1970))
    }

    /// UUID of the main executable image (LC_UUID), matching the prior `MH_EXECUTE` search.
    private static func mainExecutableUUIDString() -> String? {
        for index in 0..<_dyld_image_count() {
            guard let header = _dyld_get_image_header(index),
                  header.pointee.filetype == MH_EXECUTE else { continue }
            return uuid(from: header)?.uuidString
        }
        return nil
    }

    private static func imageMetrics(_ header: UnsafePointer<mach_header>) -> (base: UInt, cmdSize: UInt) {
        let base = UInt(bitPattern: header)
        switch header.pointee.magic {
        case MH_MAGIC_64, MH_CIGAM_64:
            let header64 = UnsafeRawPointer(header).assumingMemoryBound(to: mach_header_64.self)
            return (base, UInt(header64.pointee.sizeofcmds))
        default:
            return (base, UInt(header.pointee.sizeofcmds))
        }
    }

    /// Bounds-checked LC_UUID extraction from a Mach-O header.
    private static func uuid(from header: UnsafePointer<mach_header>) -> UUID? {
        let headerSize: Int
        switch header.pointee.magic {
        case MH_MAGIC_64, MH_CIGAM_64:
            headerSize = MemoryLayout<mach_header_64>.size
        case MH_MAGIC, MH_CIGAM:
            headerSize = MemoryLayout<mach_header>.size
        default:
            return nil
        }

        let commandsStart = UnsafeRawPointer(header).advanced(by: headerSize)
        let commandsSize = Int(header.pointee.sizeofcmds)
        let commandCount = Int(header.pointee.ncmds)
        var offset = 0

        for _ in 0..<commandCount {
            let remaining = commandsSize - offset
            guard remaining >= MemoryLayout<load_command>.size else { return nil }

            let pointer = commandsStart.advanced(by: offset)
            let command = pointer.load(as: load_command.self)
            let commandSize = Int(command.cmdsize)
            guard commandSize >= MemoryLayout<load_command>.size, commandSize <= remaining else { return nil }

            if command.cmd == LC_UUID, commandSize >= MemoryLayout<uuid_command>.size {
                return UUID(uuid: pointer.load(as: uuid_command.self).uuid)
            }
            offset += commandSize
        }
        return nil
    }
}
