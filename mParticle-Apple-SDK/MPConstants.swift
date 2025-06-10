//
//  MPConstants.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/3/24.
//
// NOTE: This will temporarily duplicate values from MPIConstants.h to prevent
//       the need to make all our internal constants public during porting
//

func MPMilliseconds(timestamp: Double) -> Double {
    return trunc(timestamp * 1000.0)
}

// NOTE: I kept the same naming here for clarity, but we should rename these
//       after we remove them from the MPIConstants.h file

let kMParticleSDKVersion = "8.32.0"

struct MessageKeys {
    static let kMPMessagesKey = "msgs"
    static let kMPMessageIdKey = "id"
    static let kMPMessageUserIdKey = "mpid"
    static let kMPTimestampKey = "ct"
    static let kMPSessionIdKey = "sid"
    static let kMPSessionStartTimestamp = "sct"
    static let kMPEventStartTimestamp = "est"
    static let kMPEventLength = "el"
    static let kMPEventNameKey = "n"
    static let kMPEventTypeKey = "et"
    static let kMPEventLengthKey = "el"
    static let kMPAttributesKey = "attrs"
    static let kMPLocationKey = "lc"
    static let kMPUserAttributeKey = "ua"
    static let kMPUserAttributeDeletedKey = "uad"
    static let kMPEventTypePageView = "pageview"
    static let kMPUserIdentityArrayKey = "ui"
    static let kMPUserIdentityIdKey = "i"
    static let kMPUserIdentityTypeKey = "n"
    static let kMPUserIdentitySharedGroupIdentifier = "sgi"
    static let kMPAppStateTransitionType = "t"
    static let kMPEventTagsKey = "tags"
    static let kMPLeaveBreadcrumbsKey = "l"
    static let kMPOptOutKey = "oo"
    static let kMPDateUserIdentityWasFirstSet = "dfs"
    static let kMPIsFirstTimeUserIdentityHasBeenSet = "f"
    static let kMPRemoteNotificationContentIdHistoryKey = "cntid"
    static let kMPRemoteNotificationTimestampHistoryKey = "ts"
    static let kMPForwardStatsRecord = "fsr"
    static let kMPEventCustomFlags = "flags"
    static let kMPContextKey = "ctx"
    static let kMPDataPlanKey = "dpln"
    static let kMPDataPlanIdKey = "id"
    static let kMPDataPlanVersionKey = "v"
}

struct PushNotifications {
    static let kMPDeviceTokenKey = "to"
    static let kMPPushStatusKey = "r"
    static let kMPPushMessageTypeKey = "t"
    static let kMPPushMessageReceived = "received"
    static let kMPPushMessageAction = "action"
    static let kMPPushMessageSent = "sent"
    static let kMPPushMessageProviderKey = "n"
    static let kMPPushMessageProviderValue = "apn"
    static let kMPPushMessagePayloadKey = "pay"
    static let kMPPushNotificationStateKey = "as"
    static let kMPPushNotificationStateNotRunning = "not_running"
    static let kMPPushNotificationStateBackground = "background"
    static let kMPPushNotificationStateForeground = "foreground"
    static let kMPPushNotificationActionIdentifierKey = "aid"
    static let kMPPushNotificationBehaviorKey = "bhv"
    static let kMPPushNotificationActionTitleKey = "an"
    static let kMPPushNotificationCategoryIdentifierKey = "acid"
}

struct RemoteConfig {
    static let kMPRemoteConfigExceptionHandlingModeKey = "cue"
    static let kMPRemoteConfigExceptionHandlingModeAppDefined = "appdefined"
    static let kMPRemoteConfigExceptionHandlingModeForce = "forcecatch"
    static let kMPRemoteConfigExceptionHandlingModeIgnore = "forceignore"
    static let kMPRemoteConfigCrashMaxPLReportLength = "crml"
    static let kMPRemoteConfigAppDefined = "appdefined"
    static let kMPRemoteConfigForceTrue = "forcetrue"
    static let kMPRemoteConfigForceFalse = "forcefalse"
    static let kMPRemoteConfigKitsKey = "eks"
    static let kMPRemoteConfigKitHashesKey = "hs"
    static let kMPRemoteConfigConsumerInfoKey = "ci"
    static let kMPRemoteConfigCookiesKey = "ck"
    static let kMPRemoteConfigMPIDKey = "mpid"
    static let kMPRemoteConfigCustomModuleSettingsKey = "cms"
    static let kMPRemoteConfigCustomModuleIdKey = "id"
    static let kMPRemoteConfigCustomModulePreferencesKey = "pr"
    static let kMPRemoteConfigCustomModuleLocationKey = "f"
    static let kMPRemoteConfigCustomModulePreferenceSettingsKey = "ps"
    static let kMPRemoteConfigCustomModuleReadKey = "k"
    static let kMPRemoteConfigCustomModuleDataTypeKey = "t"
    static let kMPRemoteConfigCustomModuleWriteKey = "n"
    static let kMPRemoteConfigCustomModuleDefaultKey = "d"
    static let kMPRemoteConfigCustomSettingsKey = "cs"
    static let kMPRemoteConfigSandboxModeKey = "dbg"
    static let kMPRemoteConfigSessionTimeoutKey = "stl"
    static let kMPRemoteConfigPushNotificationDictionaryKey = "pn"
    static let kMPRemoteConfigPushNotificationModeKey = "pnm"
    static let kMPRemoteConfigPushNotificationTypeKey = "rnt"
    static let kMPRemoteConfigLocationKey = "lct"
    static let kMPRemoteConfigLocationModeKey = "ltm"
    static let kMPRemoteConfigLocationAccuracyKey = "acc"
    static let kMPRemoteConfigLocationMinimumDistanceKey = "mdf"
    static let kMPRemoteConfigRampKey = "rp"
    static let kMPRemoteConfigTriggerKey = "tri"
    static let kMPRemoteConfigTriggerEventsKey = "evts"
    static let kMPRemoteConfigTriggerMessageTypesKey = "dts"
    static let kMPRemoteConfigUniqueIdentifierKey = "das"
    static let kMPRemoteConfigBracketKey = "bk"
    static let kMPRemoteConfigRestrictIDFA = "rdlat"
    static let kMPRemoteConfigAliasMaxWindow = "alias_max_window"
    static let kMPRemoteConfigAllowASR = "iasr"
    static let kMPRemoteConfigExcludeAnonymousUsersKey = "eau"
    static let kMPRemoteConfigDirectURLRouting = "dur"
    static let kMPRemoteConfigFlagsKey = "flags"
    static let kMPRemoteConfigAudienceAPIKey = "AudienceAPI"
    static let kMPRemoteConfigDataPlanningResults = "dpr"
    static let kMPRemoteConfigDataPlanning = "dtpn"
    static let kMPRemoteConfigDataPlanningBlock = "blok"
    static let kMPRemoteConfigDataPlanningBlockUnplannedEvents = "ev"
    static let kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes = "ea"
    static let kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes = "ua"
    static let kMPRemoteConfigDataPlanningBlockUnplannedIdentities = "id"
    static let kMPRemoteConfigDataPlanningDataPlanId = "dpid"
    static let kMPRemoteConfigDataPlanningDataPlanVersion = "dpvn"
    static let kMPRemoteConfigDataPlanningDataPlanError = "error"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValue = "vers"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueDoc = "version_document"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueDataPoints = "data_points"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueMatch = "match"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueType = "type"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueValidator = "validator"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueDefinition = "definition"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAdditionalProperties = "additionalProperties"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueUserAttributes = "user_attributes"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEvent = "custom_event"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEventType = "custom_event_type"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueEventName = "event_name"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueScreenView = "screen_view"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueScreenName = "screen_name"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueProductAction = "product_action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueUnknown = "unknown"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAddToCart = "add_to_cart"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromCart = "remove_from_cart"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCheckout = "checkout"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCheckoutOption = "checkout_option"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueClick = "click"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueViewDetail = "view_detail"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValuePurchase = "purchase"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueRefund = "refund"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAddToWishlist = "add_to_wishlist"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromWishlist = "remove_from_wish_list"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValuePromotionAction = "promotion_action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueProductImpressions = "product_impressions"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueCriteria = "criteria"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAction  = "action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionUnknown = "unknown"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionView = "view"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionClick = "click"
}

struct ConsentFiltering {
    static let kMPConsentKitFilter = "crvf"
    static let kMPConsentKitFilterIncludeOnMatch = "i"
    static let kMPConsentKitFilterItems = "v"
    static let kMPConsentKitFilterItemConsented = "c"
    static let kMPConsentKitFilterItemHash = "h"
    static let kMPConsentRegulationFilters = "reg"
    static let kMPConsentPurposeFilters = "pur"
    static let kMPConsentGDPRRegulationType = "1"
    static let kMPConsentCCPARegulationType = "2"
    static let kMPConsentCCPAPurposeName = "data_sale_opt_out"
}

struct Notifications {
    static let kMPCrashReportOccurredNotification = Notification.Name("MPCrashReportOccurredNotification")
    static let kMPConfigureExceptionHandlingNotification = Notification.Name("MPConfigureExceptionHandlingNotification")
    static let kMPUserNotificationDictionaryKey = Notification.Name("MPUserNotificationDictionaryKey")
    static let kMPUserNotificationActionKey = Notification.Name("MPUserNotificationActionKey")
    static let kMPRemoteNotificationDeviceTokenNotification = Notification.Name("MPRemoteNotificationDeviceTokenNotification")
    static let kMPRemoteNotificationDeviceTokenKey = Notification.Name("MPRemoteNotificationDeviceTokenKey")
    static let kMPRemoteNotificationOldDeviceTokenKey = Notification.Name("MPRemoteNotificationOldDeviceTokenKey")
}

struct Device {
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

struct Miscellaneous {
    static let kMPFirstSeenUser = "fsu"
    static let kMPLastSeenUser = "lsu"
    static let kMPAppInitialLaunchTimeKey = "ict"
    static let kMPHTTPETagHeaderKey = "ETag"
    static let kMPConfigProvisionedTimestampKey = "ConfigProvisionedTimestamp"
    static let kMPConfigMaxAgeHeaderKey = "ConfigMaxAgeHeader"
    static let kMPConfigParameters = "ConfigParameters"
    static let kMPLastIdentifiedDate = "last_date_used"
    static let MPSideloadedKitsCountUserDefaultsKey = "MPSideloadedKitsCountUserDefaultsKey"
    static let kMPLastUploadSettingsUserDefaultsKey = "lastUploadSettings"
    static let CONFIG_REQUESTS_DEFAULT_EXPIRATION_AGE = 5.0*60
    static let CONFIG_REQUESTS_MAX_EXPIRATION_AGE = 60*60*24.0
    static let kMPDeviceTokenTypeKey = "tot"
    static let kMPATT = "atts"
    static let kMPATTTimestamp = "attt"
    static let kMPDeviceCydiaJailbrokenKey = "cydia"

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
