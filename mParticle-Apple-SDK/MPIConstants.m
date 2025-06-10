#import "MPIConstants.h"

// mParticle SDK Version
NSString *const kMParticleSDKVersion = @"8.32.0";

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
NSString *const kMPConsentStateGDPRKey = @"gdpr";
NSString *const kMPConsentStateConsentedKey = @"consented";
NSString *const kMPConsentStateDocumentKey = @"document";
NSString *const kMPConsentStateTimestampKey = @"timestamp";
NSString *const kMPConsentStateLocationKey = @"location";
NSString *const kMPConsentStateHardwareIdKey = @"hardware_id";

// Consent filtering
NSString *const kMPConsentKitFilter = @"crvf";
NSString *const kMPConsentKitFilterIncludeOnMatch = @"i";
NSString *const kMPConsentKitFilterItems = @"v";
NSString *const kMPConsentKitFilterItemConsented = @"c";
NSString *const kMPConsentKitFilterItemHash = @"h";
NSString *const kMPConsentRegulationFilters = @"reg";
NSString *const kMPConsentPurposeFilters = @"pur";
NSString *const kMPConsentGDPRRegulationType = @"1";
NSString *const kMPConsentCCPARegulationType = @"2";
NSString *const kMPConsentCCPAPurposeName = @"data_sale_opt_out";

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
NSString *const kMPPushNotificationActionTitleKey = @"an";
NSString *const kMPPushNotificationCategoryIdentifierKey = @"acid";

// Assorted Keys
NSString *const kMPSessionLengthKey = @"sl";
NSString *const kMPSessionTotalLengthKey = @"slx";
NSString *const kMPOptOutStatus = @"s";
NSString *const kMPATT = @"atts";
NSString *const kMPATTTimestamp = @"attt";
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
NSString *const kMPHTTPCacheControlHeaderKey = @"Cache-Control";
NSString *const kMPHTTPAgeHeaderKey = @"Age";
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
NSString *const kMPConfigProvisionedTimestampKey = @"ConfigProvisionedTimestamp";
NSString *const kMPConfigMaxAgeHeaderKey = @"ConfigMaxAgeHeader";
NSString *const kMPConfigParameters = @"ConfigParameters";
NSString *const kMPUserAgentSystemVersionUserDefaultsKey = @"UserAgentSystemVersion";
NSString *const kMPUserAgentValueUserDefaultsKey = @"UserAgentValue";
NSString *const kMPFirstSeenUser = @"fsu";
NSString *const kMPLastSeenUser = @"lsu";
NSString *const kMPAppForePreviousForegroundTime = @"pft";
NSString *const kMPLastUploadSettingsUserDefaultsKey = @"lastUploadSettings";

// Remote configuration
NSString *const kMPRemoteConfigExceptionHandlingModeKey = @"cue";
NSString *const kMPRemoteConfigExceptionHandlingModeAppDefined = @"appdefined";
NSString *const kMPRemoteConfigFlagsKey = @"flags";
NSString *const kMPRemoteConfigAudienceAPIKey = @"AudienceAPI";
NSString *const kMPRemoteConfigExceptionHandlingModeForce = @"forcecatch";
NSString *const kMPRemoteConfigExceptionHandlingModeIgnore = @"forceignore";
NSString *const kMPRemoteConfigCrashMaxPLReportLength = @"crml";
NSString *const kMPRemoteConfigAppDefined = @"appdefined";
NSString *const kMPRemoteConfigForceTrue = @"forcetrue";
NSString *const kMPRemoteConfigForceFalse = @"forcefalse";
NSString *const kMPRemoteConfigKitsKey = @"eks";
NSString *const kMPRemoteConfigKitHashesKey = @"hs";
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
NSString *const kMPRemoteConfigAliasMaxWindow = @"alias_max_window";
NSString *const kMPRemoteConfigAllowASR = @"iasr";
NSString *const kMPRemoteConfigExcludeAnonymousUsersKey = @"eau";
NSString *const kMPRemoteConfigDirectURLRouting = @"dur";
NSString *const kMPRemoteConfigDataPlanningResults = @"dpr";
NSString *const kMPRemoteConfigDataPlanning = @"dtpn";
NSString *const kMPRemoteConfigDataPlanningBlock = @"blok";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedEvents = @"ev";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes = @"ea";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes = @"ua";
NSString *const kMPRemoteConfigDataPlanningBlockUnplannedIdentities = @"id";
NSString *const kMPRemoteConfigDataPlanningDataPlanId = @"dpid";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersion = @"dpvn";
NSString *const kMPRemoteConfigDataPlanningDataPlanError = @"error";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValue = @"vers";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueDoc = @"version_document";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueDataPoints = @"data_points";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueMatch = @"match";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueType = @"type";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueValidator = @"validator";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueDefinition = @"definition";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueAdditionalProperties = @"additionalProperties";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueUserAttributes = @"user_attributes";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEvent = @"custom_event";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEventType = @"custom_event_type";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueEventName = @"event_name";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueScreenView = @"screen_view";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueScreenName = @"screen_name";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueProductAction = @"product_action";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueUnknown = @"unknown";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueAddToCart = @"add_to_cart";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromCart = @"remove_from_cart";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueCheckout = @"checkout";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueCheckoutOption = @"checkout_option";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueClick = @"click";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueViewDetail = @"view_detail";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValuePurchase = @"purchase";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueRefund = @"refund";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueAddToWishlist = @"add_to_wishlist";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromWishlist = @"remove_from_wish_list";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValuePromotionAction = @"promotion_action";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueProductImpressions = @"product_impressions";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueCriteria = @"criteria";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueAction  = @"action";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionUnknown = @"unknown";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionView = @"view";
NSString *const kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionClick = @"click";

// Notifications
NSString *const kMPCrashReportOccurredNotification = @"MPCrashReportOccurredNotification";
NSString *const kMPConfigureExceptionHandlingNotification = @"MPConfigureExceptionHandlingNotification";
NSString *const kMPUserNotificationDictionaryKey = @"MPUserNotificationDictionaryKey";
NSString *const kMPUserNotificationActionKey = @"MPUserNotificationActionKey";
NSString *const kMPRemoteNotificationDeviceTokenNotification = @"MPRemoteNotificationDeviceTokenNotification";
NSString *const kMPRemoteNotificationDeviceTokenKey = @"MPRemoteNotificationDeviceTokenKey";
NSString *const kMPRemoteNotificationOldDeviceTokenKey = @"MPRemoteNotificationOldDeviceTokenKey";

// Config.plist keys
NSString *const kMPConfigPlist = @"MParticleConfig";
NSString *const kMPConfigApiKey = @"api_key";
NSString *const kMPConfigSecret = @"api_secret";
NSString *const kMPConfigSharedGroupID = @"shared_group_id";
NSString *const kMPConfigCustomUserAgent = @"custom_user_agent";
NSString *const kMPConfigCollectUserAgent = @"collect_user_agent";
NSString *const kMPConfigTrackNotifications = @"track_notifications";
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
NSString *const MPSideloadedKitsCountUserDefaultsKey = @"MPSideloadedKitsCountUserDefaultsKey";

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
NSString *const kMParticleWebViewPathAlias = @"alias";

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
NSString *const kMPEventTypeStringUnknown = @"Unknown";
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
NSString * const kMPNetworkCountryKey = @"nc";
NSString * const kMPNetworkCarrierKey = @"nca";
NSString * const kMPMobileNetworkCodeKey = @"mnc";
NSString * const kMPMobileCountryCodeKey = @"mcc";
NSString * const kMPTimezoneOffsetKey = @"tz";
NSString * const kMPTimezoneDescriptionKey = @"tzn";
NSString * const kMPDeviceJailbrokenKey = @"jb";
NSString * const kMPDeviceArchitectureKey = @"arc";
NSString * const kMPDeviceRadioKey = @"dr";
NSString * const kMPDeviceFloatingPointFormat = @"%0.0f";
NSString * const kMPDeviceSignerIdentityString = @"signeridentity";
NSString * const kMPDeviceIsTabletKey = @"it";
NSString * const kMPDeviceIdentifierKey = @"deviceIdentifier";
NSString * const kMPDeviceLimitAdTrackingKey = @"lat";
NSString * const kMPDeviceIsDaylightSavingTime = @"idst";
NSString * const kMPDeviceInvalidVendorId = @"00000000-0000-0000-0000-000000000000";

// MPRokt Constants
NSString * const kMPPlacementAttributesMapping = @"placementAttributesMapping";

//
// Primitive data type constants
//
const NSTimeInterval MINIMUM_SESSION_TIMEOUT = 1.0;

const NSTimeInterval MAXIMUM_SESSION_TIMEOUT = DBL_MAX;

const NSTimeInterval DEFAULT_SESSION_TIMEOUT = 60.0;

const NSTimeInterval TWENTY_FOUR_HOURS = 86400; // database clean up interval
const NSTimeInterval SEVEN_DAYS = 60 * 60 * 24 * 7; // Old messages purged on migration = 60 seconds * 60 minutes * 24 hours * 7 days
const NSTimeInterval NINETY_DAYS = 60 * 60 * 24 * 90; // Old messages purge interval = 60 seconds * 60 minutes * 24 hours * 90 days

// Interval between uploads if not specified
const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL = 60.0;

const NSTimeInterval DEFAULT_UPLOAD_INTERVAL = 600.0;

// How long to block config requests after a successful response.
const NSTimeInterval CONFIG_REQUESTS_DEFAULT_EXPIRATION_AGE = 5.0*60;
const NSTimeInterval CONFIG_REQUESTS_MAX_EXPIRATION_AGE = 60*60*24.0;

const NSTimeInterval SEARCH_ADS_ATTRIBUTION_GLOBAL_TIMEOUT_SECONDS = 30.0;
const NSTimeInterval SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY = 3.0;
const NSInteger SEARCH_ADS_ATTRIBUTION_MAX_RETRIES = 4;

const NSTimeInterval NETWORK_REQUEST_MAX_WAIT_SECONDS = 10;

// Attributes limits
const NSInteger LIMIT_ATTR_KEY_LENGTH = 256;
const NSInteger LIMIT_ATTR_VALUE_LENGTH = 4096;
const NSInteger MAX_USER_ATTR_LIST_SIZE = 1000;
const NSInteger MAX_USER_ATTR_LIST_ENTRY_LENGTH = 512;

// Consent limits
const NSInteger MAX_GDPR_CONSENT_PURPOSES = 100;
const NSInteger MAX_CCPA_CONSENT_PURPOSES = 100;

// Size limits
const NSInteger MAX_BYTES_PER_EVENT = 100*1024;
const NSInteger MAX_BYTES_PER_BATCH = 2 * MAX_BYTES_PER_EVENT;
const NSInteger MAX_BYTES_PER_EVENT_CRASH = 1000*1024;
const NSInteger MAX_BYTES_PER_BATCH_CRASH = 2 * MAX_BYTES_PER_EVENT_CRASH;
const NSInteger MAX_EVENTS_PER_BATCH = 100;
