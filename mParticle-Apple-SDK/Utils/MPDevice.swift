//
//  MPDevice.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 2/3/25.
//

import Foundation
import QuartzCore
import MachO

#if os(iOS) && !MPARTICLE_LOCATION_DISABLE
import CoreTelephony
#endif

@objc public class MPDevice : NSObject, NSCopying {
    private var stateMachine: MPStateMachine_PRIVATE
    private var userDefaults: MPUserDefaults
    private var identity: MPIdentityApi
    
    @objc required public init(stateMachine: MPStateMachine_PRIVATE, userDefaults: MPUserDefaults, identity: MPIdentityApi) {
        self.stateMachine = stateMachine
        self.userDefaults = userDefaults
        self.identity = identity
        super.init()
    }
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let copyObject = MPDevice(stateMachine: self.stateMachine, userDefaults: self.userDefaults, identity: self.identity)
        
        copyObject.advertiserId = self.advertiserId
        copyObject.architecture = self.architecture
        copyObject.model = self.model
        copyObject.vendorId = self.vendorId
        copyObject.screenSize = self.screenSize
        
        return copyObject
    }

    private var _advertiserId: String?
    @objc public private(set) var advertiserId: String? {
        set {
            _advertiserId = newValue
        }
        get {
            if let adID = _advertiserId {
                return adID
            } else {
                if let userIdentities = identity.currentUser?.identities as? [NSNumber: String] {
                    return userIdentities[NSNumber(value: MPIdentity.iosAdvertiserId.rawValue)]
                } else {
                    return nil
                }
            }
        }
    }

    private var _architecture: String?
    @objc public private(set) var architecture: String {
        set {
            _architecture = newValue
        }
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
    }

    @objc public var brand: String {
        get {
            return UIDevice.current.model
        }
    }
    
#if os(iOS) && !MPARTICLE_LOCATION_DISABLE
    @objc public var carrier: String? {
        get {
            // Deprecated and no longer provided by Apple https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/subscribercellularprovider
            return nil
        }
    }
    
    @objc public var radioAccessTechnology: String {
        get {
            if let radioAccessTechnology = CTTelephonyNetworkInfo().currentRadioAccessTechnology {
                if let range = radioAccessTechnology.range(of: "CTRadioAccessTechnology") {
                    if !range.isEmpty {
                        return String(radioAccessTechnology[...range.upperBound])
                    }
                }
            }
            return "None"
        }
    }
#endif

    @objc public var country: String? {
        get {
            return Locale.current.regionCode
        }
    }

    private var _deviceIdentifier: String?
    @objc public var deviceIdentifier: String {
        get {
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
    }

    @objc public var language: String? {
        get {
            // Extra logic added to strip out the country code to stay consistent with earlier iOS releases
            guard let subString = Locale.preferredLanguages[0].split(separator: "-").first else {
                return nil
            }
            
            return String(subString)
        }
    }

    @objc public var manufacturer: String {
        get {
            return "Apple"
        }
    }

    private var _model: String?
    @objc public private(set) var model: String {
        set {
            _model = newValue
        }
        get {
            if _model == nil {
                var size = 0
                sysctlbyname("hw.machine", nil, &size, nil, 0)
                var model = [CChar](repeating: 0,  count: size)
                sysctlbyname("hw.machine", &model, &size, nil, 0)
                _model = String(cString: model)
            }
            
            if let model = _model {
                return model
            } else {
                return "Not available."
            }
        }
    }

    @objc open var name: String {
        get {
            return UIDevice.current.name
        }
    }

    @objc open var platform: String {
        get {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone, .pad:
                return "iOS"
            case .tv:
                return "tvOS"
            default:
                return "unknown"
                
            }
        }
    }

    @objc public var product: String? {
        get {
            return UIDevice.current.model
        }
    }

    @objc public var operatingSystem: String {
        get {
            return UIDevice.current.systemVersion
        }
    }

    @objc public var timezoneOffset: String {
        get {
            let seconds = TimeZone.current.secondsFromGMT()
            let hours = seconds/3600
            
            return String(format: "%+i", hours)
        }
    }

    @objc public var timezoneDescription: String {
        get {
            return Calendar.current.timeZone.identifier
        }
    }

    private var _vendorId: String?
    @objc public private(set) var vendorId: String? {
        set {
            _vendorId = newValue
        }
        get {
            if _vendorId == nil {
                if let vendor = userDefaults[Device.kMPDeviceAppVendorIdKey] as? String, vendor != Device.kMPDeviceInvalidVendorId {
                    _vendorId = vendor
                } else {
                    _vendorId = UIDevice.current.identifierForVendor?.uuidString
                    userDefaults[Device.kMPDeviceAppVendorIdKey] = _vendorId
                }
            }
            return _vendorId
        }
    }

    @objc public var buildId: String? {
        get {
            var size = 0
            sysctlbyname("kern.osversion", nil, &size, nil, 0)
            var build = [CChar](repeating: 0,  count: size)
            sysctlbyname("kern.osversion", &build, &size, nil, 0)
            return String(cString: build)
        }
    }

    private var _screenSize: CGSize?
    @objc public private(set) var screenSize: CGSize {
        set {
            _screenSize = newValue
        }
        get {
            if let screenSize = _screenSize, !CGSizeEqualToSize(screenSize, CGSizeZero) {
                return screenSize
            } else {
                let bounds = UIScreen.main.bounds
                let scale: CGFloat = UIScreen.main.scale
                let screenSize = CGSize(width: bounds.size.width * scale, height: bounds.height * scale)
                _screenSize = screenSize
                return screenSize
            }
        }
    }

    @objc public var isDaylightSavingTime: Bool {
        get {
            let isDaylightSavingTime = TimeZone.current.isDaylightSavingTime()
            return isDaylightSavingTime
        }
    }

    @objc public var isTablet: Bool {
        get {
            let isTablet = UI_USER_INTERFACE_IDIOM() == .pad
            return isTablet
        }
    }

    @objc public class func jailbrokenInfo() -> [AnyHashable : Any] {
        var jailbroken = false
        
#if targetEnvironment(simulator)
        // Simulator
#else
        let fileManager = FileManager.default
        var signerIdentityKey: String?
        let bundleInfoDictionary = Bundle.main.infoDictionary
        var key: String?
        
        if var infoEnumerator = bundleInfoDictionary?.keys.makeIterator() {
            while (key != nil) {
                key = infoEnumerator.next()
                if let signerId = key?.copy() as? String, (signerId.lowercased() == Device.kMPDeviceSignerIdentityString) {
                    signerIdentityKey = signerId
                    break
                }
            }
        }
        
        jailbroken = signerIdentityKey != nil
        
        if (!jailbroken) {
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
                let jailbrokenTestData = "Jailbroken filesystem test.".data(using: .utf8)
                let filePath = "/private/mpjailbrokentest.txt"
                do {
                    try jailbrokenTestData?.write(to: URL(fileURLWithPath: filePath), options: [])
                } catch {
                    MPLog.warning("Device is not jailbroken, failed to write test file: \(error)")
                }
                jailbroken = fileManager.fileExists(atPath: filePath)

                if jailbroken {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    } catch {
                        MPLog.error("Device is jailbroken and test file still exists, failed to remove test file: \(error)")
                    }
                }
            }
        }
#endif
        return [Miscellaneous.kMPDeviceCydiaJailbrokenKey:NSNumber(value: jailbroken)]
    }
    
    @objc public func dictionaryRepresentation() -> [AnyHashable : Any] {
        var deviceDictionary: [AnyHashable : Any] = [Device.kMPDeviceBrandKey:self.model,
                                                     Device.kMPDeviceNameKey:self.name,
                                                     Device.kMPDeviceProductKey:self.model,
                                                     Device.kMPDeviceOSKey:self.operatingSystem,
                                                     Device.kMPDeviceModelKey:self.model,
                                                     Device.kMPDeviceArchitectureKey:self.architecture,
                                                     Device.kMPScreenWidthKey:String(format: Device.kMPDeviceFloatingPointFormat, self.screenSize.width),
                                                     Device.kMPScreenHeightKey:String(format: Device.kMPDeviceFloatingPointFormat, self.screenSize.height),
                                                     Device.kMPDevicePlatformKey:self.platform,
                                                     Device.kMPDeviceManufacturerKey:self.manufacturer,
                                                     Device.kMPTimezoneOffsetKey:self.timezoneOffset,
                                                     Device.kMPTimezoneDescriptionKey:self.timezoneDescription,
                                                     Device.kMPDeviceJailbrokenKey:MPDevice.jailbrokenInfo(),
                                                     Device.kMPDeviceIsTabletKey:NSNumber(value: self.isTablet),
                                                     Device.kMPDeviceIsDaylightSavingTime:NSNumber(value: self.isDaylightSavingTime),
                                                     Device.kMPDeviceLimitAdTrackingKey:NSNumber(value: false)]
        
        if let language = self.language {
            deviceDictionary[Device.kMPDeviceLocaleLanguageKey] = language
        }
        
        if let country = self.country {
            deviceDictionary[Device.kMPDeviceLocaleCountryKey] = country
        }
        
        if let advertiserId = self.advertiserId {
            deviceDictionary[Device.kMPDeviceAdvertiserIdKey] = advertiserId
        }
        
        if let vendorId = self.vendorId {
            deviceDictionary[Device.kMPDeviceAppVendorIdKey] = vendorId
        }
        
        if let buildId = self.buildId {
            deviceDictionary[Device.kMPDeviceBuildIdKey] = buildId
        }
        
#if os(iOS) && !MPARTICLE_LOCATION_DISABLE
        deviceDictionary[Device.kMPDeviceRadioKey] = self.radioAccessTechnology
        
        if let pushNotificationToken = MPNotificationController_PRIVATE.deviceToken() {
            if let tokenString = MPUserDefaults.stringFromDeviceToken(pushNotificationToken) {
                deviceDictionary[PushNotifications.kMPDeviceTokenKey] = tokenString
            }
        }
#endif
        
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

    @objc public func dictionaryRepresentation(withMpid mpid: NSNumber?) -> [AnyHashable : Any] {
        var deviceDictionary: [AnyHashable : Any] = self.dictionaryRepresentation()
        
        if let mpid = mpid {
            if let userIdentities = self.identity.getUser(mpid)?.identities {
                if let advertiserId = userIdentities[MPIdentity.iosAdvertiserId.rawValue as NSNumber],
                   let currentStatus = stateMachine.attAuthorizationStatus,
                   currentStatus.intValue == MPATTAuthorizationStatusSwift.authorized.rawValue {
                    deviceDictionary[Device.kMPDeviceAdvertiserIdKey] = advertiserId
                }
                
                if let vendorId = userIdentities[MPIdentity.iosVendorId.rawValue as NSNumber] {
                    deviceDictionary[Device.kMPDeviceAppVendorIdKey] = vendorId
                }
            }
        }
        
        return deviceDictionary
    }
}
