#import "MPIConstants.h"

// mParticle SDK Version
NSString *const kMParticleSDKVersion = @"7.3.5";

// Message Type (dt)
NSString *const kMPMessageTypeKey = @"dt";
NSString *const kMPMessageTypeRequestHeader = @"h";
NSString *const kMPMessageTypeResponseHeader = @"rh";
NSString *const kMPMessageTypeConfig = @"ac";
NSString *const kMPMessageTypeNetworkPerformance = @"npe";
NSString *const kMPMessageTypeLeaveBreadcrumbs = @"bc";

// Request Header Keys
NSString *const kMPmParticleSDKVersionKey = @"sdk";
NSString *const kMPApplicationKey = @"a";

// Device Information Keys
NSString *const kMPDeviceCydiaJailbrokenKey = @"cydia";
NSString *const kMPDeviceSupportedPushNotificationTypesKey = @"tt";

// Launch Keys
NSString *const kMPLaunchSourceKey = @"src";
NSString *const kMPLaunchURLKey = @"lr";
NSString *const kMPLaunchParametersKey = @"lpr";
NSString *const kMPLaunchSessionFinalizedKey = @"sf";
NSString *const kMPLaunchNumberOfSessionInterruptionsKey = @"nsi";

// Message Keys
NSString *const kMPMessagesKey = @"msgs";
NSString *const kMPMessageIdKey = @"id";
NSString *const kMPMessageUserIdKey = @"mpid";
NSString *const kMPTimestampKey = @"ct";
NSString *const kMPSessionIdKey = @"sid";
NSString *const kMPSessionStartTimestamp = @"sct";
NSString *const kMPEventStartTimestamp = @"est";
NSString *const kMPEventLength = @"el";
NSString *const kMPEventNameKey = @"n";
NSString *const kMPEventTypeKey = @"et";
NSString *const kMPEventLengthKey = @"el";
NSString *const kMPAttributesKey = @"attrs";
NSString *const kMPLocationKey = @"lc";
NSString *const kMPUserAttributeKey = @"ua";
NSString *const kMPUserAttributeDeletedKey = @"uad";
NSString *const kMPEventTypePageView = @"pageview";
NSString *const kMPUserIdentityArrayKey = @"ui";
NSString *const kMPUserIdentityIdKey = @"i";
NSString *const kMPUserIdentityTypeKey = @"n";
NSString *const kMPUserIdentitySharedGroupIdentifier = @"sgi";
NSString *const kMPAppStateTransitionType = @"t";
NSString *const kMPEventTagsKey = @"tags";
NSString *const kMPLeaveBreadcrumbsKey = @"l";
NSString *const kMPOptOutKey = @"oo";
NSString *const kMPDateUserIdentityWasFirstSet = @"dfs";
NSString *const kMPIsFirstTimeUserIdentityHasBeenSet = @"f";
NSString *const kMPRemoteNotificationContentIdHistoryKey = @"cntid";
NSString *const kMPRemoteNotificationTimestampHistoryKey = @"ts";
NSString *const kMPForwardStatsRecord = @"fsr";

// Consent
NSString *const kMPConsentState = @"con";

// GDPR Consent
NSString *const kMPConsentStateGDPR = @"gdpr";

NSString *const kMPConsentStateGDPRConsented = @"c";
NSString *const kMPConsentStateGDPRDocument = @"d";
NSString *const kMPConsentStateGDPRTimestamp = @"ts";
NSString *const kMPConsentStateGDPRLocation = @"l";
NSString *const kMPConsentStateGDPRHardwareId = @"h";

// Consent serialization
NSString *const kMPConsentStateKey = @"consent_state";
NSString *const kMPConsentStateGDPRKey = @"gdpr";
NSString *const kMPConsentStateGDPRConsentedKey = @"consented";
NSString *const kMPConsentStateGDPRDocumentKey = @"document";
NSString *const kMPConsentStateGDPRTimestampKey = @"timestamp";
NSString *const kMPConsentStateGDPRLocationKey = @"location";
NSString *const kMPConsentStateGDPRHardwareIdKey = @"hardware_id";

// Push Notifications
NSString *const kMPDeviceTokenKey = @"to";
NSString *const kMPPushStatusKey = @"r";
NSString *const kMPPushMessageTypeKey = @"t";
NSString *const kMPPushMessageReceived = @"received";
NSString *const kMPPushMessageAction = @"action";
NSString *const kMPPushMessageSent = @"sent";
NSString *const kMPPushMessageProviderKey = @"n";
NSString *const kMPPushMessageProviderValue = @"apn";
NSString *const kMPPushMessagePayloadKey = @"pay";
NSString *const kMPPushNotificationStateKey = @"as";
NSString *const kMPPushNotificationStateNotRunning = @"not_running";
NSString *const kMPPushNotificationStateBackground = @"background";
NSString *const kMPPushNotificationStateForeground = @"foreground";
NSString *const kMPPushNotificationActionIdentifierKey = @"aid";
NSString *const kMPPushNotificationBehaviorKey = @"bhv";
NSString *const kMPPushNotificationActionTileKey = @"an";
NSString *const kMPPushNotificationCategoryIdentifierKey = @"acid";

// Assorted Keys
NSString *const kMPSessionLengthKey = @"sl";
NSString *const kMPSessionTotalLengthKey = @"slx";
NSString *const kMPOptOutStatus = @"s";
NSString *const kMPAlwaysTryToCollectIDFA = @"alwaysTryToCollectIDFA";
NSString *const kMPCrashingSeverity = @"s";
NSString *const kMPCrashingClass = @"c";
NSString *const kMPCrashWasHandled = @"eh";
NSString *const kMPErrorMessage = @"m";
NSString *const kMPStackTrace = @"st";
NSString *const kMPCrashSignal = @"csg";
NSString *const kMPTopmostContext = @"tc";
NSString *const kMPPLCrashReport = @"plc";
NSString *const kMPCrashExceptionKey = @"MPCrashExceptionKey";
NSString *const kMPNullUserAttributeString = @"null";
NSString *const kMPSessionTimeoutKey = @"stl";
NSString *const kMPUploadIntervalKey = @"uitl";
NSString *const kMPPreviousSessionLengthKey = @"psl";
NSString *const kMPLifeTimeValueKey = @"ltv";
NSString *const kMPIncreasedLifeTimeValueKey = @"iltv";
NSString *const kMPPreviousSessionStateFileName = @"PreviousSessionState.dic";
NSString *const kMPHTTPMethodPost = @"POST";
NSString *const kMPHTTPMethodGet = @"GET";
NSString *const kMPPreviousSessionIdKey = @"pid";
NSString *const kMPEventCounterKey = @"en";
NSString *const kMPProfileChangeTypeKey = @"t";
NSString *const kMPProfileChangeCurrentKey = @"n";
NSString *const kMPProfileChangePreviousKey = @"o";
NSString *const kMPPresentedViewControllerKey = @"vc";
NSString *const kMPMainThreadKey = @"mt";
NSString *const kMPPreviousSessionStartKey = @"pss";
NSString *const kMPAppFirstSeenInstallationKey = @"fi";
NSString *const kMPResponseURLKey = @"u";
NSString *const kMPResponseMethodKey = @"m";
NSString *const kMPResponsePOSTDataKey = @"d";
NSString *const kMPHTTPHeadersKey = @"h";
NSString *const kMPHTTPAcceptEncodingKey = @"Accept-Encoding";
NSString *const kMPDeviceTokenTypeKey = @"tot";
NSString *const kMPDeviceTokenTypeDevelopment = @"appleSandbox";
NSString *const kMPDeviceTokenTypeProduction = @"appleProduction";
NSString *const kMPHTTPETagHeaderKey = @"ETag";
NSString *const kMResponseConfigurationKey = @"responseConfiguration";
NSString *const kMResponseConfigurationMigrationKey = @"responseConfigurationMigrated";
NSString *const kMPAppSearchAdsAttributionKey = @"asaa";
NSString *const kMPSynchedUserAttributesKey = @"SynchedUserAttributes";
NSString *const kMPSynchedUserIdentitiesKey = @"SynchedUserIdentities";
NSString *const kMPSessionUserIdsKey = @"smpids";
NSString *const kMPIsEphemeralKey = @"is_ephemeral";
NSString *const kMPLastIdentifiedDate = @"last_date_used";
NSString *const kMPDeviceApplicationStampKey = @"das";
NSString *const kMPDeviceApplicationStampStorageKey = @"dast";
NSString *const kMPLastConfigReceivedKey = @"LastConfigReceived";
NSString *const kMPUserAgentSystemVersionUserDefaultsKey = @"UserAgentSystemVersion";
NSString *const kMPUserAgentValueUserDefaultsKey = @"UserAgentValue";

// Remote configuration
NSString *const kMPRemoteConfigExceptionHandlingModeKey = @"cue";
NSString *const kMPRemoteConfigExceptionHandlingModeAppDefined = @"appdefined";
NSString *const kMPRemoteConfigExceptionHandlingModeForce = @"forcecatch";
NSString *const kMPRemoteConfigExceptionHandlingModeIgnore = @"forceignore";
NSString *const kMPRemoteConfigAppDefined = @"appdefined";
NSString *const kMPRemoteConfigForceTrue = @"forcetrue";
NSString *const kMPRemoteConfigForceFalse = @"forcefalse";
NSString *const kMPRemoteConfigKitsKey = @"eks";
NSString *const kMPRemoteConfigConsumerInfoKey = @"ci";
NSString *const kMPRemoteConfigCookiesKey = @"ck";
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
NSString *const kMPRemoteConfigCustomSettingsKey = @"cs";
NSString *const kMPRemoteConfigSandboxModeKey = @"dbg";
NSString *const kMPRemoteConfigSessionTimeoutKey = @"stl";
NSString *const kMPRemoteConfigPushNotificationDictionaryKey = @"pn";
NSString *const kMPRemoteConfigPushNotificationModeKey = @"pnm";
NSString *const kMPRemoteConfigPushNotificationTypeKey = @"rnt";
NSString *const kMPRemoteConfigLocationKey = @"lct";
NSString *const kMPRemoteConfigLocationModeKey = @"ltm";
NSString *const kMPRemoteConfigLocationAccuracyKey = @"acc";
NSString *const kMPRemoteConfigLocationMinimumDistanceKey = @"mdf";
NSString *const kMPRemoteConfigRampKey = @"rp";
NSString *const kMPRemoteConfigTriggerKey = @"tri";
NSString *const kMPRemoteConfigTriggerEventsKey = @"evts";
NSString *const kMPRemoteConfigTriggerMessageTypesKey = @"dts";
NSString *const kMPRemoteConfigUniqueIdentifierKey = @"das";
NSString *const kMPRemoteConfigBracketKey = @"bk";
NSString *const kMPRemoteConfigRestrictIDFA = @"rdlat";

// Notifications
NSString *const kMPCrashReportOccurredNotification = @"MPCrashReportOccurredNotification";
NSString *const kMPConfigureExceptionHandlingNotification = @"MPConfigureExceptionHandlingNotification";
NSString *const kMPRemoteNotificationReceivedNotification = @"MPRemoteNotificationReceivedNotification";
NSString *const kMPUserNotificationDictionaryKey = @"MPUserNotificationDictionaryKey";
NSString *const kMPUserNotificationActionKey = @"MPUserNotificationActionKey";
NSString *const kMPRemoteNotificationDeviceTokenNotification = @"MPRemoteNotificationDeviceTokenNotification";
NSString *const kMPRemoteNotificationDeviceTokenKey = @"MPRemoteNotificationDeviceTokenKey";
NSString *const kMPRemoteNotificationOldDeviceTokenKey = @"MPRemoteNotificationOldDeviceTokenKey";
NSString *const kMPLocalNotificationReceivedNotification = @"MPLocalNotificationReceivedNotification";
NSString *const kMPUserNotificationRunningModeKey = @"MPUserNotificationRunningModeKey";

// Config.plist keys
NSString *const kMPConfigPlist = @"MParticleConfig";
NSString *const kMPConfigApiKey = @"api_key";
NSString *const kMPConfigSecret = @"api_secret";
NSString *const kMPConfigSharedGroupID = @"shared_group_id";
NSString *const kMPConfigCustomUserAgent = @"custom_user_agent";
NSString *const kMPConfigCollectUserAgent = @"collect_user_agent";
NSString *const kMPConfigSessionTimeout = @"session_timeout";
NSString *const kMPConfigUploadInterval = @"upload_interval";
NSString *const kMPConfigEnableSSL = @"enable_secure_transport";
NSString *const kMPConfigEnableCrashReporting = @"enable_crash_reporting";
NSString *const kMPConfigLocationTracking = @"enable_location_tracking";
NSString *const kMPConfigLocationAccuracy = @"location_tracking_accuracy";
NSString *const kMPConfigLocationDistanceFilter = @"location_tracking_distance_filter";

// Data connection path/status
NSString *const kDataConnectionOffline = @"offline";
NSString *const kDataConnectionMobile = @"mobile";
NSString *const kDataConnectionWifi = @"wifi";

// Application State Transition
NSString *const kMPASTInitKey = @"app_init";
NSString *const kMPASTExitKey = @"app_exit";
NSString *const kMPASTBackgroundKey = @"app_back";
NSString *const kMPASTForegroundKey = @"app_fore";
NSString *const kMPASTIsFirstRunKey = @"ifr";
NSString *const kMPASTIsUpgradeKey = @"iu";
NSString *const kMPASTPreviousSessionSuccessfullyClosedKey = @"sc";

// Network performance
NSString *const kMPNetworkPerformanceMeasurementNotification = @"MPNetworkPerformanceMeasurement";
NSString *const kMPNetworkPerformanceKey = @"MPNetworkPerformance";

// Kits
NSString *const MPKitAttributeJailbrokenKey = @"jailbroken";
NSString *const MPIntegrationAttributesKey = @"ia";

// mParticle Javascript SDK paths
NSString *const kMParticleWebViewSdkScheme = @"mp-sdk";
NSString *const kMParticleWebViewPathLogEvent = @"logEvent";
NSString *const kMParticleWebViewPathSetUserIdentity = @"setUserIdentity";
NSString *const kMParticleWebViewPathRemoveUserIdentity = @"removeUserIdentity";
NSString *const kMParticleWebViewPathSetUserTag = @"setUserTag";
NSString *const kMParticleWebViewPathRemoveUserTag = @"removeUserTag";
NSString *const kMParticleWebViewPathSetUserAttribute = @"setUserAttribute";
NSString *const kMParticleWebViewPathRemoveUserAttribute = @"removeUserAttribute";
NSString *const kMParticleWebViewPathSetSessionAttribute = @"setSessionAttribute";
NSString *const kMParticleWebViewPathIdentify = @"identify";
NSString *const kMParticleWebViewPathLogout = @"logout";
NSString *const kMParticleWebViewPathLogin = @"login";
NSString *const kMParticleWebViewPathModify = @"modify";

//
// Primitive data type constants
//
const NSTimeInterval MINIMUM_SESSION_TIMEOUT = 1.0;

const NSTimeInterval MAXIMUM_SESSION_TIMEOUT =
    #if TARGET_OS_TV == 1
        12.0;
    #else
        120.0;
    #endif

const NSTimeInterval DEFAULT_SESSION_TIMEOUT =
    #if TARGET_OS_TV == 1
        6.0;
    #else
        60.0;
    #endif

const NSTimeInterval TWENTY_FOUR_HOURS = 86400; // database clean up interval
const NSTimeInterval SEVEN_DAYS = 60 * 60 * 24 * 7; // Old messages purged on migration = 60 seconds * 60 minutes * 24 hours * 7 days
const NSTimeInterval NINETY_DAYS = 60 * 60 * 24 * 90; // Old messages purge interval = 60 seconds * 60 minutes * 24 hours * 90 days

// Interval between uploads if not specified
const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL =
    #if TARGET_OS_TV == 1
        2.0;
    #else
        20.0;
    #endif

const NSTimeInterval DEFAULT_UPLOAD_INTERVAL =
    #if TARGET_OS_TV == 1
        6.0;
    #else
        600.0;
    #endif

// How long to block config requests after a successful response.
const NSTimeInterval DEBUG_CONFIG_REQUESTS_QUIET_INTERVAL = 60.0;
const NSTimeInterval CONFIG_REQUESTS_QUIET_INTERVAL = 10.0*60;

// Attributes limits
const NSInteger LIMIT_ATTR_COUNT = 100;
const NSInteger LIMIT_ATTR_LENGTH = 256;
const NSInteger LIMIT_NAME = 256;
const NSInteger LIMIT_USER_ATTR_LENGTH = 4096;
const NSInteger MAX_USER_ATTR_LIST_SIZE = 1000;
const NSInteger MAX_USER_ATTR_LIST_ENTRY_LENGTH = 512;

// Consent limits
const NSInteger MAX_GDPR_CONSENT_PURPOSES = 100;
