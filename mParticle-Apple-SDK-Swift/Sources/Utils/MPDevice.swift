import UIKit
import MachO
import QuartzCore

@objc
public protocol MPStateMachineMPDeviceProtocol {
    var deviceTokenType: String? { get }
    var attAuthorizationStatus: NSNumber? { get }
    var attAuthorizationTimestamp: NSNumber? { get }
}

@objc
public protocol MPIdentityApiMPDeviceProtocol {
    func currentUserIdentities() -> [NSNumber: String]?
    func userIdentities(mpId: NSNumber) -> [NSNumber: String]?
}

@objc public protocol MPIdentityApiMPUserDefaultsProtocol {
    @objc subscript(key: String) -> Any? { get set }
}

public
enum Device {
    static let kMPDeviceInformationKey = "di"
    static let kMPDeviceBrandKey = "b"
    static let kMPDeviceProductKey = "p"
    static let kMPDeviceNameKey = "dn"
    static let kMPDeviceAdvertiserIdKey = "aid"
    static let kMPDeviceAppVendorIdKey = "vid"
    static let kMPDeviceBuildIdKey = "bid"
    static let kMPDeviceManufacturerKey = "dma"
    static let kMPDevicePlatformKey = "dp"
    static let kMPDeviceOSKey = "dosv"
    static let kMPDeviceModelKey = "dmdl"
    static let kMPScreenHeightKey = "dsh"
    static let kMPScreenWidthKey = "dsw"
    static let kMPDeviceLocaleCountryKey = "dlc"
    static let kMPDeviceLocaleLanguageKey = "dll"
    static let kMPNetworkCountryKey = "nc"
    static let kMPNetworkCarrierKey = "nca"
    static let kMPMobileNetworkCodeKey = "mnc"
    static let kMPMobileCountryCodeKey = "mcc"
    static let kMPTimezoneOffsetKey = "tz"
    static let kMPTimezoneDescriptionKey = "tzn"
    static let kMPDeviceJailbrokenKey = "jb"
    static let kMPDeviceArchitectureKey = "arc"
    static let kMPDeviceRadioKey = "dr"
    static let kMPDeviceFloatingPointFormat = "%0.0f"
    static let kMPDeviceSignerIdentityString = "signeridentity"
    static let kMPDeviceIsTabletKey = "it"
    static let kMPDeviceIdentifierKey = "deviceIdentifier"
    static let kMPDeviceLimitAdTrackingKey = "lat"
    static let kMPDeviceIsDaylightSavingTime = "idst"
    static let kMPDeviceInvalidVendorId = "00000000-0000-0000-0000-000000000000"
}

@objc(MPDevice)
public class MPDevice: NSObject, NSCopying {
    private let stateMachine: MPStateMachineMPDeviceProtocol
    private let userDefaults: MPIdentityApiMPUserDefaultsProtocol
    private let identity: MPIdentityApiMPDeviceProtocol
    private let logger: MPLog

    @objc public required init(
        stateMachine: MPStateMachineMPDeviceProtocol,
        userDefaults: MPIdentityApiMPUserDefaultsProtocol,
        identity: MPIdentityApiMPDeviceProtocol,
        logger: MPLog
    ) {
        self.stateMachine = stateMachine
        self.userDefaults = userDefaults
        self.identity = identity
        self.logger = logger

        super.init()
    }

    @objc public func copy(with _: NSZone? = nil) -> Any {
        let copyObject = MPDevice(stateMachine: stateMachine, userDefaults: userDefaults, identity: identity, logger: logger)

        copyObject.advertiserId = advertiserId
        copyObject.architecture = architecture
        copyObject.model = model
        copyObject.vendorId = vendorId
        copyObject.screenSize = screenSize

        return copyObject
    }

    private var _advertiserId: String?
    @objc public private(set) var advertiserId: String? {
        get {
            if let adID = _advertiserId {
                return adID
            } else {
                if let userIdentities = identity.currentUserIdentities() {
                    return userIdentities[NSNumber(value: MPIdentitySwift.iosAdvertiserId.rawValue)]
                } else {
                    return nil
                }
            }
        }
        set {
            _advertiserId = newValue
        }
    }

    private var _architecture: String?
    @objc public private(set) var architecture: String {
        get {
            if let arch = _architecture {
                return arch
            } else {
                guard let archRaw = NXGetLocalArchInfo().pointee.name else {
                    return "unknown"
                }
                return String(cString: archRaw)
            }
        }
        set {
            _architecture = newValue
        }
    }

    @objc public var brand: String {
        return UIDevice.current.model
    }

    @objc public var country: String? {
        return Locale.current.regionCode
    }

    private var _deviceIdentifier: String?
    @objc public var deviceIdentifier: String {
        if _deviceIdentifier == nil {
            if let deviceID = userDefaults[Device.kMPDeviceIdentifierKey] as? String {
                _deviceIdentifier = deviceID
            } else {
                _deviceIdentifier = UUID().uuidString
                userDefaults[Device.kMPDeviceIdentifierKey] = _deviceIdentifier
            }
        }
        return _deviceIdentifier ?? ""
    }

    @objc public var language: String? {
        // Extra logic added to strip out the country code to stay consistent with earlier iOS releases
        guard let subString = Locale.preferredLanguages.first?.split(separator: "-").first else {
            return nil
        }

        return String(subString)
    }

    @objc public var manufacturer: String {
        return "Apple"
    }

    private var _model: String?
    @objc public private(set) var model: String {
        get {
            if _model == nil {
                var size = 0
                sysctlbyname("hw.machine", nil, &size, nil, 0)
                var model = [CChar](repeating: 0, count: size)
                sysctlbyname("hw.machine", &model, &size, nil, 0)
                _model = String(cString: model)
            }

            if let model = _model {
                return model
            } else {
                return "Not available."
            }
        }
        set {
            _model = newValue
        }
    }

    @objc open var name: String {
        return UIDevice.current.name
    }

    @objc open var platform: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone, .pad:
            return "iOS"
        case .tv:
            return "tvOS"
        default:
            return "unknown"
        }
    }

    @objc public var product: String? {
        return UIDevice.current.model
    }

    @objc public var operatingSystem: String {
        return UIDevice.current.systemVersion
    }

    @objc public var timezoneOffset: String {
        let seconds = TimeZone.current.secondsFromGMT()
        let hours = seconds/3600

        return String(format: "%+i", hours)
    }

    @objc public var timezoneDescription: String {
        return Calendar.current.timeZone.identifier
    }

    private var _vendorId: String?
    @objc public private(set) var vendorId: String? {
        get {
            if _vendorId == nil {
                if let vendor = userDefaults[Device.kMPDeviceAppVendorIdKey] as? String,
                   vendor != Device.kMPDeviceInvalidVendorId {
                    _vendorId = vendor
                } else {
                    _vendorId = UIDevice.current.identifierForVendor?.uuidString
                    userDefaults[Device.kMPDeviceAppVendorIdKey] = _vendorId
                }
            }
            return _vendorId
        }
        set {
            _vendorId = newValue
        }
    }

    @objc public var buildId: String? {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var build = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &build, &size, nil, 0)
        return String(cString: build)
    }

    private var _screenSize: CGSize?
    @objc public private(set) var screenSize: CGSize {
        get {
            if let screenSize = _screenSize, !CGSizeEqualToSize(screenSize, .zero) {
                return screenSize
            } else {
                let bounds = UIScreen.main.bounds
                let scale: CGFloat = UIScreen.main.scale
                let screenSize = CGSize(width: bounds.size.width * scale, height: bounds.height * scale)
                _screenSize = screenSize
                return screenSize
            }
        }
        set {
            _screenSize = newValue
        }
    }

    @objc public var isDaylightSavingTime: Bool {
        let isDaylightSavingTime = TimeZone.current.isDaylightSavingTime()
        return isDaylightSavingTime
    }

    @objc public var isTablet: Bool {
        let isTablet = UIDevice.current.userInterfaceIdiom == .pad
        return isTablet
    }

    @objc public func jailbrokenInfo() -> [AnyHashable: Any] {
        var jailbroken = false

        #if targetEnvironment(simulator)
        // Simulator
        #else
            let fileManager = FileManager.default
            var signerIdentityKey: String?
            let bundleInfoDictionary = Bundle.main.infoDictionary
            var key: String?

            if var infoEnumerator = bundleInfoDictionary?.keys.makeIterator() {
                while key != nil {
                    key = infoEnumerator.next()
                    if let signerId = key?.copy() as? String, signerId.lowercased() == Device.kMPDeviceSignerIdentityString {
                        signerIdentityKey = signerId
                        break
                    }
                }
            }

            jailbroken = signerIdentityKey != nil

            if !jailbroken {
                let filePaths = ["/usr/sbin/sshd",
                                 "/Library/MobileSubstrate/MobileSubstrate.dylib",
                                 "/bin/bash",
                                 "/usr/libexec/sftp-server",
                                 "/Applications/Cydia.app",
                                 "/Applications/blackra1n.app",
                                 "/Applications/FakeCarrier.app",
                                 "/Applications/Icy.app",
                                 "/Applications/IntelliScreen.app",
                                 "/Applications/MxTube.app",
                                 "/Applications/RockApp.app",
                                 "/Applications/SBSettings.app",
                                 "/Applications/WinterBoard.app",
                                 "/Library/MobileSubstrate/DynamicLibraries/LiveClock.plist",
                                 "/Library/MobileSubstrate/DynamicLibraries/Veency.plist",
                                 "/private/var/lib/apt",
                                 "/private/var/lib/cydia",
                                 "/private/var/mobile/Library/SBSettings/Themes",
                                 "/private/var/stash",
                                 "/private/var/tmp/cydia.log",
                                 "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
                                 "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist"]

                for filePath in filePaths {
                    jailbroken = fileManager.fileExists(atPath: filePath)

                    if jailbroken {
                        break
                    }
                }

                if !jailbroken {
                    // Valid test only if running as root on a jailbroken device
                    let jailbrokenTestData = Data("Jailbroken filesystem test.".utf8)
                    let filePath = "/private/mpjailbrokentest.txt"
                    do {
                        try jailbrokenTestData.write(to: URL(fileURLWithPath: filePath), options: [])
                    } catch {
                        logger.warning("Device is not jailbroken, failed to write test file: \(error)")
                    }
                    jailbroken = fileManager.fileExists(atPath: filePath)

                    if jailbroken {
                        do {
                            try FileManager.default.removeItem(atPath: filePath)
                        } catch {
                            logger.error("Device is jailbroken and test file still exists, failed to remove test file: \(error)")
                        }
                    }
                }
            }
        #endif
        return [Miscellaneous.kMPDeviceCydiaJailbrokenKey: NSNumber(value: jailbroken)]
    }

    @objc public func dictionaryRepresentation() -> [AnyHashable: Any] {
        var deviceDictionary: [AnyHashable: Any] = [Device.kMPDeviceBrandKey: model,
                                                    Device.kMPDeviceNameKey: name,
                                                    Device.kMPDeviceProductKey: model,
                                                    Device.kMPDeviceOSKey: operatingSystem,
                                                    Device.kMPDeviceModelKey: model,
                                                    Device.kMPDeviceArchitectureKey: architecture,
                                                    Device.kMPScreenWidthKey: String(
                                                        format: Device.kMPDeviceFloatingPointFormat,
                                                        screenSize.width
                                                    ),
                                                    Device.kMPScreenHeightKey: String(
                                                        format: Device.kMPDeviceFloatingPointFormat,
                                                        screenSize.height
                                                    ),
                                                    Device.kMPDevicePlatformKey: platform,
                                                    Device.kMPDeviceManufacturerKey: manufacturer,
                                                    Device.kMPTimezoneOffsetKey: timezoneOffset,
                                                    Device.kMPTimezoneDescriptionKey: timezoneDescription,
                                                    Device.kMPDeviceJailbrokenKey: jailbrokenInfo(),
                                                    Device.kMPDeviceIsTabletKey: NSNumber(value: isTablet),
                                                    Device.kMPDeviceIsDaylightSavingTime: NSNumber(value: isDaylightSavingTime),
                                                    Device.kMPDeviceLimitAdTrackingKey: NSNumber(value: false)]

        if let language = language {
            deviceDictionary[Device.kMPDeviceLocaleLanguageKey] = language
        }

        if let country = country {
            deviceDictionary[Device.kMPDeviceLocaleCountryKey] = country
        }

        if let advertiserId = advertiserId {
            deviceDictionary[Device.kMPDeviceAdvertiserIdKey] = advertiserId
        }

        if let vendorId = vendorId {
            deviceDictionary[Device.kMPDeviceAppVendorIdKey] = vendorId
        }

        if let buildId = buildId {
            deviceDictionary[Device.kMPDeviceBuildIdKey] = buildId
        }

        if let noDeviceToken = stateMachine.deviceTokenType?.isEmpty, !noDeviceToken {
            deviceDictionary[Miscellaneous.kMPDeviceTokenTypeKey] = stateMachine.deviceTokenType
        }

        if let authStatus = stateMachine.attAuthorizationStatus {
            switch authStatus.intValue {
            case MPATTAuthorizationStatusSwift.notDetermined.rawValue:
                deviceDictionary[Miscellaneous.kMPATT] = "not_determined"
            case MPATTAuthorizationStatusSwift.restricted.rawValue:
                deviceDictionary[Miscellaneous.kMPATT] = "restricted"
            case MPATTAuthorizationStatusSwift.denied.rawValue:
                deviceDictionary[Miscellaneous.kMPATT] = "denied"
            case MPATTAuthorizationStatusSwift.authorized.rawValue:
                deviceDictionary[Miscellaneous.kMPATT] = "authorized"
            default:
                break
            }
        }

        if let authTimestamp = stateMachine.attAuthorizationTimestamp {
            deviceDictionary[Miscellaneous.kMPATTTimestamp] = authTimestamp
        }

        return deviceDictionary
    }

    @objc public func dictionaryRepresentation(withMpid mpid: NSNumber?) -> [AnyHashable: Any] {
        var deviceDictionary: [AnyHashable: Any] = dictionaryRepresentation()

        if let mpid = mpid {
            if let userIdentities = identity.userIdentities(mpId: mpid) {
                if let advertiserId = userIdentities[MPIdentitySwift.iosAdvertiserId.rawValue as NSNumber],
                   let currentStatus = stateMachine.attAuthorizationStatus,
                   currentStatus.intValue == MPATTAuthorizationStatusSwift.authorized.rawValue {
                    deviceDictionary[Device.kMPDeviceAdvertiserIdKey] = advertiserId
                }

                if let vendorId = userIdentities[MPIdentitySwift.iosVendorId.rawValue as NSNumber] {
                    deviceDictionary[Device.kMPDeviceAppVendorIdKey] = vendorId
                }
            }
        }

        return deviceDictionary
    }
}
