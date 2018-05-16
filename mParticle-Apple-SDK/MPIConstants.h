#ifndef mParticleSDK_MPIConstants_h
#define mParticleSDK_MPIConstants_h

#import <Foundation/Foundation.h>

#define MPMilliseconds(timestamp) @(trunc((timestamp) * 1000))
#define MPCurrentEpochInMilliseconds @(trunc([[NSDate date] timeIntervalSince1970] * 1000))

#define CRASH_LOGS_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"CrashLogs"];
#define ARCHIVED_MESSAGES_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"ArchivedMessages"];
#define STATE_MACHINE_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"StateMachine"];

#define MPIsNull(object) ((object) == nil || (NSNull *)(object) == [NSNull null])

typedef NS_ENUM(NSInteger, MPUploadStatus) {
    MPUploadStatusUnknown = -1,
    MPUploadStatusStream = 0,
    MPUploadStatusBatch,
    MPUploadStatusUploaded
};

// Types of messages as defined by the Javascript SDK
typedef NS_ENUM(NSUInteger, MPJavascriptMessageType) {
    MPJavascriptMessageTypeSessionStart = 1,    /** Session start */
    MPJavascriptMessageTypeSessionEnd,   /** Session end */
    MPJavascriptMessageTypePageView,     /** Page/Screen view */
    MPJavascriptMessageTypePageEvent,      /** User/transaction event */
    MPJavascriptMessageTypeError,       /** Error event */
    MPJavascriptMessageTypeOptOut,    /** Opt out */
    MPJavascriptMessageTypeCommerce = 16  /** Product action, promotion or impression */
};

typedef NS_ENUM(NSInteger, MPDataType) {
    MPDataTypeString = 1,
    MPDataTypeInt = 2,
    MPDataTypeBool = 3,
    MPDataTypeFloat = 4,
    MPDataTypeLong = 5
};

// mParticle SDK Version
extern NSString * _Nonnull const kMParticleSDKVersion;

// Message Type (dt)
extern NSString * _Nonnull const kMPMessageTypeKey;                  
extern NSString * _Nonnull const kMPMessageTypeRequestHeader;
extern NSString * _Nonnull const kMPMessageTypeResponseHeader;
extern NSString * _Nonnull const kMPMessageTypeConfig;
extern NSString * _Nonnull const kMPMessageTypeNetworkPerformance;
extern NSString * _Nonnull const kMPMessageTypeLeaveBreadcrumbs;

// Request Header Keys
extern NSString * _Nonnull const kMPmParticleSDKVersionKey;
extern NSString * _Nonnull const kMPApplicationKey;

// Device Information Keys
extern NSString * _Nonnull const kMPDeviceCydiaJailbrokenKey;
extern NSString * _Nonnull const kMPDeviceSupportedPushNotificationTypesKey;

// Launch Keys
extern NSString * _Nonnull const kMPLaunchSourceKey;
extern NSString * _Nonnull const kMPLaunchURLKey;
extern NSString * _Nonnull const kMPLaunchParametersKey;
extern NSString * _Nonnull const kMPLaunchSessionFinalizedKey;
extern NSString * _Nonnull const kMPLaunchNumberOfSessionInterruptionsKey;

// Message Keys
extern NSString * _Nonnull const kMPMessagesKey;
extern NSString * _Nonnull const kMPMessageUserIdKey;
extern NSString * _Nonnull const kMPMessageIdKey;                     
extern NSString * _Nonnull const kMPTimestampKey;                   
extern NSString * _Nonnull const kMPSessionIdKey;                     
extern NSString * _Nonnull const kMPSessionStartTimestamp;           
extern NSString * _Nonnull const kMPEventStartTimestamp;              
extern NSString * _Nonnull const kMPEventLength;                     
extern NSString * _Nonnull const kMPEventNameKey;
extern NSString * _Nonnull const kMPEventTypeKey;
extern NSString * _Nonnull const kMPEventLengthKey;
extern NSString * _Nonnull const kMPAttributesKey;                   
extern NSString * _Nonnull const kMPLocationKey;
extern NSString * _Nonnull const kMPUserAttributeKey;
extern NSString * _Nonnull const kMPUserAttributeDeletedKey;
extern NSString * _Nonnull const kMPEventTypePageView;
extern NSString * _Nonnull const kMPUserIdentityArrayKey;
extern NSString * _Nonnull const kMPUserIdentityIdKey;
extern NSString * _Nonnull const kMPUserIdentityTypeKey;
extern NSString * _Nonnull const kMPUserIdentitySharedGroupIdentifier;
extern NSString * _Nonnull const kMPAppStateTransitionType;
extern NSString * _Nonnull const kMPEventTagsKey;
extern NSString * _Nonnull const kMPLeaveBreadcrumbsKey;
extern NSString * _Nonnull const kMPOptOutKey;
extern NSString * _Nonnull const kMPDateUserIdentityWasFirstSet;
extern NSString * _Nonnull const kMPIsFirstTimeUserIdentityHasBeenSet;
extern NSString * _Nonnull const kMPRemoteNotificationCampaignHistoryKey;
extern NSString * _Nonnull const kMPRemoteNotificationContentIdHistoryKey;
extern NSString * _Nonnull const kMPRemoteNotificationTimestampHistoryKey;
extern NSString * _Nonnull const kMPForwardStatsRecord;

// Consent
extern NSString * _Nonnull const kMPConsentState;

// GDPR Consent
extern NSString * _Nonnull const kMPConsentStateGDPR;

extern NSString * _Nonnull const kMPConsentStateGDPRConsented;
extern NSString * _Nonnull const kMPConsentStateGDPRDocument;
extern NSString * _Nonnull const kMPConsentStateGDPRTimestamp;
extern NSString * _Nonnull const kMPConsentStateGDPRLocation;
extern NSString * _Nonnull const kMPConsentStateGDPRHardwareId;

// Consent serialization
extern NSString * _Nonnull const kMPConsentStateKey;
extern NSString * _Nonnull const kMPConsentStateGDPRKey;
extern NSString * _Nonnull const kMPConsentStateGDPRConsentedKey;
extern NSString * _Nonnull const kMPConsentStateGDPRDocumentKey;
extern NSString * _Nonnull const kMPConsentStateGDPRTimestampKey;
extern NSString * _Nonnull const kMPConsentStateGDPRLocationKey;
extern NSString * _Nonnull const kMPConsentStateGDPRHardwareIdKey;

// Push Notifications
extern NSString * _Nonnull const kMPDeviceTokenKey;
extern NSString * _Nonnull const kMPPushStatusKey;
extern NSString * _Nonnull const kMPPushMessageTypeKey;
extern NSString * _Nonnull const kMPPushMessageReceived;
extern NSString * _Nonnull const kMPPushMessageAction;
extern NSString * _Nonnull const kMPPushMessageSent;
extern NSString * _Nonnull const kMPPushMessageProviderKey;
extern NSString * _Nonnull const kMPPushMessageProviderValue;
extern NSString * _Nonnull const kMPPushMessagePayloadKey;
extern NSString * _Nonnull const kMPPushNotificationStateKey;
extern NSString * _Nonnull const kMPPushNotificationStateNotRunning;
extern NSString * _Nonnull const kMPPushNotificationStateBackground;
extern NSString * _Nonnull const kMPPushNotificationStateForeground;
extern NSString * _Nonnull const kMPPushNotificationActionIdentifierKey;
extern NSString * _Nonnull const kMPPushNotificationBehaviorKey;
extern NSString * _Nonnull const kMPPushNotificationActionTileKey;
extern NSString * _Nonnull const kMPPushNotificationCategoryIdentifierKey;

// Assorted Keys
extern NSString * _Nonnull const kMPSessionLengthKey;                 
extern NSString * _Nonnull const kMPSessionTotalLengthKey;
extern NSString * _Nonnull const kMPOptOutStatus;
extern NSString * _Nonnull const kMPAlwaysTryToCollectIDFA;
extern NSString * _Nonnull const kMPCrashingSeverity;
extern NSString * _Nonnull const kMPCrashingClass;
extern NSString * _Nonnull const kMPCrashWasHandled;
extern NSString * _Nonnull const kMPErrorMessage;                     
extern NSString * _Nonnull const kMPStackTrace;                       
extern NSString * _Nonnull const kMPCrashSignal;
extern NSString * _Nonnull const kMPTopmostContext;
extern NSString * _Nonnull const kMPPLCrashReport;
extern NSString * _Nonnull const kMPCrashExceptionKey;
extern NSString * _Nonnull const kMPNullUserAttributeString;
extern NSString * _Nonnull const kMPSessionTimeoutKey;
extern NSString * _Nonnull const kMPUploadIntervalKey;
extern NSString * _Nonnull const kMPPreviousSessionLengthKey;
extern NSString * _Nonnull const kMPLifeTimeValueKey;
extern NSString * _Nonnull const kMPIncreasedLifeTimeValueKey;
extern NSString * _Nonnull const kMPPreviousSessionStateFileName;
extern NSString * _Nonnull const kMPHTTPMethodPost;
extern NSString * _Nonnull const kMPHTTPMethodGet;
extern NSString * _Nonnull const kMPPreviousSessionIdKey;
extern NSString * _Nonnull const kMPEventCounterKey;
extern NSString * _Nonnull const kMPProfileChangeTypeKey;
extern NSString * _Nonnull const kMPProfileChangeCurrentKey;
extern NSString * _Nonnull const kMPProfileChangePreviousKey;
extern NSString * _Nonnull const kMPPresentedViewControllerKey;
extern NSString * _Nonnull const kMPMainThreadKey;
extern NSString * _Nonnull const kMPPreviousSessionStartKey;
extern NSString * _Nonnull const kMPAppFirstSeenInstallationKey;
extern NSString * _Nonnull const kMPResponseURLKey;
extern NSString * _Nonnull const kMPResponseMethodKey;
extern NSString * _Nonnull const kMPResponsePOSTDataKey;
extern NSString * _Nonnull const kMPHTTPHeadersKey;
extern NSString * _Nonnull const kMPHTTPAcceptEncodingKey;
extern NSString * _Nonnull const kMPDeviceTokenTypeKey;
extern NSString * _Nonnull const kMPDeviceTokenTypeDevelopment;
extern NSString * _Nonnull const kMPDeviceTokenTypeProduction;
extern NSString * _Nonnull const kMPHTTPETagHeaderKey;
extern NSString * _Nonnull const kMResponseConfigurationKey;
extern NSString * _Nonnull const kMResponseConfigurationMigrationKey;
extern NSString * _Nonnull const kMPAppSearchAdsAttributionKey;
extern NSString * _Nonnull const kMPSynchedUserAttributesKey;
extern NSString * _Nonnull const kMPSynchedUserIdentitiesKey;
extern NSString * _Nonnull const kMPSessionUserIdsKey;
extern NSString * _Nonnull const kMPIsEphemeralKey;
extern NSString * _Nonnull const kMPLastIdentifiedDate;
extern NSString * _Nonnull const kMPDeviceApplicationStampKey;
extern NSString * _Nonnull const kMPDeviceApplicationStampStorageKey;
extern NSString * _Nonnull const kMPLastConfigReceivedKey;
extern NSString * _Nonnull const kMPUserAgentSystemVersionUserDefaultsKey;
extern NSString * _Nonnull const kMPUserAgentValueUserDefaultsKey;

// Remote configuration
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeKey;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeAppDefined;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeForce;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeIgnore;
extern NSString * _Nonnull const kMPRemoteConfigAppDefined;
extern NSString * _Nonnull const kMPRemoteConfigForceTrue;
extern NSString * _Nonnull const kMPRemoteConfigForceFalse;
extern NSString * _Nonnull const kMPRemoteConfigKitsKey;
extern NSString * _Nonnull const kMPRemoteConfigConsumerInfoKey;
extern NSString * _Nonnull const kMPRemoteConfigCookiesKey;
extern NSString * _Nonnull const kMPRemoteConfigMPIDKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleSettingsKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleIdKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModulePreferencesKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleLocationKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModulePreferenceSettingsKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleReadKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleDataTypeKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleWriteKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomModuleDefaultKey;
extern NSString * _Nonnull const kMPRemoteConfigCustomSettingsKey;
extern NSString * _Nonnull const kMPRemoteConfigSandboxModeKey;
extern NSString * _Nonnull const kMPRemoteConfigSessionTimeoutKey;
extern NSString * _Nonnull const kMPRemoteConfigPushNotificationDictionaryKey;
extern NSString * _Nonnull const kMPRemoteConfigPushNotificationModeKey;
extern NSString * _Nonnull const kMPRemoteConfigPushNotificationTypeKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationModeKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationAccuracyKey;
extern NSString * _Nonnull const kMPRemoteConfigLocationMinimumDistanceKey;
extern NSString * _Nonnull const kMPRemoteConfigRampKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerEventsKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerMessageTypesKey;
extern NSString * _Nonnull const kMPRemoteConfigUniqueIdentifierKey;
extern NSString * _Nonnull const kMPRemoteConfigBracketKey;
extern NSString * _Nonnull const kMPRemoteConfigRestrictIDFA;

// Notifications
extern NSString * _Nonnull const kMPCrashReportOccurredNotification;
extern NSString * _Nonnull const kMPConfigureExceptionHandlingNotification;
extern NSString * _Nonnull const kMPRemoteNotificationReceivedNotification;
extern NSString * _Nonnull const kMPUserNotificationDictionaryKey;
extern NSString * _Nonnull const kMPUserNotificationActionKey;
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenNotification;
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenKey;
extern NSString * _Nonnull const kMPRemoteNotificationOldDeviceTokenKey;
extern NSString * _Nonnull const kMPLocalNotificationReceivedNotification;
extern NSString * _Nonnull const kMPUserNotificationRunningModeKey;

// Config.plist keys
extern NSString * _Nonnull const kMPConfigPlist;
extern NSString * _Nonnull const kMPConfigApiKey;
extern NSString * _Nonnull const kMPConfigSecret;
extern NSString * _Nonnull const kMPConfigSharedGroupID;
extern NSString * _Nonnull const kMPConfigCustomUserAgent;
extern NSString * _Nonnull const kMPConfigCollectUserAgent;
extern NSString * _Nonnull const kMPConfigSessionTimeout;
extern NSString * _Nonnull const kMPConfigUploadInterval;
extern NSString * _Nonnull const kMPConfigEnableSSL;
extern NSString * _Nonnull const kMPConfigEnableCrashReporting;
extern NSString * _Nonnull const kMPConfigLocationTracking;
extern NSString * _Nonnull const kMPConfigLocationAccuracy;
extern NSString * _Nonnull const kMPConfigLocationDistanceFilter;

// Data connection path/status
extern NSString * _Nonnull const kDataConnectionOffline;
extern NSString * _Nonnull const kDataConnectionMobile;
extern NSString * _Nonnull const kDataConnectionWifi;

// Application State Transition
extern NSString * _Nonnull const kMPASTInitKey;
extern NSString * _Nonnull const kMPASTExitKey;
extern NSString * _Nonnull const kMPASTBackgroundKey;
extern NSString * _Nonnull const kMPASTForegroundKey;
extern NSString * _Nonnull const kMPASTIsFirstRunKey;
extern NSString * _Nonnull const kMPASTIsUpgradeKey;
extern NSString * _Nonnull const kMPASTPreviousSessionSuccessfullyClosedKey;

// Network performance
extern NSString * _Nonnull const kMPNetworkPerformanceMeasurementNotification;
extern NSString * _Nonnull const kMPNetworkPerformanceKey;

// Kits
extern NSString * _Nonnull const MPKitAttributeJailbrokenKey;
extern NSString * _Nonnull const MPIntegrationAttributesKey;

// mParticle Javascript SDK paths
extern NSString * _Nonnull const kMParticleWebViewSdkScheme;
extern NSString * _Nonnull const kMParticleWebViewPathLogEvent;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserIdentity;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserTag;
extern NSString * _Nonnull const kMParticleWebViewPathRemoveUserTag;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathRemoveUserAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathSetSessionAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathIdentify;
extern NSString * _Nonnull const kMParticleWebViewPathLogout;
extern NSString * _Nonnull const kMParticleWebViewPathLogin;
extern NSString * _Nonnull const kMParticleWebViewPathModify;

//
// Primitive data type constants
//
extern const NSTimeInterval MINIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval MAXIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval DEFAULT_SESSION_TIMEOUT;
extern const NSTimeInterval TWENTY_FOUR_HOURS; // Database clean up interval
extern const NSTimeInterval SEVEN_DAYS;
extern const NSTimeInterval NINETY_DAYS;

// Interval between uploads if not specified
extern const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL;
extern const NSTimeInterval DEFAULT_UPLOAD_INTERVAL;

// Delay before processing uploads to allow app to get started
extern const NSTimeInterval INITIAL_UPLOAD_TIME;

// How long to block config requests after a successful response.
extern const NSTimeInterval DEBUG_CONFIG_REQUESTS_QUIET_INTERVAL;
extern const NSTimeInterval CONFIG_REQUESTS_QUIET_INTERVAL;

// Attributes limits
extern const NSInteger LIMIT_ATTR_COUNT;
extern const NSInteger LIMIT_ATTR_LENGTH;
extern const NSInteger LIMIT_NAME;
extern const NSInteger LIMIT_USER_ATTR_LENGTH;
extern const NSInteger MAX_USER_ATTR_LIST_SIZE;
extern const NSInteger MAX_USER_ATTR_LIST_ENTRY_LENGTH;

// Consent limits
extern const NSInteger MAX_GDPR_CONSENT_PURPOSES;

#endif
