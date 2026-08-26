import Foundation

enum IdentityHTTPKeys {
    static let clientSDK = "client_sdk"
    static let platform = "platform"
    static let sdkVendor = "sdk_vendor"
    static let sdkVersion = "sdk_version"
    static let environment = "environment"
    static let requestId = "request_id"
    static let requestTimestamp = "request_timestamp_ms"
    static let previousMPID = "previous_mpid"
    static let knownIdentities = "known_identities"
    static let identityChanges = "identity_changes"
    static let requestType = "request_type"
    static let apiKey = "api_key"
    static let data = "data"
    static let sourceMPID = "source_mpid"
    static let destinationMPID = "destination_mpid"
    static let startUnixTime = "start_unixtime_ms"
    static let endUnixTime = "end_unixtime_ms"
    static let deviceApplicationStamp = "device_application_stamp"
    static let oldValue = "old_value"
    static let newValue = "new_value"
    static let identityType = "identity_type"
    static let mpid = "mpid"
    static let context = "context"
    static let isEphemeral = "is_ephemeral"
    static let isLoggedIn = "is_logged_in"
    static let code = "code"
    static let message = "message"
    static let changeResults = "change_results"
    static let modifiedMPID = "modified_mpid"
}

@objc public final class MPIdentityHTTPIdentitiesPRIVATE: NSObject {
    private let passthroughValues = NSMutableDictionary()

    @objc public var advertiserId: String?
    @objc public var vendorId: String?
    @objc public var deviceApplicationStamp: String?
    @objc public var pushToken: String?
    @objc public var customerId: String?
    @objc public var email: String?
    @objc public var facebook: String?
    @objc public var facebookCustomAudienceId: String?
    @objc public var google: String?
    @objc public var microsoft: String?
    @objc public var other: String?
    @objc public var twitter: String?
    @objc public var yahoo: String?
    @objc public var other2: String?
    @objc public var other3: String?
    @objc public var other4: String?
    @objc public var other5: String?
    @objc public var other6: String?
    @objc public var other7: String?
    @objc public var other8: String?
    @objc public var other9: String?
    @objc public var other10: String?
    @objc public var mobileNumber: String?
    @objc public var phoneNumber2: String?
    @objc public var phoneNumber3: String?

    override public init() {
        super.init()
    }

    @objc(initWithIdentities:attAuthorizationStatus:)
    public init(identities: NSDictionary?, attAuthorizationStatus: NSNumber?) {
        super.init()
        apply(identities: identities, attAuthorizationStatus: attAuthorizationStatus)
    }

    @objc(stringForIdentityType:)
    public static func string(forIdentityType identityType: Int) -> String? {
        IdentityHTTPKeys.string(forIdentityType: identityType)
    }

    @objc(identityTypeForString:)
    public static func identityType(for string: String?) -> NSNumber? {
        IdentityHTTPKeys.identityType(for: string)
    }

    @objc public func dictionaryRepresentation() -> NSDictionary {
        let dictionary = NSMutableDictionary()
        assign(advertiserId, to: dictionary, key: "ios_idfa")
        assign(vendorId, to: dictionary, key: "ios_idfv")
        assign(deviceApplicationStamp, to: dictionary, key: "device_application_stamp")
        #if os(iOS)
        assign(pushToken, to: dictionary, key: "push_token")
        #endif
        assign(customerId, to: dictionary, key: "customerid")
        assign(email, to: dictionary, key: "email")
        assign(facebook, to: dictionary, key: "facebook")
        assign(facebookCustomAudienceId, to: dictionary, key: "facebookcustomaudienceid")
        assign(google, to: dictionary, key: "google")
        assign(microsoft, to: dictionary, key: "microsoft")
        assign(other, to: dictionary, key: "other")
        assign(twitter, to: dictionary, key: "twitter")
        assign(yahoo, to: dictionary, key: "yahoo")
        assign(other2, to: dictionary, key: "other2")
        assign(other3, to: dictionary, key: "other3")
        assign(other4, to: dictionary, key: "other4")
        assign(other5, to: dictionary, key: "other5")
        assign(other6, to: dictionary, key: "other6")
        assign(other7, to: dictionary, key: "other7")
        assign(other8, to: dictionary, key: "other8")
        assign(other9, to: dictionary, key: "other9")
        assign(other10, to: dictionary, key: "other10")
        assign(mobileNumber, to: dictionary, key: "mobile_number")
        assign(phoneNumber2, to: dictionary, key: "phone_number_2")
        assign(phoneNumber3, to: dictionary, key: "phone_number_3")
        return dictionary
    }

    private func apply(identities: NSDictionary?, attAuthorizationStatus: NSNumber?) {
        identities?.enumerateKeysAndObjects { key, value, _ in
            guard let typeNumber = key as? NSNumber else { return }
            switch MPIdentitySwift(rawValue: typeNumber.intValue) {
            case .customerId: apply(value, to: &customerId, key: "customerid")
            case .email: apply(value, to: &email, key: "email")
            case .facebook: apply(value, to: &facebook, key: "facebook")
            case .facebookCustomAudienceId: apply(value, to: &facebookCustomAudienceId, key: "facebookcustomaudienceid")
            case .google: apply(value, to: &google, key: "google")
            case .microsoft: apply(value, to: &microsoft, key: "microsoft")
            case .other: apply(value, to: &other, key: "other")
            case .twitter: apply(value, to: &twitter, key: "twitter")
            case .yahoo: apply(value, to: &yahoo, key: "yahoo")
            case .other2: apply(value, to: &other2, key: "other2")
            case .other3: apply(value, to: &other3, key: "other3")
            case .other4: apply(value, to: &other4, key: "other4")
            case .other5: apply(value, to: &other5, key: "other5")
            case .other6: apply(value, to: &other6, key: "other6")
            case .other7: apply(value, to: &other7, key: "other7")
            case .other8: apply(value, to: &other8, key: "other8")
            case .other9: apply(value, to: &other9, key: "other9")
            case .other10: apply(value, to: &other10, key: "other10")
            case .mobileNumber: apply(value, to: &mobileNumber, key: "mobile_number")
            case .phoneNumber2: apply(value, to: &phoneNumber2, key: "phone_number_2")
            case .phoneNumber3: apply(value, to: &phoneNumber3, key: "phone_number_3")
            case .iosAdvertiserId:
                if attAuthorizationStatus == nil
                    || attAuthorizationStatus?.intValue == MPATTAuthorizationStatusSwift.authorized.rawValue {
                    apply(value, to: &advertiserId, key: "ios_idfa")
                }
            case .iosVendorId: apply(value, to: &vendorId, key: "ios_idfv")
            case .pushToken: apply(value, to: &pushToken, key: "push_token")
            case .deviceApplicationStamp: apply(value, to: &deviceApplicationStamp, key: "device_application_stamp")
            default: break
            }
        }
    }

    private func apply(_ value: Any, to property: inout String?, key: String) {
        if let stringValue = value as? String {
            passthroughValues.removeObject(forKey: key)
            property = stringValue
            return
        }
        property = nil
        passthroughValues[key] = value
    }

    private func assign(_ value: String?, to dictionary: NSMutableDictionary, key: String) {
        if let value {
            dictionary[key] = value
        } else if let passthrough = passthroughValues[key] {
            dictionary[key] = passthrough
        }
    }
}

@objc public final class MPIdentityHTTPRequestBuilderPRIVATE: NSObject {
    @objc public static func clientSDKDictionary(withVersion sdkVersion: String?) -> NSDictionary {
        let dictionary = NSMutableDictionary()
        #if os(tvOS)
        dictionary[IdentityHTTPKeys.platform] = "tvos"
        #else
        dictionary[IdentityHTTPKeys.platform] = "ios"
        #endif
        dictionary[IdentityHTTPKeys.sdkVendor] = "mparticle"
        if let sdkVersion {
            dictionary[IdentityHTTPKeys.sdkVersion] = sdkVersion
        }
        return dictionary
    }

    @objc public static func baseDictionary(sdkVersion: String?, environment: String?) -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        dictionary[IdentityHTTPKeys.clientSDK] = clientSDKDictionary(withVersion: sdkVersion)
        if let environment {
            dictionary[IdentityHTTPKeys.environment] = environment
        }
        dictionary[IdentityHTTPKeys.requestId] = UUID().uuidString
        let timestamp = floor(Date().timeIntervalSince1970 * 1000)
        dictionary[IdentityHTTPKeys.requestTimestamp] = NSNumber(value: Int64(timestamp))
        return dictionary
    }

    @objc public static func identifyDictionary(
        sdkVersion: String?,
        environment: String?,
        previousMPID: String?,
        identities: NSDictionary?
    ) -> NSDictionary {
        let dictionary = baseDictionary(sdkVersion: sdkVersion, environment: environment)
        if let previousMPID {
            dictionary[IdentityHTTPKeys.previousMPID] = previousMPID
        }
        if let identities {
            dictionary[IdentityHTTPKeys.knownIdentities] = identities
        }
        return dictionary
    }

    @objc public static func modifyDictionary(
        sdkVersion: String?,
        environment: String?,
        identityChanges: NSArray?
    ) -> NSDictionary {
        let dictionary = baseDictionary(sdkVersion: sdkVersion, environment: environment)
        let changes = NSMutableArray()
        identityChanges?.enumerateObjects { object, _, _ in
            if let changeDictionary = object as? NSDictionary {
                changes.add(changeDictionary)
            }
        }
        dictionary[IdentityHTTPKeys.identityChanges] = changes
        return dictionary
    }

    @objc public static func aliasDictionary(
        sdkVersion: String?,
        environment: String?,
        apiKey: String?,
        sourceMPID: NSNumber?,
        destinationMPID: NSNumber?,
        startTime: Date?,
        endTime: Date?,
        deviceApplicationStamp: String?
    ) -> NSDictionary {
        let dictionary = baseDictionary(sdkVersion: sdkVersion, environment: environment)
        dictionary.removeObject(forKey: IdentityHTTPKeys.clientSDK)
        dictionary.removeObject(forKey: IdentityHTTPKeys.requestTimestamp)
        dictionary[IdentityHTTPKeys.requestType] = "alias"
        if let apiKey {
            dictionary[IdentityHTTPKeys.apiKey] = apiKey
        }
        let dataDictionary = NSMutableDictionary()
        if let sourceMPID {
            dataDictionary[IdentityHTTPKeys.sourceMPID] = sourceMPID
        }
        if let destinationMPID {
            dataDictionary[IdentityHTTPKeys.destinationMPID] = destinationMPID
        }
        if let startTime {
            dataDictionary[IdentityHTTPKeys.startUnixTime] = milliseconds(from: startTime)
        }
        if let endTime {
            dataDictionary[IdentityHTTPKeys.endUnixTime] = milliseconds(from: endTime)
        }
        if let deviceApplicationStamp {
            dataDictionary[IdentityHTTPKeys.deviceApplicationStamp] = deviceApplicationStamp
        }
        dictionary[IdentityHTTPKeys.data] = dataDictionary
        return dictionary
    }

    @objc public static func successFields(from dictionary: NSDictionary?) -> NSDictionary {
        let result = NSMutableDictionary()
        result[IdentityHTTPKeys.context] = dictionary?[IdentityHTTPKeys.context]
        if let mpidValue = dictionary?[IdentityHTTPKeys.mpid], !(mpidValue is NSNull) {
            result[IdentityHTTPKeys.mpid] = NSNumber(value: (mpidValue as AnyObject).longLongValue)
        }
        result[IdentityHTTPKeys.isEphemeral] = NSNumber(
            value: (dictionary?[IdentityHTTPKeys.isEphemeral] as? NSNumber)?.boolValue ?? false
        )
        result[IdentityHTTPKeys.isLoggedIn] = NSNumber(
            value: (dictionary?[IdentityHTTPKeys.isLoggedIn] as? NSNumber)?.boolValue ?? false
        )
        if let changeResults = dictionary?[IdentityHTTPKeys.changeResults] {
            result[IdentityHTTPKeys.changeResults] = changeResults
        }
        return result
    }

    private static func milliseconds(from date: Date) -> NSNumber {
        NSNumber(value: Int64(floor(date.timeIntervalSince1970 * 1000)))
    }
}

@objc public final class MPIdentityHTTPIdentityChangePRIVATE: NSObject {
    @objc public var oldValue: String?
    @objc public var value: String?
    @objc public var identityType: String?

    override public init() {
        super.init()
    }

    @objc public init(oldValue: String?, value: String?, identityType: String?) {
        self.oldValue = oldValue
        self.value = value
        self.identityType = identityType
        super.init()
    }

    @objc public func dictionaryRepresentation() -> NSMutableDictionary {
        let dictionary = NSMutableDictionary()
        dictionary[IdentityHTTPKeys.oldValue] = oldValue ?? NSNull()
        dictionary[IdentityHTTPKeys.newValue] = value ?? NSNull()
        if let identityType {
            dictionary[IdentityHTTPKeys.identityType] = identityType
        }
        return dictionary
    }
}

private extension IdentityHTTPKeys {
    static let typeToString: [Int: String] = [
        MPIdentitySwift.customerId.rawValue: "customerid",
        MPIdentitySwift.email.rawValue: "email",
        MPIdentitySwift.facebook.rawValue: "facebook",
        MPIdentitySwift.facebookCustomAudienceId.rawValue: "facebookcustomaudienceid",
        MPIdentitySwift.google.rawValue: "google",
        MPIdentitySwift.microsoft.rawValue: "microsoft",
        MPIdentitySwift.other.rawValue: "other",
        MPIdentitySwift.twitter.rawValue: "twitter",
        MPIdentitySwift.yahoo.rawValue: "yahoo",
        MPIdentitySwift.other2.rawValue: "other2",
        MPIdentitySwift.other3.rawValue: "other3",
        MPIdentitySwift.other4.rawValue: "other4",
        MPIdentitySwift.other5.rawValue: "other5",
        MPIdentitySwift.other6.rawValue: "other6",
        MPIdentitySwift.other7.rawValue: "other7",
        MPIdentitySwift.other8.rawValue: "other8",
        MPIdentitySwift.other9.rawValue: "other9",
        MPIdentitySwift.other10.rawValue: "other10",
        MPIdentitySwift.mobileNumber.rawValue: "mobile_number",
        MPIdentitySwift.phoneNumber2.rawValue: "phone_number_2",
        MPIdentitySwift.phoneNumber3.rawValue: "phone_number_3",
        MPIdentitySwift.iosAdvertiserId.rawValue: "ios_idfa",
        MPIdentitySwift.iosVendorId.rawValue: "ios_idfv",
        MPIdentitySwift.pushToken.rawValue: "push_token",
        MPIdentitySwift.deviceApplicationStamp.rawValue: "device_application_stamp"
    ]

    static func string(forIdentityType identityType: Int) -> String? {
        typeToString[identityType]
    }

    static func identityType(for string: String?) -> NSNumber? {
        guard let string else { return nil }
        guard let match = typeToString.first(where: { $0.value == string }) else { return nil }
        return NSNumber(value: match.key)
    }
}
