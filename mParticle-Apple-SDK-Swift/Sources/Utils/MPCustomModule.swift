import Foundation

@objc(MPCustomModule) public final class CustomModule: NSObject, NSCopying, NSSecureCoding {
    @objc public let customModuleId: NSNumber
    @objc public let preferences: [CustomModulePreference]?

    /// Memoised because MPUploadBuilder asks for it once per upload and each preference read
    /// goes to NSUserDefaults. Matches the ObjC property this replaced.
    private var memoisedDictionary: [String: Any]?

    // Takes Any rather than a dictionary type: these entries come straight off the configuration
    // response, and a typed parameter would be bridged before this initialiser ran, raising on a
    // non-dictionary instead of rejecting it.
    /// `allowedPreferenceKeys` has no default: every caller states which of the host application's
    /// preferences it is willing to read, so no path acquires a wider set by omission.
    @objc public init?(dictionary: Any,
                       connector: MPUserDefaultsConnectorProtocol,
                       allowedPreferenceKeys: [String],
                       logger: MPLog) {
        guard let dictionary = dictionary as? [AnyHashable: Any],
              let customModuleId = dictionary[CustomModuleConfigKey.moduleId] as? NSNumber,
              let preferenceGroups = dictionary[CustomModuleConfigKey.preferences] as? [Any]
        else {
            return nil
        }

        self.customModuleId = customModuleId

        let allowedPreferenceKeys = Set(allowedPreferenceKeys)
        var parsed: [CustomModulePreference] = []
        for group in preferenceGroups {
            guard let group = group as? [AnyHashable: Any] else {
                continue
            }

            let location = group[CustomModuleConfigKey.location] as? String ?? "NSUserDefaults"
            guard let settings = group[CustomModuleConfigKey.preferenceSettings] as? [Any] else {
                continue
            }

            for setting in settings {
                guard let setting = setting as? [AnyHashable: Any],
                      let preference = CustomModulePreference(dictionary: setting,
                                                              location: location,
                                                              moduleId: customModuleId,
                                                              connector: connector,
                                                              allowedPreferenceKeys: allowedPreferenceKeys,
                                                              logger: logger)
                else {
                    continue
                }
                parsed.append(preference)
            }
        }

        preferences = parsed.isEmpty ? nil : parsed

        super.init()
    }

    private init(customModuleId: NSNumber, preferences: [CustomModulePreference]?) {
        self.customModuleId = customModuleId
        self.preferences = preferences
        super.init()
    }

    @objc public func dictionaryRepresentation() -> [String: Any] {
        if let memoisedDictionary = memoisedDictionary {
            return memoisedDictionary
        }

        var dictionary: [String: Any] = [:]
        for preference in preferences ?? [] {
            dictionary[preference.writeKey] = preference.value
        }

        memoisedDictionary = dictionary
        return dictionary
    }

    public override var description: String {
        // NSDictionary description, matching the %@ formatting the ObjC version produced.
        return "MPCustomModule\n \(dictionaryRepresentation() as NSDictionary)"
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CustomModule else {
            return false
        }
        return (dictionaryRepresentation() as NSDictionary)
            .isEqual(to: other.dictionaryRepresentation())
    }

    public override var hash: Int {
        return (dictionaryRepresentation() as NSDictionary).hash
    }

    // MARK: - NSCopying

    /// Shallow, as before: the copy shares its preference objects with the original.
    public func copy(with _: NSZone? = nil) -> Any {
        return CustomModule(customModuleId: customModuleId, preferences: preferences)
    }

    // MARK: - NSSecureCoding

    /// Coding keys are unchanged from the ObjC implementation so existing archives still read.
    @objc public static var supportsSecureCoding: Bool { true }

    @objc public func encode(with coder: NSCoder) {
        coder.encode(customModuleId, forKey: "customModuleId")
        if let preferences = preferences {
            coder.encode(preferences, forKey: "preferences")
        }
    }

    @objc public required init?(coder: NSCoder) {
        guard let customModuleId = coder.decodeObject(of: NSNumber.self, forKey: "customModuleId") else {
            return nil
        }

        self.customModuleId = customModuleId
        preferences = coder.decodeObject(of: [NSArray.self, CustomModulePreference.self],
                                         forKey: "preferences") as? [CustomModulePreference]

        super.init()
    }
}
