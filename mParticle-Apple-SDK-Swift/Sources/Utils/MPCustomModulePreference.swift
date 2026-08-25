import Foundation

/// Mirrors the custom module keys in MPIConstants.h, which this module cannot import.
/// Values must stay identical to that file; `testSwiftPreferenceReadsEveryKeyFromMPIConstants`
/// in the ObjC suite builds its config from the real constants and fails if either side moves.
enum CustomModuleConfigKey {
    static let readKey = "k"
    static let writeKey = "n"
    static let dataType = "t"
    static let defaultValue = "d"
}

@objc(MPCustomModulePreference) public final class CustomModulePreference: NSObject, NSSecureCoding {
    @objc public let moduleId: NSNumber
    @objc public let readKey: String
    @objc public let writeKey: String

    /// Raw `MPDataType`. Int rather than the enum because MPIConstants.h is not importable here.
    @objc public let dataType: Int

    /// Optional, though the header this replaced annotated it `nonnull`: an unrecognised data
    /// type has always left it unset, which `MPCustomModuleTests` asserts through ObjC.
    @objc public let defaultValue: String?

    private let location: String?

    /// Nil only on an unarchived instance — `init(coder:)` has nowhere to get a connector from.
    /// See the `value` getter.
    private let connector: MPUserDefaultsConnectorProtocol?
    private let archivedValue: Any?

    @objc public init?(dictionary: [AnyHashable: Any],
                       location: String?,
                       moduleId: NSNumber,
                       connector: MPUserDefaultsConnectorProtocol) {
        guard let readKey = dictionary[CustomModuleConfigKey.readKey] as? String,
              let writeKey = dictionary[CustomModuleConfigKey.writeKey] as? String
        else {
            return nil
        }

        self.readKey = readKey
        self.writeKey = writeKey
        self.moduleId = moduleId.copy() as? NSNumber ?? moduleId
        self.location = location
        self.connector = connector
        archivedValue = nil

        if let rawDataType = dictionary[CustomModuleConfigKey.dataType] as? NSNumber {
            dataType = rawDataType.intValue
        } else {
            dataType = CustomModuleDataType.string.rawValue
        }

        let configuredDefault = dictionary[CustomModuleConfigKey.defaultValue]
        if CustomModulePreferenceLogic.isMacroPlaceholder(configuredDefault) {
            defaultValue = CustomModulePreferenceLogic.defaultValue(forMacroPlaceholder: configuredDefault as? String)
        } else if let configuredDefault = configuredDefault as? String {
            defaultValue = configuredDefault
        } else {
            defaultValue = CustomModulePreferenceLogic.defaultValue(forDataType: dataType)
        }

        super.init()
    }

    /// Resolved on every read rather than cached, matching the getter this replaced.
    /// `MPCustomModule` memoises its dictionary representation, so this runs once per upload.
    ///
    /// An unarchived instance has no connector and returns the value that was encoded. The ObjC
    /// original re-resolved from `NSUserDefaults` even after decoding, which made the value it
    /// had just decoded dead. Nothing in the SDK unarchives these types — only
    /// `testCustomModuleSerialization` does — and returning the encoded value keeps that
    /// round trip meaningful instead of silently discarding it.
    @objc public var value: Any? {
        guard let connector = connector else {
            return archivedValue
        }

        let userDefaults = MPUserDefaults.standardUserDefaults(connector: connector)
        let userId = connector.mpId()
        let deprecatedKey = "cms::\(writeKey)"
        let customModuleKey = "cms::\(moduleId)::\(writeKey)"

        if let deprecatedValue = userDefaults.mpObject(forKey: deprecatedKey, userId: userId) {
            userDefaults.setMPObject(deprecatedValue, forKey: customModuleKey, userId: userId)
            userDefaults.removeMPObject(forKey: deprecatedKey, userId: userId)
            return deprecatedValue
        }

        if let storedValue = userDefaults.mpObject(forKey: customModuleKey, userId: userId) {
            return storedValue
        }

        let resolved = resolveFromStandardUserDefaults()
        userDefaults.setMPObject(resolved, forKey: customModuleKey, userId: userId)
        return resolved
    }

    private func resolveFromStandardUserDefaults() -> Any? {
        let standard = UserDefaults.standard
        guard standard.dictionaryRepresentation().keys.contains(readKey) else {
            return CustomModulePreferenceLogic.value(forDefaultValue: defaultValue, dataType: dataType)
        }

        var resolved: Any?
        if let storedValue = standard.object(forKey: readKey), !(storedValue is NSNull) {
            if let storedDate = storedValue as? Date {
                resolved = MPDateFormatter.string(fromDateRFC3339: storedDate)
            } else {
                resolved = storedValue
            }
        }

        guard resolved == nil, dataType != CustomModuleDataType.string.rawValue else {
            return resolved
        }

        switch CustomModuleDataType(rawValue: dataType) {
        case .int, .long:
            return NSNumber(value: standard.integer(forKey: readKey))
        case .bool:
            return NSNumber(value: standard.bool(forKey: readKey))
        case .float:
            return NSNumber(value: standard.float(forKey: readKey))
        default:
            return defaultValue
        }
    }

    // MARK: - NSSecureCoding

    /// Coding keys are unchanged from the ObjC implementation so existing archives still read.
    @objc public static var supportsSecureCoding: Bool { true }

    @objc public func encode(with coder: NSCoder) {
        coder.encode(defaultValue, forKey: "defaultValue")
        coder.encode(location, forKey: "location")
        coder.encode(readKey, forKey: "readKey")
        coder.encode(value, forKey: "value")
        coder.encode(writeKey, forKey: "writeKey")
        coder.encode(dataType, forKey: "dataType")
        coder.encode(moduleId.int64Value, forKey: "moduleId")
    }

    @objc public required init?(coder: NSCoder) {
        guard let readKey = coder.decodeObject(of: NSString.self, forKey: "readKey") as String?,
              let writeKey = coder.decodeObject(of: NSString.self, forKey: "writeKey") as String?
        else {
            return nil
        }

        self.readKey = readKey
        self.writeKey = writeKey
        defaultValue = coder.decodeObject(of: NSString.self, forKey: "defaultValue") as String?
        location = coder.decodeObject(of: NSString.self, forKey: "location") as String?
        dataType = coder.decodeInteger(forKey: "dataType")
        moduleId = NSNumber(value: coder.decodeInt64(forKey: "moduleId"))
        // The resolved value is whatever NSUserDefaults held, so any plist type is possible.
        archivedValue = coder.decodeObject(
            of: [NSString.self, NSNumber.self, NSDate.self, NSData.self, NSArray.self, NSDictionary.self],
            forKey: "value"
        )
        connector = nil

        super.init()
    }
}
