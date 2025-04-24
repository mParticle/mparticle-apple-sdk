#ifndef mParticleSDK_MPIConstants_h
#define mParticleSDK_MPIConstants_h

#import <Foundation/Foundation.h>

#define MPMilliseconds(timestamp) @(trunc((timestamp) * 1000))
#define MPCurrentEpochInMilliseconds @(trunc([[NSDate date] timeIntervalSince1970] * 1000))

#define STATE_MACHINE_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"StateMachine"];

#define MPIsNull(object) ((object) == nil || (NSNull *)(object) == [NSNull null])
#define MPIsDictionary(object) (!MPIsNull(object) && [object isKindOfClass:[NSDictionary class]])
#define MPIsArray(object) (!MPIsNull(object) && [object isKindOfClass:[NSArray class]])
#define MPIsString(object) (!MPIsNull(object) && [object isKindOfClass:[NSString class]])
#define MPIsNumber(object) (!MPIsNull(object) && [object isKindOfClass:[NSNumber class]])

#define MPIsNonEmptyDictionary(object) (MPIsDictionary(object) && ((NSDictionary *)object).count > 0)
#define MPIsNonEmptyArray(object) (MPIsArray(object) && ((NSArray *)object).count > 0)
#define MPIsNonEmptyString(object) (MPIsString(object) && ((NSString *)object).length > 0)
#define MPIsNonZeroNumber(object) (MPIsNumber(object) && ![(NSNumber *)object) isEqual:@0])

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
extern NSString * _Nonnull const kMPEventCustomFlags;
extern NSString * _Nonnull const kMPContextKey;
extern NSString * _Nonnull const kMPDataPlanKey;
extern NSString * _Nonnull const kMPDataPlanIdKey;
extern NSString * _Nonnull const kMPDataPlanVersionKey;


// Consent
extern NSString * _Nonnull const kMPConsentState;

// GDPR Consent
extern NSString * _Nonnull const kMPConsentStateGDPR;

// CCPA Consent
extern NSString * _Nonnull const kMPConsentStateCCPA;
extern NSString * _Nonnull const kMPConsentStateCCPAPurpose;

extern NSString * _Nonnull const kMPConsentStateConsented;
extern NSString * _Nonnull const kMPConsentStateDocument;
extern NSString * _Nonnull const kMPConsentStateTimestamp;
extern NSString * _Nonnull const kMPConsentStateLocation;
extern NSString * _Nonnull const kMPConsentStateHardwareId;

// Consent serialization
extern NSString * _Nonnull const kMPConsentStateKey;
extern NSString * _Nonnull const kMPConsentStateGDPRKey;
extern NSString * _Nonnull const kMPConsentStateConsentedKey;
extern NSString * _Nonnull const kMPConsentStateDocumentKey;
extern NSString * _Nonnull const kMPConsentStateTimestampKey;
extern NSString * _Nonnull const kMPConsentStateLocationKey;
extern NSString * _Nonnull const kMPConsentStateHardwareIdKey;

// Consent filtering
extern NSString * _Nonnull const kMPConsentKitFilter;
extern NSString * _Nonnull const kMPConsentKitFilterIncludeOnMatch;
extern NSString * _Nonnull const kMPConsentKitFilterItems;
extern NSString * _Nonnull const kMPConsentKitFilterItemConsented;
extern NSString * _Nonnull const kMPConsentKitFilterItemHash;
extern NSString * _Nonnull const kMPConsentRegulationFilters;
extern NSString * _Nonnull const kMPConsentPurposeFilters;
extern NSString * _Nonnull const kMPConsentGDPRRegulationType;
extern NSString * _Nonnull const kMPConsentCCPARegulationType;
extern NSString * _Nonnull const kMPConsentCCPAPurposeName;

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
extern NSString * _Nonnull const kMPPushNotificationActionTitleKey;
extern NSString * _Nonnull const kMPPushNotificationCategoryIdentifierKey;

// Assorted Keys
extern NSString * _Nonnull const kMPSessionLengthKey;                 
extern NSString * _Nonnull const kMPSessionTotalLengthKey;
extern NSString * _Nonnull const kMPOptOutStatus;
extern NSString * _Nonnull const kMPATT;
extern NSString * _Nonnull const kMPATTTimestamp;
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
extern NSString * _Nonnull const kMPHTTPCacheControlHeaderKey;
extern NSString * _Nonnull const kMPHTTPAgeHeaderKey;
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
extern NSString * _Nonnull const kMPConfigProvisionedTimestampKey;
extern NSString * _Nonnull const kMPConfigMaxAgeHeaderKey;
extern NSString * _Nonnull const kMPConfigParameters;
extern NSString * _Nonnull const kMPUserAgentSystemVersionUserDefaultsKey;
extern NSString * _Nonnull const kMPUserAgentValueUserDefaultsKey;
extern NSString * _Nonnull const kMPFirstSeenUser;
extern NSString * _Nonnull const kMPLastSeenUser;
extern NSString * _Nonnull const kMPAppForePreviousForegroundTime;
extern NSString * _Nonnull const kMPLastUploadSettingsUserDefaultsKey;

// Remote configuration
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeKey;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeAppDefined;
extern NSString * _Nonnull const kMPRemoteConfigFlagsKey;
extern NSString * _Nonnull const kMPRemoteConfigAudienceAPIKey;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeForce;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeIgnore;
extern NSString * _Nonnull const kMPRemoteConfigCrashMaxPLReportLength;
extern NSString * _Nonnull const kMPRemoteConfigAppDefined;
extern NSString * _Nonnull const kMPRemoteConfigForceTrue;
extern NSString * _Nonnull const kMPRemoteConfigForceFalse;
extern NSString * _Nonnull const kMPRemoteConfigKitsKey;
extern NSString * _Nonnull const kMPRemoteConfigKitHashesKey;
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
extern NSString * _Nonnull const kMPRemoteConfigAliasMaxWindow;
extern NSString * _Nonnull const kMPRemoteConfigAllowASR;
extern NSString * _Nonnull const kMPRemoteConfigExcludeAnonymousUsersKey;
extern NSString * _Nonnull const kMPRemoteConfigDirectURLRouting;

extern NSString * _Nonnull const kMPRemoteConfigBlockUnplannedEvents;
extern NSString * _Nonnull const kMPRemoteConfigBlockUnplannedEventAttributes;
extern NSString * _Nonnull const kMPRemoteConfigBlockUnplannedIdentities;
extern NSString * _Nonnull const kMPRemoteConfigBlockUnplannedUserAttributes;

extern NSString * _Nonnull const kMPRemoteConfigDataPlanningResults;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanning;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlock;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedEvents;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedIdentities;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanId;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersion;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanError;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValue;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueDoc;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueDataPoints;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueMatch;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueType;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueValidator;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueDefinition;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueSchemaEverything;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueSchemaNothing;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueAdditionalProperties;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueUserAttributes;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEvent;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueCustomEventType;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueEventName;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueScreenView;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueScreenName;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueProductAction;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueUnknown;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueAddToCart;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromCart;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueCheckout;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueCheckoutOption;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueClick;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueViewDetail;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValuePurchase;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueRefund;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueAddToWishlist;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueRemoveFromWishlist;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValuePromotionAction;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueProductImpressions;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueCriteria;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueAction ;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionUnknown;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionView;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValueImpressionClick;

// Notifications
extern NSString * _Nonnull const kMPCrashReportOccurredNotification;
extern NSString * _Nonnull const kMPConfigureExceptionHandlingNotification;
extern NSString * _Nonnull const kMPUserNotificationDictionaryKey;
extern NSString * _Nonnull const kMPUserNotificationActionKey;
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenNotification;
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenKey;
extern NSString * _Nonnull const kMPRemoteNotificationOldDeviceTokenKey;

// Config.plist keys
extern NSString * _Nonnull const kMPConfigPlist;
extern NSString * _Nonnull const kMPConfigApiKey;
extern NSString * _Nonnull const kMPConfigSecret;
extern NSString * _Nonnull const kMPConfigSharedGroupID;
extern NSString * _Nonnull const kMPConfigCustomUserAgent;
extern NSString * _Nonnull const kMPConfigCollectUserAgent;
extern NSString * _Nonnull const kMPConfigTrackNotifications;
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
extern NSString * _Nonnull const MPSideloadedKitsCountUserDefaultsKey;

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
extern NSString * _Nonnull const kMParticleWebViewPathAlias;

// Message type strings
extern NSString * _Nonnull const kMPMessageTypeStringUnknown;
extern NSString * _Nonnull const kMPMessageTypeStringSessionStart;
extern NSString * _Nonnull const kMPMessageTypeStringSessionEnd;
extern NSString * _Nonnull const kMPMessageTypeStringScreenView;
extern NSString * _Nonnull const kMPMessageTypeStringEvent;
extern NSString * _Nonnull const kMPMessageTypeStringCrashReport;
extern NSString * _Nonnull const kMPMessageTypeStringOptOut;
extern NSString * _Nonnull const kMPMessageTypeStringFirstRun;
extern NSString * _Nonnull const kMPMessageTypeStringPreAttribution;
extern NSString * _Nonnull const kMPMessageTypeStringPushRegistration;
extern NSString * _Nonnull const kMPMessageTypeStringAppStateTransition;
extern NSString * _Nonnull const kMPMessageTypeStringPushNotification;
extern NSString * _Nonnull const kMPMessageTypeStringNetworkPerformance;
extern NSString * _Nonnull const kMPMessageTypeStringBreadcrumb;
extern NSString * _Nonnull const kMPMessageTypeStringProfile;
extern NSString * _Nonnull const kMPMessageTypeStringPushNotificationInteraction;
extern NSString * _Nonnull const kMPMessageTypeStringCommerceEvent;
extern NSString * _Nonnull const kMPMessageTypeStringUserAttributeChange;
extern NSString * _Nonnull const kMPMessageTypeStringUserIdentityChange;
extern NSString * _Nonnull const kMPMessageTypeStringMedia;

// Event type strings
extern NSString * _Nonnull const kMPEventTypeStringUnknown;
extern NSString * _Nonnull const kMPEventTypeStringNavigation;
extern NSString * _Nonnull const kMPEventTypeStringLocation;
extern NSString * _Nonnull const kMPEventTypeStringSearch;
extern NSString * _Nonnull const kMPEventTypeStringTransaction;
extern NSString * _Nonnull const kMPEventTypeStringUserContent;
extern NSString * _Nonnull const kMPEventTypeStringUserPreference;
extern NSString * _Nonnull const kMPEventTypeStringSocial;
extern NSString * _Nonnull const kMPEventTypeStringOther;
extern NSString * _Nonnull const kMPEventTypeStringMediaDiscontinued;
extern NSString * _Nonnull const kMPEventTypeStringProductAddToCart;
extern NSString * _Nonnull const kMPEventTypeStringProductRemoveFromCart;
extern NSString * _Nonnull const kMPEventTypeStringProductCheckout;
extern NSString * _Nonnull const kMPEventTypeStringProductCheckoutOption;
extern NSString * _Nonnull const kMPEventTypeStringProductClick;
extern NSString * _Nonnull const kMPEventTypeStringProductViewDetail;
extern NSString * _Nonnull const kMPEventTypeStringProductPurchase;
extern NSString * _Nonnull const kMPEventTypeStringProductRefund;
extern NSString * _Nonnull const kMPEventTypeStringPromotionView;
extern NSString * _Nonnull const kMPEventTypeStringPromotionClick;
extern NSString * _Nonnull const kMPEventTypeStringProductAddToWishlist;
extern NSString * _Nonnull const kMPEventTypeStringProductRemoveFromWishlist;
extern NSString * _Nonnull const kMPEventTypeStringProductImpression;
extern NSString * _Nonnull const kMPEventTypeStringMedia;

//
// Primitive data type constants
//
extern const NSTimeInterval MINIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval MAXIMUM_SESSION_TIMEOUT DEPRECATED_MSG_ATTRIBUTE("There is no longer a maximum session timout, the value is unlimited");
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
extern const NSTimeInterval CONFIG_REQUESTS_DEFAULT_EXPIRATION_AGE;
extern const NSTimeInterval CONFIG_REQUESTS_MAX_EXPIRATION_AGE;

// Search Ads timeout/retry
extern const NSTimeInterval SEARCH_ADS_ATTRIBUTION_GLOBAL_TIMEOUT_SECONDS;
extern const NSTimeInterval SEARCH_ADS_ATTRIBUTION_DELAY_BEFORE_RETRY;
extern const NSInteger SEARCH_ADS_ATTRIBUTION_MAX_RETRIES;

// Network request timeout
extern const NSTimeInterval NETWORK_REQUEST_MAX_WAIT_SECONDS;

// Attributes limits
extern const NSInteger LIMIT_ATTR_KEY_LENGTH;
extern const NSInteger LIMIT_ATTR_VALUE_LENGTH;
extern const NSInteger MAX_USER_ATTR_LIST_SIZE;
extern const NSInteger MAX_USER_ATTR_LIST_ENTRY_LENGTH;

// Consent limits
extern const NSInteger MAX_GDPR_CONSENT_PURPOSES;
extern const NSInteger MAX_CCPA_CONSENT_PURPOSES;

// Size limits
extern const NSInteger MAX_BYTES_PER_EVENT;
extern const NSInteger MAX_BYTES_PER_BATCH;
extern const NSInteger MAX_BYTES_PER_EVENT_CRASH;
extern const NSInteger MAX_BYTES_PER_BATCH_CRASH;
extern const NSInteger MAX_EVENTS_PER_BATCH;

// Device (Need these in objective C until the classes that use them are refactored to Swift)
extern NSString * _Nonnull const kMPDeviceInformationKey;
extern NSString * _Nonnull const kMPDeviceBrandKey;
extern NSString * _Nonnull const kMPDeviceProductKey;
extern NSString * _Nonnull const kMPDeviceNameKey;
extern NSString * _Nonnull const kMPDeviceAdvertiserIdKey;
extern NSString * _Nonnull const kMPDeviceAppVendorIdKey;
extern NSString * _Nonnull const kMPDeviceBuildIdKey;
extern NSString * _Nonnull const kMPDeviceManufacturerKey;
extern NSString * _Nonnull const kMPDevicePlatformKey;
extern NSString * _Nonnull const kMPDeviceOSKey;
extern NSString * _Nonnull const kMPDeviceModelKey;
extern NSString * _Nonnull const kMPScreenHeightKey;
extern NSString * _Nonnull const kMPScreenWidthKey;
extern NSString * _Nonnull const kMPDeviceLocaleCountryKey;
extern NSString * _Nonnull const kMPDeviceLocaleLanguageKey;
extern NSString * _Nonnull const kMPNetworkCountryKey;
extern NSString * _Nonnull const kMPNetworkCarrierKey;
extern NSString * _Nonnull const kMPMobileNetworkCodeKey;
extern NSString * _Nonnull const kMPMobileCountryCodeKey;
extern NSString * _Nonnull const kMPTimezoneOffsetKey;
extern NSString * _Nonnull const kMPTimezoneDescriptionKey;
extern NSString * _Nonnull const kMPDeviceJailbrokenKey;
extern NSString * _Nonnull const kMPDeviceArchitectureKey;
extern NSString * _Nonnull const kMPDeviceRadioKey;
extern NSString * _Nonnull const kMPDeviceFloatingPointFormat;
extern NSString * _Nonnull const kMPDeviceSignerIdentityString;
extern NSString * _Nonnull const kMPDeviceIsTabletKey;
extern NSString * _Nonnull const kMPDeviceIdentifierKey;
extern NSString * _Nonnull const kMPDeviceLimitAdTrackingKey;
extern NSString * _Nonnull const kMPDeviceIsDaylightSavingTime;
extern NSString * _Nonnull const kMPDeviceInvalidVendorId;

// MPRokt Constants
extern NSString * _Nonnull const kMPPlacementAttributesMapping;
#endif
