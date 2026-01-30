//
//  MPConstants.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/3/24.
//
// NOTE: This will temporarily duplicate values from MPIConstants.h to prevent
//       the need to make all our internal constants public during porting
//

// NOTE: I kept the same naming here for clarity, but we should rename these
//       after we remove them from the MPIConstants.h file

let kMParticleSDKVersion = "8.41.1"

enum PushNotifications {
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

enum RemoteConfig {
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
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueAction = "action"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionUnknown = "unknown"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionView = "view"
    static let kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionClick = "click"
}

enum Notifications {
    static let kMPCrashReportOccurredNotification = Notification.Name("MPCrashReportOccurredNotification")
    static let kMPConfigureExceptionHandlingNotification = Notification.Name("MPConfigureExceptionHandlingNotification")
    static let kMPUserNotificationDictionaryKey = Notification.Name("MPUserNotificationDictionaryKey")
    static let kMPUserNotificationActionKey = Notification.Name("MPUserNotificationActionKey")
    static let kMPRemoteNotificationDeviceTokenNotification = Notification.Name("MPRemoteNotificationDeviceTokenNotification")
    static let kMPRemoteNotificationDeviceTokenKey = Notification.Name("MPRemoteNotificationDeviceTokenKey")
    static let kMPRemoteNotificationOldDeviceTokenKey = Notification.Name("MPRemoteNotificationOldDeviceTokenKey")
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
