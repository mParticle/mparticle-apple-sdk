#ifndef mParticleSDK_MPIConstants_h
#define mParticleSDK_MPIConstants_h

#import <Foundation/Foundation.h>

#define MPMilliseconds(timestamp) @(trunc((timestamp) * 1000))
#define MPCurrentEpochInMilliseconds @(trunc([[NSDate date] timeIntervalSince1970] * 1000))

#define STATE_MACHINE_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"StateMachine"];

#define MPIsNull(object) ((object) == nil || (NSNull *)(object) == [NSNull null])
#define MPIsDictionary(object) (!MPIsNull(object) && [object isKindOfClass:[NSDictionary class]])

#define NSStringFromEventType( value ) \
( \
@{ \
@( MPEventTypeNavigation )          : kMPEventTypeStringNavigation, \
@( MPEventTypeLocation )            : kMPEventTypeStringLocation, \
@( MPEventTypeSearch )              : kMPEventTypeStringSearch, \
@( MPEventTypeTransaction )         : kMPEventTypeStringTransaction, \
@( MPEventTypeUserContent )         : kMPEventTypeStringUserContent, \
@( MPEventTypeUserPreference )      : kMPEventTypeStringUserPreference, \
@( MPEventTypeSocial )              : kMPEventTypeStringSocial, \
@( MPEventTypeOther )               : kMPEventTypeStringOther, \
@( MPEventTypeAddToCart )           : kMPEventTypeStringProductAddToCart, \
@( MPEventTypeRemoveFromCart )      : kMPEventTypeStringProductRemoveFromCart, \
@( MPEventTypeCheckout )            : kMPEventTypeStringProductCheckout, \
@( MPEventTypeCheckoutOption )      : kMPEventTypeStringProductCheckoutOption, \
@( MPEventTypeClick )               : kMPEventTypeStringProductClick, \
@( MPEventTypeViewDetail )          : kMPEventTypeStringProductViewDetail, \
@( MPEventTypePurchase )            : kMPEventTypeStringProductPurchase, \
@( MPEventTypeRefund )              : kMPEventTypeStringProductRefund, \
@( MPEventTypePromotionView )       : kMPEventTypeStringPromotionView, \
@( MPEventTypePromotionClick )      : kMPEventTypeStringPromotionClick, \
@( MPEventTypeAddToWishlist )       : kMPEventTypeStringProductAddToWishlist, \
@( MPEventTypeRemoveFromWishlist )  : kMPEventTypeStringProductRemoveFromWishlist, \
@( MPEventTypeImpression )          : kMPEventTypeStringProductImpression, \
@( MPEventTypeMedia )               : kMPEventTypeStringMedia, \
} \
[ @( value ) ] \
)

#define NSStringFromMessageType( value ) \
( \
@{ \
@( MPMessageTypeUnknown )          : kMPMessageTypeStringUnknown, \
@( MPMessageTypeSessionStart )            : kMPMessageTypeStringSessionStart, \
@( MPMessageTypeSessionEnd )              : kMPMessageTypeStringSessionEnd, \
@( MPMessageTypeScreenView )         : kMPMessageTypeStringScreenView, \
@( MPMessageTypeEvent )         : kMPMessageTypeStringEvent, \
@( MPMessageTypeCrashReport )      : kMPMessageTypeStringCrashReport, \
@( MPMessageTypeOptOut )              : kMPMessageTypeStringOptOut, \
@( MPMessageTypeFirstRun )               : kMPMessageTypeStringFirstRun, \
@( MPMessageTypePreAttribution )           : kMPMessageTypeStringPreAttribution, \
@( MPMessageTypePushRegistration )      : kMPMessageTypeStringPushRegistration, \
@( MPMessageTypeAppStateTransition )            : kMPMessageTypeStringAppStateTransition, \
@( MPMessageTypePushNotification )      : kMPMessageTypeStringPushNotification, \
@( MPMessageTypeNetworkPerformance )               : kMPMessageTypeStringNetworkPerformance, \
@( MPMessageTypeBreadcrumb )          : kMPMessageTypeStringBreadcrumb, \
@( MPMessageTypeProfile )            : kMPMessageTypeStringProfile, \
@( MPMessageTypePushNotificationInteraction )              : kMPMessageTypeStringPushNotificationInteraction, \
@( MPMessageTypeCommerceEvent )       : kMPMessageTypeStringCommerceEvent, \
@( MPMessageTypeUserAttributeChange )      : kMPMessageTypeStringUserAttributeChange, \
@( MPMessageTypeUserIdentityChange )       : kMPMessageTypeStringUserIdentityChange, \
@( MPMessageTypeMedia )  : kMPMessageTypeStringMedia, \
} \
[ @( value ) ] \
)
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

// Request Header Keys
extern NSString * _Nonnull const kMPmParticleSDKVersionKey;
extern NSString * _Nonnull const kMPApplicationKey;

// Device Information Keys
extern NSString * _Nonnull const kMPDeviceCydiaJailbrokenKey;

// Message Keys
extern NSString * _Nonnull const kMPMessagesKey;
extern NSString * _Nonnull const kMPMessageIdKey;                     
extern NSString * _Nonnull const kMPTimestampKey;                   
extern NSString * _Nonnull const kMPSessionIdKey;                     
extern NSString * _Nonnull const kMPSessionStartTimestamp;           
extern NSString * _Nonnull const kMPEventStartTimestamp;              
extern NSString * _Nonnull const kMPEventLength;                     
extern NSString * _Nonnull const kMPEventNameKey;
extern NSString * _Nonnull const kMPEventTypeKey;
extern NSString * _Nonnull const kMPAttributesKey;                   
extern NSString * _Nonnull const kMPUserAttributeKey;
extern NSString * _Nonnull const kMPUserIdentityArrayKey;
extern NSString * _Nonnull const kMPUserIdentityIdKey;
extern NSString * _Nonnull const kMPUserIdentityTypeKey;
extern NSString * _Nonnull const kMPLeaveBreadcrumbsKey;
extern NSString * _Nonnull const kMPOptOutKey;
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
extern NSString * _Nonnull const kMPConsentDeviceStateKey;

// Consent filtering
extern NSString * _Nonnull const kMPConsentGDPRRegulationType;
extern NSString * _Nonnull const kMPConsentCCPARegulationType;
extern NSString * _Nonnull const kMPConsentCCPAPurposeName;

// Push Notifications
extern NSString * _Nonnull const kMPDeviceTokenKey;
extern NSString * _Nonnull const kMPPushNotificationStateBackground;
extern NSString * _Nonnull const kMPPushNotificationStateForeground;

// Assorted Keys
extern NSString * _Nonnull const kMPOptOutStatus;
extern NSString * _Nonnull const kMPATTTimestamp;
extern NSString * _Nonnull const kMPCrashingSeverity;
extern NSString * _Nonnull const kMPCrashWasHandled;
extern NSString * _Nonnull const kMPErrorMessage;                     
extern NSString * _Nonnull const kMPStackTrace;                       
extern NSString * _Nonnull const kMPPLCrashReport;
extern NSString * _Nonnull const kMPNullUserAttributeString;
extern NSString * _Nonnull const kMPSessionTimeoutKey;
extern NSString * _Nonnull const kMPUploadIntervalKey;
extern NSString * _Nonnull const kMPLifeTimeValueKey;
extern NSString * _Nonnull const kMPHTTPMethodPost;
extern NSString * _Nonnull const kMPHTTPMethodGet;
extern NSString * _Nonnull const kMPEventCounterKey;
extern NSString * _Nonnull const kMPAppFirstSeenInstallationKey;
extern NSString * _Nonnull const kMPSynchedUserAttributesKey;
extern NSString * _Nonnull const kMPIsEphemeralKey;
extern NSString * _Nonnull const kMPLastIdentifiedDate;
extern NSString * _Nonnull const kMPDeviceApplicationStampKey;
extern NSString * _Nonnull const kMPConfigProvisionedTimestampKey;
extern NSString * _Nonnull const kMPConfigMaxAgeHeaderKey;
extern NSString * _Nonnull const kMPFirstSeenUser;
extern NSString * _Nonnull const kMPLastSeenUser;

// Remote configuration
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeKey;
extern NSString * _Nonnull const kMPRemoteConfigExceptionHandlingModeForce;
extern NSString * _Nonnull const kMPRemoteConfigKitsKey;
extern NSString * _Nonnull const kMPRemoteConfigKitConfigurationKey;
extern NSString * _Nonnull const kMPRemoteConfigKitHashesKey;
extern NSString * _Nonnull const kMPRemoteConfigConsumerInfoKey;
extern NSString * _Nonnull const kMPRemoteConfigCookiesKey;
// Keys within one entry of the kMPRemoteConfigCookiesKey table. Moved here from MPConsumerInfo.h
// when MPConsumerInfo became Swift, which cannot emit C globals. Objective-C callers build a
// cookie configuration from them; the Swift module keeps its own copies in MPCookie.swift.
extern NSString * _Nonnull const kMPCKContent;
extern NSString * _Nonnull const kMPCKDomain;
extern NSString * _Nonnull const kMPCKExpiration;
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
extern NSString * _Nonnull const kMPRemoteConfigSessionTimeoutKey;
extern NSString * _Nonnull const kMPRemoteConfigRampKey;
extern NSString * _Nonnull const kMPRemoteConfigTriggerKey;
extern NSString * _Nonnull const kMPRemoteConfigUniqueIdentifierKey;

extern NSString * _Nonnull const kMPRemoteConfigDataPlanning;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlock;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedEvents;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedEventAttributes;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedUserAttributes;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningBlockUnplannedIdentities;
extern NSString * _Nonnull const kMPRemoteConfigDataPlanningDataPlanVersionValue;

// Notifications
extern NSString * _Nonnull const kMPRemoteNotificationDeviceTokenKey;

// Config.plist keys
extern NSString * _Nonnull const kMPConfigPlist;
extern NSString * _Nonnull const kMPConfigCustomUserAgent;
extern NSString * _Nonnull const kMPConfigCollectUserAgent;
extern NSString * _Nonnull const kMPConfigTrackNotifications;
extern NSString * _Nonnull const kMPConfigSessionTimeout;
extern NSString * _Nonnull const kMPConfigUploadInterval;

// Kits
extern NSString * _Nonnull const MPIntegrationAttributesKey;

// mParticle Javascript SDK paths
extern NSString * _Nonnull const kMParticleWebViewPathLogEvent;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserTag;
extern NSString * _Nonnull const kMParticleWebViewPathRemoveUserTag;
extern NSString * _Nonnull const kMParticleWebViewPathSetUserAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathRemoveUserAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathSetSessionAttribute;
extern NSString * _Nonnull const kMParticleWebViewPathIdentify;
extern NSString * _Nonnull const kMParticleWebViewPathLogout;
extern NSString * _Nonnull const kMParticleWebViewPathLogin;
extern NSString * _Nonnull const kMParticleWebViewPathModify;

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
extern NSString * _Nonnull const kMPEventTypeStringNavigation;
extern NSString * _Nonnull const kMPEventTypeStringLocation;
extern NSString * _Nonnull const kMPEventTypeStringSearch;
extern NSString * _Nonnull const kMPEventTypeStringTransaction;
extern NSString * _Nonnull const kMPEventTypeStringUserContent;
extern NSString * _Nonnull const kMPEventTypeStringUserPreference;
extern NSString * _Nonnull const kMPEventTypeStringSocial;
extern NSString * _Nonnull const kMPEventTypeStringOther;
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
extern const NSTimeInterval DEFAULT_SESSION_TIMEOUT;

// Interval between uploads if not specified
extern const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL;
extern const NSTimeInterval DEFAULT_UPLOAD_INTERVAL;

// Attributes limits
extern const NSInteger LIMIT_ATTR_KEY_LENGTH;
extern const NSInteger LIMIT_ATTR_VALUE_LENGTH;

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
extern NSString * _Nonnull const kMPTimezoneOffsetKey;
extern NSString * _Nonnull const kMPTimezoneDescriptionKey;
extern NSString * _Nonnull const kMPDeviceJailbrokenKey;
extern NSString * _Nonnull const kMPDeviceArchitectureKey;
extern NSString * _Nonnull const kMPDeviceIsTabletKey;
extern NSString * _Nonnull const kMPDeviceLimitAdTrackingKey;
extern NSString * _Nonnull const kMPDeviceIsDaylightSavingTime;

#endif
