//
//  MPConstants.h
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifndef mParticleSDK_MPConstants_h
#define mParticleSDK_MPConstants_h

#import <Foundation/Foundation.h>

#define MPMilliseconds(timestamp) @(trunc((timestamp) * 1000))
#define MPCurrentEpochInMilliseconds @(trunc([[NSDate date] timeIntervalSince1970] * 1000))

#define CRASH_LOGS_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"CrashLogs"];
#define ARCHIVED_MESSAGES_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"ArchivedMessages"];
#define STATE_MACHINE_DIRECTORY_PATH [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0] stringByAppendingPathComponent:@"StateMachine"];

#define MPIsNull(object) (!(object) || (NSNull *)(object) == [NSNull null])

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
    MPJavascriptMessageTypeOptOut    /** Opt out */
};

typedef NS_ENUM(NSInteger, MPDataType) {
    MPDataTypeString = 1,
    MPDataTypeInt = 2,
    MPDataTypeBool = 3,
    MPDataTypeFloat = 4,
    MPDataTypeLong = 5
};

extern NSUInteger kMPNumberOfMessageTypes;

// mParticle SDK Version
extern NSString *const kMParticleSDKVersion;

// Session Upload Settings
extern NSString *const kMPSessionHistoryValue;

// Message Type (dt)
extern NSString *const kMPMessageTypeKey;                  
extern NSString *const kMPMessageTypeRequestHeader;
extern NSString *const kMPMessageTypeResponseHeader;
extern NSString *const kMPMessageTypeConfig;
extern NSString *const kMPMessageTypeNetworkPerformance;
extern NSString *const kMPMessageTypeLeaveBreadcrumbs;

// Request Header Keys
extern NSString *const kMPmParticleSDKVersionKey;
extern NSString *const kMPApplicationKey;

// Device Information Keys
extern NSString *const kMPDeviceCydiaJailbrokenKey;
extern NSString *const kMPDeviceSupportedPushNotificationTypesKey;

// Launch Keys
extern NSString *const kMPLaunchSourceKey;
extern NSString *const kMPLaunchURLKey;
extern NSString *const kMPLaunchParametersKey;
extern NSString *const kMPLaunchSessionFinalizedKey;
extern NSString *const kMPLaunchNumberOfSessionInterruptionsKey;

// Message Keys
extern NSString *const kMPMessagesKey;                      
extern NSString *const kMPMessageIdKey;                     
extern NSString *const kMPTimestampKey;                   
extern NSString *const kMPSessionIdKey;                     
extern NSString *const kMPSessionStartTimestamp;           
extern NSString *const kMPEventStartTimestamp;              
extern NSString *const kMPEventLength;                     
extern NSString *const kMPEventNameKey;
extern NSString *const kMPEventTypeKey;
extern NSString *const kMPEventLengthKey;
extern NSString *const kMPAttributesKey;                   
extern NSString *const kMPLocationKey;
extern NSString *const kMPUserAttributeKey;
extern NSString *const kMPUserAttributeDeletedKey;
extern NSString *const kMPEventTypePageView;
extern NSString *const kMPUserIdentityArrayKey;
extern NSString *const kMPUserIdentityIdKey;
extern NSString *const kMPUserIdentityTypeKey;
extern NSString *const kMPAppStateTransitionType;
extern NSString *const kMPEventTagsKey;
extern NSString *const kMPLeaveBreadcrumbsKey;
extern NSString *const kMPSessionNumberKey;
extern NSString *const kMPOptOutKey;
extern NSString *const kMPDateUserIdentityWasFirstSet;
extern NSString *const kMPIsFirstTimeUserIdentityHasBeenSet;
extern NSString *const kMPRemoteNotificationCampaignHistoryKey;
extern NSString *const kMPRemoteNotificationContentIdHistoryKey;
extern NSString *const kMPRemoteNotificationTimestampHistoryKey;
extern NSString *const kMPProductBagKey;
extern NSString *const kMPForwardStatsRecord;

// Push Notifications
extern NSString *const kMPDeviceTokenKey;
extern NSString *const kMPPushStatusKey;
extern NSString *const kMPPushMessageTypeKey;
extern NSString *const kMPPushMessageReceived;
extern NSString *const kMPPushMessageAction;
extern NSString *const kMPPushMessageSent;
extern NSString *const kMPPushMessageProviderKey;
extern NSString *const kMPPushMessageProviderValue;
extern NSString *const kMPPushMessagePayloadKey;
extern NSString *const kMPPushNotificationStateKey;
extern NSString *const kMPPushNotificationStateNotRunning;
extern NSString *const kMPPushNotificationStateBackground;
extern NSString *const kMPPushNotificationStateForeground;
extern NSString *const kMPPushNotificationActionIdentifierKey;
extern NSString *const kMPPushNotificationBehaviorKey;
extern NSString *const kMPPushNotificationActionTileKey;
extern NSString *const kMPPushNotificationCategoryIdentifierKey;

// Assorted Keys
extern NSString *const kMPSessionLengthKey;                 
extern NSString *const kMPSessionTotalLengthKey;
extern NSString *const kMPOptOutStatus;
extern NSString *const kMPCrashingSeverity;
extern NSString *const kMPCrashingClass;
extern NSString *const kMPCrashWasHandled;
extern NSString *const kMPErrorMessage;                     
extern NSString *const kMPStackTrace;                       
extern NSString *const kMPCrashSignal;
extern NSString *const kMPTopmostContext;
extern NSString *const kMPPLCrashReport;
extern NSString *const kMPCrashExceptionKey;
extern NSString *const kMPNullUserAttributeString;
extern NSString *const kMPSessionTimeoutKey;
extern NSString *const kMPUploadIntervalKey;
extern NSString *const kMPPreviousSessionLengthKey;
extern NSString *const kMPLifeTimeValueKey;
extern NSString *const kMPIncreasedLifeTimeValueKey;
extern NSString *const kMPPreviousSessionStateFileName;
extern NSString *const kMPHTTPMethodPost;
extern NSString *const kMPHTTPMethodGet;
extern NSString *const kMPPreviousSessionIdKey;
extern NSString *const kMPEventCounterKey;
extern NSString *const kMPProfileChangeTypeKey;
extern NSString *const kMPProfileChangeCurrentKey;
extern NSString *const kMPProfileChangePreviousKey;
extern NSString *const kMPPresentedViewControllerKey;
extern NSString *const kMPMainThreadKey;
extern NSString *const kMPPreviousSessionStartKey;
extern NSString *const kMPAppFirstSeenInstallationKey;
extern NSString *const kMPInfluencedOpenTimerKey;
extern NSString *const kMPResponseURLKey;
extern NSString *const kMPResponseMethodKey;
extern NSString *const kMPResponsePOSTDataKey;
extern NSString *const kMPHTTPHeadersKey;
extern NSString *const kMPHTTPAcceptEncodingKey;
extern NSString *const kMPDeviceTokenTypeKey;
extern NSString *const kMPDeviceTokenTypeDevelopment;
extern NSString *const kMPDeviceTokenTypeProduction;
extern NSString *const kMPHTTPETagHeaderKey;

// Remote configuration
extern NSString *const kMPRemoteConfigExceptionHandlingModeKey;
extern NSString *const kMPRemoteConfigExceptionHandlingModeAppDefined;
extern NSString *const kMPRemoteConfigExceptionHandlingModeForce;
extern NSString *const kMPRemoteConfigExceptionHandlingModeIgnore;
extern NSString *const kMPRemoteConfigNetworkPerformanceModeKey;
extern NSString *const kMPRemoteConfigAppDefined;
extern NSString *const kMPRemoteConfigForceTrue;
extern NSString *const kMPRemoteConfigForceFalse;
extern NSString *const kMPRemoteConfigKitsKey;
extern NSString *const kMPRemoteConfigConsumerInfoKey;
extern NSString *const kMPRemoteConfigCookiesKey;
extern NSString *const kMPRemoteConfigMPIDKey;
extern NSString *const kMPRemoteConfigCustomModuleSettingsKey;
extern NSString *const kMPRemoteConfigCustomModuleIdKey;
extern NSString *const kMPRemoteConfigCustomModulePreferencesKey;
extern NSString *const kMPRemoteConfigCustomModuleLocationKey;
extern NSString *const kMPRemoteConfigCustomModulePreferenceSettingsKey;
extern NSString *const kMPRemoteConfigCustomModuleReadKey;
extern NSString *const kMPRemoteConfigCustomModuleDataTypeKey;
extern NSString *const kMPRemoteConfigCustomModuleWriteKey;
extern NSString *const kMPRemoteConfigCustomModuleDefaultKey;
extern NSString *const kMPRemoteConfigCustomSettingsKey;
extern NSString *const kMPRemoteConfigSandboxModeKey;
extern NSString *const kMPRemoteConfigSessionTimeoutKey;
extern NSString *const kMPRemoteConfigUploadIntervalKey;
extern NSString *const kMPRemoteConfigPushNotificationDictionaryKey;
extern NSString *const kMPRemoteConfigPushNotificationModeKey;
extern NSString *const kMPRemoteConfigPushNotificationTypeKey;
extern NSString *const kMPRemoteConfigLocationKey;
extern NSString *const kMPRemoteConfigLocationModeKey;
extern NSString *const kMPRemoteConfigLocationAccuracyKey;
extern NSString *const kMPRemoteConfigLocationMinimumDistanceKey;
extern NSString *const kMPRemoteConfigLatestSDKVersionKey;
extern NSString *const kMPRemoteConfigRampKey;
extern NSString *const kMPRemoteConfigTriggerKey;
extern NSString *const kMPRemoteConfigTriggerEventsKey;
extern NSString *const kMPRemoteConfigTriggerMessageTypesKey;
extern NSString *const kMPRemoteConfigInfluencedOpenTimerKey;
extern NSString *const kMPRemoteConfigUniqueIdentifierKey;
extern NSString *const kMPRemoteConfigBracketKey;

// Notifications
extern NSString *const kMPCrashReportOccurredNotification;
extern NSString *const kMPConfigureExceptionHandlingNotification;
extern NSString *const kMPRemoteNotificationOpenKey;
extern NSString *const kMPLogRemoteNotificationKey;
extern NSString *const kMPEventCounterLimitReachedNotification;
extern NSString *const kMPRemoteNotificationReceivedNotification;
extern NSString *const kMPUserNotificationDictionaryKey;
extern NSString *const kMPUserNotificationActionKey;
extern NSString *const kMPRemoteNotificationDeviceTokenNotification;
extern NSString *const kMPRemoteNotificationDeviceTokenKey;
extern NSString *const kMPRemoteNotificationOldDeviceTokenKey;
extern NSString *const kMPLocalNotificationReceivedNotification;
extern NSString *const kMPUserNotificationRunningModeKey;

// Config.plist keys
extern NSString *const kMPConfigPlist;
extern NSString *const kMPConfigApiKey;
extern NSString *const kMPConfigSecret;
extern NSString *const kMPConfigSessionTimeout;
extern NSString *const kMPConfigUploadInterval;
extern NSString *const kMPConfigEnableSSL;
extern NSString *const kMPConfigEnableCrashReporting;
extern NSString *const kMPConfigLocationTracking;
extern NSString *const kMPConfigLocationAccuracy;
extern NSString *const kMPConfigLocationDistanceFilter;

// Data connection path/status
extern NSString *const kDataConnectionOffline;
extern NSString *const kDataConnectionMobile;
extern NSString *const kDataConnectionWifi;

// Application State Transition
extern NSString *const kMPASTInitKey;
extern NSString *const kMPASTExitKey;
extern NSString *const kMPASTBackgroundKey;
extern NSString *const kMPASTForegroundKey;
extern NSString *const kMPASTIsFirstRunKey;
extern NSString *const kMPASTIsUpgradeKey;
extern NSString *const kMPASTPreviousSessionSuccessfullyClosedKey;

// Network performance
extern NSString *const kMPNetworkPerformanceMeasurementNotification;
extern NSString *const kMPNetworkPerformanceKey;

// Kits
extern NSString *const MPKitAttributeJailbrokenKey;

// Media Track
extern NSString *const MPMediaTrackActionKey;
extern NSString *const MPMediaTrackPlaybackRateKey;

// mParticle Javascript SDK paths
extern NSString *const kMParticleWebViewSdkScheme;
extern NSString *const kMParticleWebViewPathLogEvent;
extern NSString *const kMParticleWebViewPathSetUserIdentity;
extern NSString *const kMParticleWebViewPathSetUserTag;
extern NSString *const kMParticleWebViewPathRemoveUserTag;
extern NSString *const kMParticleWebViewPathSetUserAttribute;
extern NSString *const kMParticleWebViewPathRemoveUserAttribute;
extern NSString *const kMParticleWebViewPathSetSessionAttribute;

//
// Primitive data type constants
//
extern const NSTimeInterval MINIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval MAXIMUM_SESSION_TIMEOUT;
extern const NSTimeInterval DEFAULT_SESSION_TIMEOUT;
extern const NSTimeInterval TWENTY_FOUR_HOURS; // Database clean up interval
extern const NSTimeInterval ONE_HUNDRED_EIGHTY_DAYS;

// Interval between uploads if not specified
extern const NSTimeInterval DEFAULT_DEBUG_UPLOAD_INTERVAL;
extern const NSTimeInterval DEFAULT_UPLOAD_INTERVAL;

// Delay before processing uploads to allow app to get started
extern const NSTimeInterval INITIAL_UPLOAD_TIME;

extern const NSUInteger EVENT_LIMIT; // maximum number of events per session

// Attributes limits
extern const NSInteger LIMIT_ATTR_COUNT;
extern const NSInteger LIMIT_ATTR_VALUE;
extern const NSInteger LIMIT_NAME;

#endif