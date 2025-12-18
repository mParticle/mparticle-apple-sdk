import Foundation

public func MPMilliseconds(timestamp: Double) -> Double {
    return trunc(timestamp * 1000.0)
}

// NOTE: I kept the same naming here for clarity, but we should rename these
//       after we remove them from the MPIConstants.h file

public class Version {
    public static let kMParticleSDKVersion = "8.40.0"
}

/// User Identities
/// The identities in this enum are limited to end-user forms of identity. A new enum, MPIdentity, has been provided to cover all valid forms of identity supported by the mParticle Identity API (user identities and device identities)
@objc public enum MPUserIdentity: UInt {
    /** User identity other */
    case other = 0
    /** User identity customer id. This is an id issued by your own system */
    case customerId
    /** User identity Facebook */
    case facebook
    /** User identity Twitter */
    case twitter
    /** User identity Google */
    case google
    /** User identity Microsoft */
    case microsoft
    /** User identity Yahoo! */
    case yahoo
    /** User identity Email */
    case email
    /** User identity Alias */
    case alias
    /** User identity Facebook Custom Audience Third Party Id, or User App Id */
    case facebookCustomAudienceId
    /** User identity other 2 */
    case other2
    /** User identity other 3 */
    case other3
    /** User identity other 4 */
    case other4
    /** User identity other 5 */
    case other5
    /** User identity other 6 */
    case other6
    /** User identity other 7 */
    case other7
    /** User identity other 8 */
    case other8
    /** User identity other 9 */
    case other9
    /** User identity other 10 */
    case other10
    /** User identity mobile number */
    case mobileNumber
    /** User identity phone number 2 */
    case phoneNumber2
    /** User identity phone number 3 */
    case phoneNumber3
};

/// MP Identities
@objc public enum MPIdentity: UInt {
    /** User identity other */
    case other = 0
    /** User identity customer id. This is an id issued by your own system */
    case customerId
    /** User identity Facebook */
    case facebook
    /** User identity Twitter */
    case twitter
    /** User identity Google */
    case google
    /** User identity Microsoft */
    case microsoft
    /** User identity Yahoo! */
    case yahoo
    /** User identity Email */
    case email
    /** User identity Alias */
    case alias
    /** User identity Facebook Custom Audience Third Party Id, or User App Id */
    case facebookCustomAudienceId
    /** User identity other 2 */
    case other2
    /** User identity other 3 */
    case other3
    /** User identity other 4 */
    case other4
    /** User identity other 5 */
    case other5
    /** User identity other 6 */
    case other6
    /** User identity other 7 */
    case other7
    /** User identity other 8 */
    case other8
    /** User identity other 9 */
    case other9
    /** User identity other 10 */
    case other10
    /** User identity mobile number */
    case mobileNumber
    /** User identity phone number 2 */
    case phoneNumber2
    /** User identity phone number 3 */
    case phoneNumber3
    /** Device identity advertiser ID (IDFA)
     When setting this, you must also provide the App Tracking Transparency status of the device
     @see setATTStatus:withTimestamp:
     */
    case iosAdvertiserId
    /** Device identity vendor  */
    case iosVendorId
    /** Device identity Push Token  */
    case pushToken
    /** Device identity Application Stamp  */
    case deviceApplicationStamp
};

public enum MessageKeys {
    public static let kMPMessagesKey = "msgs"
    public static let kMPMessageIdKey = "id"
    public static let kMPMessageUserIdKey = "mpid"
    public static let kMPTimestampKey = "ct"
    public static let kMPSessionIdKey = "sid"
    public static let kMPSessionStartTimestamp = "sct"
    public static let kMPEventStartTimestamp = "est"
    public static let kMPEventLength = "el"
    public static let kMPEventNameKey = "n"
    public static let kMPEventTypeKey = "et"
    public static let kMPEventLengthKey = "el"
    public static let kMPAttributesKey = "attrs"
    public static let kMPLocationKey = "lc"
    public static let kMPUserAttributeKey = "ua"
    public static let kMPUserAttributeDeletedKey = "uad"
    public static let kMPEventTypePageView = "pageview"
    public static let kMPUserIdentityArrayKey = "ui"
    public static let kMPUserIdentityIdKey = "i"
    public static let kMPUserIdentityTypeKey = "n"
    public static let kMPUserIdentitySharedGroupIdentifier = "sgi"
    public static let kMPAppStateTransitionType = "t"
    public static let kMPEventTagsKey = "tags"
    public static let kMPLeaveBreadcrumbsKey = "l"
    public static let kMPOptOutKey = "oo"
    public static let kMPDateUserIdentityWasFirstSet = "dfs"
    public static let kMPIsFirstTimeUserIdentityHasBeenSet = "f"
    public static let kMPRemoteNotificationContentIdHistoryKey = "cntid"
    public static let kMPRemoteNotificationTimestampHistoryKey = "ts"
    public static let kMPForwardStatsRecord = "fsr"
    public static let kMPEventCustomFlags = "flags"
    public static let kMPContextKey = "ctx"
    public static let kMPDataPlanKey = "dpln"
    public static let kMPDataPlanIdKey = "id"
    public static let kMPDataPlanVersionKey = "v"
}

public enum PushNotifications {
    public static let kMPDeviceTokenKey = "to"
    public static let kMPPushStatusKey = "r"
    public static let kMPPushMessageTypeKey = "t"
    public static let kMPPushMessageReceived = "received"
    public static let kMPPushMessageAction = "action"
    public static let kMPPushMessageSent = "sent"
    public static let kMPPushMessageProviderKey = "n"
    public static let kMPPushMessageProviderValue = "apn"
    public static let kMPPushMessagePayloadKey = "pay"
    public static let kMPPushNotificationStateKey = "as"
    public static let kMPPushNotificationStateNotRunning = "not_running"
    public static let kMPPushNotificationStateBackground = "background"
    public static let kMPPushNotificationStateForeground = "foreground"
    public static let kMPPushNotificationActionIdentifierKey = "aid"
    public static let kMPPushNotificationBehaviorKey = "bhv"
    public static let kMPPushNotificationActionTitleKey = "an"
    public static let kMPPushNotificationCategoryIdentifierKey = "acid"
}

public enum RemoteConfig {
    public static let kMPRemoteConfigExceptionHandlingModeKey = "cue"
    public static let kMPRemoteConfigExceptionHandlingModeAppDefined = "appdefined"
    public static let kMPRemoteConfigExceptionHandlingModeForce = "forcecatch"
    public static let kMPRemoteConfigExceptionHandlingModeIgnore = "forceignore"
    public static let kMPRemoteConfigCrashMaxPLReportLength = "crml"
    public static let kMPRemoteConfigAppDefined = "appdefined"
    public static let kMPRemoteConfigForceTrue = "forcetrue"
    public static let kMPRemoteConfigForceFalse = "forcefalse"
    public static let kMPRemoteConfigKitsKey = "eks"
    public static let kMPRemoteConfigKitHashesKey = "hs"
    public static let kMPRemoteConfigConsumerInfoKey = "ci"
    public static let kMPRemoteConfigCookiesKey = "ck"
    public static let kMPRemoteConfigMPIDKey = "mpid"
    public static let kMPRemoteConfigCustomModuleSettingsKey = "cms"
    public static let kMPRemoteConfigCustomModuleIdKey = "id"
    public static let kMPRemoteConfigCustomModulePreferencesKey = "pr"
    public static let kMPRemoteConfigCustomModuleLocationKey = "f"
    public static let kMPRemoteConfigCustomModulePreferenceSettingsKey = "ps"
    public static let kMPRemoteConfigCustomModuleReadKey = "k"
    public static let kMPRemoteConfigCustomModuleDataTypeKey = "t"
    public static let kMPRemoteConfigCustomModuleWriteKey = "n"
    public static let kMPRemoteConfigCustomModuleDefaultKey = "d"
    public static let kMPRemoteConfigCustomSettingsKey = "cs"
    public static let kMPRemoteConfigSandboxModeKey = "dbg"
    public static let kMPRemoteConfigSessionTimeoutKey = "stl"
    public static let kMPRemoteConfigPushNotificationDictionaryKey = "pn"
    public static let kMPRemoteConfigPushNotificationModeKey = "pnm"
    public static let kMPRemoteConfigPushNotificationTypeKey = "rnt"
    public static let kMPRemoteConfigLocationKey = "lct"
    public static let kMPRemoteConfigLocationModeKey = "ltm"
    public static let kMPRemoteConfigLocationAccuracyKey = "acc"
    public static let kMPRemoteConfigLocationMinimumDistanceKey = "mdf"
    public static let kMPRemoteConfigRampKey = "rp"
    public static let kMPRemoteConfigTriggerKey = "tri"
    public static let kMPRemoteConfigTriggerEventsKey = "evts"
    public static let kMPRemoteConfigTriggerMessageTypesKey = "dts"
    public static let kMPRemoteConfigUniqueIdentifierKey = "das"
    public static let kMPRemoteConfigBracketKey = "bk"
    public static let kMPRemoteConfigRestrictIDFA = "rdlat"
    public static let kMPRemoteConfigAliasMaxWindow = "alias_max_window"
    public static let kMPRemoteConfigAllowASR = "iasr"
    public static let kMPRemoteConfigExcludeAnonymousUsersKey = "eau"
    public static let kMPRemoteConfigDirectURLRouting = "dur"
    public static let kMPRemoteConfigFlagsKey = "flags"
    public static let kMPRemoteConfigAudienceAPIKey = "AudienceAPI"
    public static let kMPRemoteConfigDataPlanningResults = "dpr"
    public static let kMPRemoteConfigDataPlanning = "dtpn"
    public static let kMPRemoteConfigDataPlanningBlock = "blok"
    public static let kMPRemoteConfigDataPlanningBlockUnplannedEvents = "ev"
    public static let kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes = "ea"
    public static let kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes = "ua"
    public static let kMPRemoteConfigDataPlanningBlockUnplannedIdentities = "id"
    public static let kMPRemoteConfigDataPlanningDataPlanId = "dpid"
    public static let kMPRemoteConfigDataPlanningDataPlanVersion = "dpvn"
    public static let kMPRemoteConfigDataPlanningDataPlanError = "error"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValue = "vers"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueDoc = "version_document"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueDataPoints = "data_points"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueMatch = "match"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueType = "type"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueValidator = "validator"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueDefinition = "definition"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueAdditionalProperties = "additionalProperties"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueUserAttributes = "user_attributes"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEvent = "custom_event"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEventType = "custom_event_type"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueEventName = "event_name"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueScreenView = "screen_view"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueScreenName = "screen_name"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueProductAction = "product_action"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueUnknown = "unknown"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueAddToCart = "add_to_cart"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromCart = "remove_from_cart"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueCheckout = "checkout"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueCheckoutOption = "checkout_option"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueClick = "click"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueViewDetail = "view_detail"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValuePurchase = "purchase"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueRefund = "refund"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueAddToWishlist = "add_to_wishlist"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromWishlist = "remove_from_wish_list"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValuePromotionAction = "promotion_action"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueProductImpressions = "product_impressions"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueCriteria = "criteria"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueAction = "action"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionUnknown = "unknown"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionView = "view"
    public static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionClick = "click"
}

public enum ConsentFiltering {
    public static let kMPConsentKitFilter = "crvf"
    public static let kMPConsentKitFilterIncludeOnMatch = "i"
    public static let kMPConsentKitFilterItems = "v"
    public static let kMPConsentKitFilterItemConsented = "c"
    public static let kMPConsentKitFilterItemHash = "h"
    public static let kMPConsentRegulationFilters = "reg"
    public static let kMPConsentPurposeFilters = "pur"
    public static let kMPConsentGDPRRegulationType = "1"
    public static let kMPConsentCCPARegulationType = "2"
    public static let kMPConsentCCPAPurposeName = "data_sale_opt_out"
}

public enum Notifications {
    public static let kMPCrashReportOccurredNotification = Notification.Name("MPCrashReportOccurredNotification")
    public static let kMPConfigureExceptionHandlingNotification = Notification.Name("MPConfigureExceptionHandlingNotification")
    public static let kMPUserNotificationDictionaryKey = Notification.Name("MPUserNotificationDictionaryKey")
    public static let kMPUserNotificationActionKey = Notification.Name("MPUserNotificationActionKey")
    public static let kMPRemoteNotificationDeviceTokenNotification = Notification.Name("MPRemoteNotificationDeviceTokenNotification")
    public static let kMPRemoteNotificationDeviceTokenKey = Notification.Name("MPRemoteNotificationDeviceTokenKey")
    public static let kMPRemoteNotificationOldDeviceTokenKey = Notification.Name("MPRemoteNotificationOldDeviceTokenKey")
}

public enum Device {
    public static let kMPDeviceInformationKey = "di"
    public static let kMPDeviceBrandKey = "b"
    public static let kMPDeviceProductKey = "p"
    public static let kMPDeviceNameKey = "dn"
    public static let kMPDeviceAdvertiserIdKey = "aid"
    public static let kMPDeviceAppVendorIdKey = "vid"
    public static let kMPDeviceBuildIdKey = "bid"
    public static let kMPDeviceManufacturerKey = "dma"
    public static let kMPDevicePlatformKey = "dp"
    public static let kMPDeviceOSKey = "dosv"
    public static let kMPDeviceModelKey = "dmdl"
    public static let kMPScreenHeightKey = "dsh"
    public static let kMPScreenWidthKey = "dsw"
    public static let kMPDeviceLocaleCountryKey = "dlc"
    public static let kMPDeviceLocaleLanguageKey = "dll"
    public static let kMPNetworkCountryKey = "nc"
    public static let kMPNetworkCarrierKey = "nca"
    public static let kMPMobileNetworkCodeKey = "mnc"
    public static let kMPMobileCountryCodeKey = "mcc"
    public static let kMPTimezoneOffsetKey = "tz"
    public static let kMPTimezoneDescriptionKey = "tzn"
    public static let kMPDeviceJailbrokenKey = "jb"
    public static let kMPDeviceArchitectureKey = "arc"
    public static let kMPDeviceRadioKey = "dr"
    public static let kMPDeviceFloatingPointFormat = "%0.0f"
    public static let kMPDeviceSignerIdentityString = "signeridentity"
    public static let kMPDeviceIsTabletKey = "it"
    public static let kMPDeviceIdentifierKey = "deviceIdentifier"
    public static let kMPDeviceLimitAdTrackingKey = "lat"
    public static let kMPDeviceIsDaylightSavingTime = "idst"
    public static let kMPDeviceInvalidVendorId = "00000000-0000-0000-0000-000000000000"
}

public enum Miscellaneous {
    public static let kMPFirstSeenUser = "fsu"
    public static let kMPLastSeenUser = "lsu"
    public static let kMPAppInitialLaunchTimeKey = "ict"
    public static let kMPHTTPETagHeaderKey = "ETag"
    public static let kMPConfigProvisionedTimestampKey = "ConfigProvisionedTimestamp"
    public static let kMPConfigMaxAgeHeaderKey = "ConfigMaxAgeHeader"
    public static let kMPConfigParameters = "ConfigParameters"
    public static let kMPLastIdentifiedDate = "last_date_used"
    public static let MPSideloadedKitsCountUserDefaultsKey = "MPSideloadedKitsCountUserDefaultsKey"
    public static let kMPLastUploadSettingsUserDefaultsKey = "lastUploadSettings"
    public static let CONFIG_REQUESTS_DEFAULT_EXPIRATION_AGE = 5.0 * 60
    public static let CONFIG_REQUESTS_MAX_EXPIRATION_AGE = 60 * 60 * 24.0
    public static let kMPDeviceTokenTypeKey = "tot"
    public static let kMPATT = "atts"
    public static let kMPATTTimestamp = "attt"
    public static let kMPDeviceCydiaJailbrokenKey = "cydia"
}

/// User Identities
/// The identities in this enum are limited to end-user forms of identity. A new enum, MPIdentity, has been provided to cover all valid forms of identity supported by the mParticle Identity API (user identities and device identities)
@objc public enum MPUserIdentitySwift: Int {
    case other = 0
    case customerId = 1
    case facebook = 2
    case twitter = 3
    case google = 4
    case microsoft = 5
    case yahoo = 6
    case email = 7
    case alias = 8
    case facebookCustomAudienceId = 9
    case other2 = 10
    case other3 = 11
    case other4 = 12
    case other5 = 13
    case other6 = 14
    case other7 = 15
    case other8 = 16
    case other9 = 17
    case other10 = 18
    case mobileNumber = 19
    case phoneNumber2 = 20
    case phoneNumber3 = 21
}

/// MP Identities
@objc public enum MPIdentitySwift: Int {
    case other = 0
    case customerId = 1
    case facebook = 2
    case twitter = 3
    case google = 4
    case microsoft = 5
    case yahoo = 6
    case email = 7
    case alias = 8
    case facebookCustomAudienceId = 9
    case other2 = 10
    case other3 = 11
    case other4 = 12
    case other5 = 13
    case other6 = 14
    case other7 = 15
    case other8 = 16
    case other9 = 17
    case other10 = 18
    case mobileNumber = 19
    case phoneNumber2 = 20
    case phoneNumber3 = 21
    case iosAdvertiserId = 22
    case iosVendorId = 23
    case pushToken = 24
    case deviceApplicationStamp = 25
}

/**
 @see https://developer.apple.com/documentation/apptrackingtransparency/attrackingmanager/authorizationstatus
 */
@objc public enum MPATTAuthorizationStatusSwift: Int {
    case notDetermined = 0
    case restricted
    case denied
    case authorized
}
