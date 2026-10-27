#import "MPIConstants.h"

// mParticle SDK Version
NSString *const kMParticleSDKVersion = @"9.7.4";

// Message Type (dt)
NSString *const kMPMessageTypeKey = @"dt";

// Request Header Keys
NSString *const kMPmParticleSDKVersionKey = @"sdk";
NSString *const kMPApplicationKey = @"a";

// Device Information Keys
NSString *const kMPDeviceCydiaJailbrokenKey = @"cydia";

// Message Keys
NSString *const kMPMessagesKey = @"msgs";
NSString *const kMPMessageIdKey = @"id";
NSString *const kMPTimestampKey = @"ct";
NSString *const kMPSessionIdKey = @"sid";
NSString *const kMPSessionStartTimestamp = @"sct";
NSString *const kMPEventStartTimestamp = @"est";
NSString *const kMPEventLength = @"el";
NSString *const kMPEventNameKey = @"n";
NSString *const kMPEventTypeKey = @"et";
NSString *const kMPAttributesKey = @"attrs";
NSString *const kMPUserAttributeKey = @"ua";
NSString *const kMPUserIdentityArrayKey = @"ui";
NSString *const kMPUserIdentityIdKey = @"i";
NSString *const kMPUserIdentityTypeKey = @"n";
NSString *const kMPLeaveBreadcrumbsKey = @"l";
NSString *const kMPOptOutKey = @"oo";
NSString *const kMPForwardStatsRecord = @"fsr";
NSString *const kMPEventCustomFlags = @"flags";
NSString *const kMPContextKey = @"ctx";
NSString *const kMPDataPlanKey = @"dpln";
NSString *const kMPDataPlanIdKey = @"id";
NSString *const kMPDataPlanVersionKey = @"v";

// Consent
NSString *const kMPConsentState = @"con";

// GDPR Consent
NSString *const kMPConsentStateGDPR = @"gdpr";

// CCPA Consent
NSString *const kMPConsentStateCCPA = @"ccpa";
NSString *const kMPConsentStateCCPAPurpose = @"data_sale_opt_out";

NSString *const kMPConsentStateConsented = @"c";
NSString *const kMPConsentStateDocument = @"d";
NSString *const kMPConsentStateTimestamp = @"ts";
NSString *const kMPConsentStateLocation = @"l";
NSString *const kMPConsentStateHardwareId = @"h";

// Consent serialization
NSString *const kMPConsentStateKey = @"consent_state";
NSString *const kMPConsentDeviceStateKey = @"device_consent_state";

// Consent filtering
NSString *const kMPConsentGDPRRegulationType = @"1";
NSString *const kMPConsentCCPARegulationType = @"2";
NSString *const kMPConsentCCPAPurposeName = @"data_sale_opt_out";

// Push Notifications
NSString *const kMPDeviceTokenKey = @"to";
NSString *const kMPPushNotificationStateBackground = @"background";
NSString *const kMPPushNotificationStateForeground = @"foreground";

// Assorted Keys
NSString *const kMPOptOutStatus = @"s";
NSString *const kMPATTTimestamp = @"attt";
NSString *const kMPCrashingSeverity = @"s";
NSString *const kMPCrashWasHandled = @"eh";
NSString *const kMPErrorMessage = @"m";
NSString *const kMPStackTrace = @"st";
NSString *const kMPPLCrashReport = @"plc";
NSString *const kMPNullUserAttributeString = @"null";
NSString *const kMPSessionTimeoutKey = @"stl";
NSString *const kMPUploadIntervalKey = @"uitl";
NSString *const kMPLifeTimeValueKey = @"ltv";
NSString *const kMPHTTPMethodPost = @"POST";
NSString *const kMPHTTPMethodGet = @"GET";
NSString *const kMPEventCounterKey = @"en";
NSString *const kMPAppFirstSeenInstallationKey = @"fi";
NSString *const kMPSynchedUserAttributesKey = @"SynchedUserAttributes";
NSString *const kMPIsEphemeralKey = @"is_ephemeral";
NSString *const kMPLastIdentifiedDate = @"last_date_used";
NSString *const kMPDeviceApplicationStampKey = @"das";
NSString *const kMPConfigProvisionedTimestampKey = @"ConfigProvisionedTimestamp";
NSString *const kMPConfigMaxAgeHeaderKey = @"ConfigMaxAgeHeader";
NSString *const kMPFirstSeenUser = @"fsu";
NSString *const kMPLastSeenUser = @"lsu";

// Remote configuration
NSString *const kMPRemoteConfigExceptionHandlingModeKey = @"cue";
NSString *const kMPRemoteConfigExceptionHandlingModeForce = @"forcecatch";
NSString *const kMPRemoteConfigKitsKey = @"eks";
NSString *const kMPRemoteConfigKitConfigurationKey = @"as";
NSString *const kMPRemoteConfigKitHashesKey = @"hs";
NSString *const kMPRemoteConfigConsumerInfoKey = @"ci";
NSString *const kMPRemoteConfigCookiesKey = @"ck";
NSString *const kMPCKContent = @"c";
NSString *const kMPCKDomain = @"d";
NSString *const kMPCKExpiration = @"e";
NSString *const kMPRemoteConfigMPIDKey = @"mpid";
NSString *const kMPRemoteConfigCustomModuleSettingsKey = @"cms";
NSString *const kMPRemoteConfigCustomModuleIdKey = @"id";
NSString *const kMPRemoteConfigCustomModulePreferencesKey = @"pr";
NSString *const kMPRemoteConfigCustomModuleLocationKey = @"f";
NSString *const kMPRemoteConfigCustomModulePreferenceSettingsKey = @"ps";
NSString *const kMPRemoteConfigCustomModuleReadKey = @"k";
NSString *const kMPRemoteConfigCustomModuleDataTypeKey = @"t";
NSString *const kMPRemoteConfigCustomModuleWriteKey = @"n";
NSString *const kMPRemoteConfigCustomModuleDefaultKey = @"d";
NSString *const kMPRemoteConfigSessionTimeoutKey = @"stl";
NSString *const kMPRemoteConfigRampKey = @"rp";
NSString *const kMPRemoteConfigTriggerKey = @"tri";
NSString *const kMPRemoteConfigUniqueIdentifierKey = @"das";
NSString *const kMPRemoteConfigDataPlanning = @"dtpn";
NSString *const kMPRemoteConfigDataPlanningBlock = @"blok";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedEvents = @"ev";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes = @"ea";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes = @"ua";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedIdentities = @"id";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValue = @"vers";

// Notifications
NSString *const kMPRemoteNotificationDeviceTokenKey = @"MPRemoteNotificationDeviceTokenKey";

// Config.plist keys
NSString *const kMPConfigPlist = @"MParticleConfig";
NSString *const kMPConfigCustomUserAgent = @"custom_user_agent";
NSString *const kMPConfigCollectUserAgent = @"collect_user_agent";
NSString *const kMPConfigTrackNotifications = @"track_notifications";
NSString *const kMPConfigSessionTimeout = @"session_timeout";
NSString *const kMPConfigUploadInterval = @"upload_interval";

// Kits
NSString *const MPIntegrationAttributesKey = @"ia";

// mParticle Javascript SDK paths
NSString *const kMParticleWebViewPathLogEvent = @"logEvent";
NSString *const kMParticleWebViewPathSetUserTag = @"setUserTag";
NSString *const kMParticleWebViewPathRemoveUserTag = @"removeUserTag";
NSString *const kMParticleWebViewPathSetUserAttribute = @"setUserAttribute";
NSString *const kMParticleWebViewPathRemoveUserAttribute = @"removeUserAttribute";
NSString *const kMParticleWebViewPathSetSessionAttribute = @"setSessionAttribute";
NSString *const kMParticleWebViewPathIdentify = @"identify";
NSString *const kMParticleWebViewPathLogout = @"logout";
NSString *const kMParticleWebViewPathLogin = @"login";
NSString *const kMParticleWebViewPathModify = @"modify";

// Message type strings
NSString *const kMPMessageTypeStringUnknown = @"unknown";
NSString *const kMPMessageTypeStringSessionStart = @"ss";
NSString *const kMPMessageTypeStringSessionEnd = @"se";
NSString *const kMPMessageTypeStringScreenView = @"v";
NSString *const kMPMessageTypeStringEvent = @"e";
NSString *const kMPMessageTypeStringCrashReport = @"x";
NSString *const kMPMessageTypeStringOptOut = @"o";
NSString *const kMPMessageTypeStringFirstRun = @"fr";
NSString *const kMPMessageTypeStringPreAttribution = @"unknown";
NSString *const kMPMessageTypeStringPushRegistration = @"pr";
NSString *const kMPMessageTypeStringAppStateTransition = @"ast";
NSString *const kMPMessageTypeStringPushNotification = @"pm";
NSString *const kMPMessageTypeStringNetworkPerformance = @"npe";
NSString *const kMPMessageTypeStringBreadcrumb = @"bc";
NSString *const kMPMessageTypeStringProfile = @"pro";
NSString *const kMPMessageTypeStringPushNotificationInteraction = @"pre";
NSString *const kMPMessageTypeStringCommerceEvent = @"cm";
NSString *const kMPMessageTypeStringUserAttributeChange = @"uac";
NSString *const kMPMessageTypeStringUserIdentityChange = @"uic";
NSString *const kMPMessageTypeStringMedia = @"media";

// Event type strings
NSString *const kMPEventTypeStringNavigation = @"Navigation";
NSString *const kMPEventTypeStringLocation = @"Location";
NSString *const kMPEventTypeStringSearch = @"Search";
NSString *const kMPEventTypeStringTransaction = @"Transaction";
NSString *const kMPEventTypeStringUserContent = @"UserContent";
NSString *const kMPEventTypeStringUserPreference = @"UserPreference";
NSString *const kMPEventTypeStringSocial = @"Social";
NSString *const kMPEventTypeStringOther = @"Other";
NSString *const kMPEventTypeStringMedia = @"Media";
NSString *const kMPEventTypeStringProductAddToCart = @"ProductAddToCart";
NSString *const kMPEventTypeStringProductRemoveFromCart = @"ProductRemoveFromCart";
NSString *const kMPEventTypeStringProductCheckout = @"ProductCheckout";
NSString *const kMPEventTypeStringProductCheckoutOption = @"ProductCheckoutOption";
NSString *const kMPEventTypeStringProductClick = @"ProductClick";
NSString *const kMPEventTypeStringProductViewDetail = @"ProductViewDetail";
NSString *const kMPEventTypeStringProductPurchase = @"ProductPurchase";
NSString *const kMPEventTypeStringProductRefund = @"ProductRefund";
NSString *const kMPEventTypeStringPromotionView = @"PromotionView";
NSString *const kMPEventTypeStringPromotionClick = @"PromotionClick";
NSString *const kMPEventTypeStringProductAddToWishlist = @"ProductAddToWishlist";
NSString *const kMPEventTypeStringProductRemoveFromWishlist = @"ProductRemoveFromWishlist";
NSString *const kMPEventTypeStringProductImpression = @"ProductImpression";

// Device
NSString * const kMPDeviceInformationKey = @"di";
NSString * const kMPDeviceBrandKey = @"b";
NSString * const kMPDeviceProductKey = @"p";
NSString * const kMPDeviceNameKey = @"dn";
NSString * const kMPDeviceAdvertiserIdKey = @"aid";
NSString * const kMPDeviceAppVendorIdKey = @"vid";
NSString * const kMPDeviceBuildIdKey = @"bid";
NSString * const kMPDeviceManufacturerKey = @"dma";
NSString * const kMPDevicePlatformKey = @"dp";
NSString * const kMPDeviceOSKey = @"dosv";
NSString * const kMPDeviceModelKey = @"dmdl";
NSString * const kMPScreenHeightKey = @"dsh";
NSString * const kMPScreenWidthKey = @"dsw";
NSString * const kMPDeviceLocaleCountryKey = @"dlc";
NSString * const kMPDeviceLocaleLanguageKey = @"dll";
NSString * const kMPTimezoneOffsetKey = @"tz";
NSString * const kMPTimezoneDescriptionKey = @"tzn";
NSString * const kMPDeviceJailbrokenKey = @"jb";
NSString * const kMPDeviceArchitectureKey = @"arc";
NSString * const kMPDeviceIsTabletKey = @"it";
NSString * const kMPDeviceLimitAdTrackingKey = @"lat";
NSString * const kMPDeviceIsDaylightSavingTime = @"idst";

//
// Primitive data type constants
//
const NSTimeInterval DEFAULT_SESSION_TIMEOUT = 60.0;

// Interval between uploads if not specified
const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL = 60.0;

const NSTimeInterval DEFAULT_UPLOAD_INTERVAL = 600.0;

// Attributes limits
const NSInteger LIMIT_ATTR_KEY_LENGTH = 256;
const NSInteger LIMIT_ATTR_VALUE_LENGTH = 4096;

// Size limits
const NSInteger MAX_BYTES_PER_EVENT = 100*1024;
const NSInteger MAX_BYTES_PER_BATCH = 2 * MAX_BYTES_PER_EVENT;
const NSInteger MAX_BYTES_PER_EVENT_CRASH = 1000*1024;
const NSInteger MAX_BYTES_PER_BATCH_CRASH = 2 * MAX_BYTES_PER_EVENT_CRASH;
const NSInteger MAX_EVENTS_PER_BATCH = 100;
