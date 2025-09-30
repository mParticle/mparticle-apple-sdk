#import "MPCommerceEvent.h"
#import "MPCommerceEventInstruction.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEnums.h"
#import "MPEvent.h"
#import "MPExtensionProtocol.h"
#import <Foundation/Foundation.h>
#import "MPKitExecStatus.h"
#import "MPKitRegister.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPPromotion.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPIdentityApi.h"
#import "MPKitAPI.h"
#import "MPConsentState.h"
#import "MPListenerController.h"
#import "MPForwardRecord.h"
#import <UIKit/UIKit.h>
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPBackendController.h"
#import "MPApplication.h"
#import "MPNotificationController.h"
#import "MPNetworkCommunication.h"
#import "MPPersistenceController.h"
#import "MPRokt.h"

#if TARGET_OS_IOS == 1
    #ifndef MPARTICLE_LOCATION_DISABLE
        #import <CoreLocation/CoreLocation.h>
    #endif
    #import <WebKit/WebKit.h>
#endif

#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
    #import <UserNotifications/UserNotifications.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class MPSideloadedKit;
@class MPKitContainer;

/**
 An SDK session.
 
 Sessions are typically started and ended automatically by the SDK based on App lifecycle events.
 
 Automatic session management can be disabled if desired and is always disabled in App Extensions.
 
 @see currentSession
 */
@interface MParticleSession : NSObject

/**
 A hash of the session UUID.
 */
@property (nonatomic, readonly) NSNumber *sessionID;

/**
 The session UUID.
 */
@property (nonatomic, readonly) NSString *UUID;

/**
 The session start time.
 */
@property (nonatomic, readonly) NSNumber *startTime;

@end

/**
 Attribution information returned by a kit.
 */
@interface MPAttributionResult : NSObject

/**
 Free-form attribution info dictionary.
 */
@property (nonatomic) NSDictionary *linkInfo;
@property (nonatomic, readonly) NSNumber *kitCode;
@property (nonatomic, readonly) NSString *kitName;

@end

/**
 Allows you to override the default HTTPS hosts and certificates used by the SDK.
 */
@interface MPNetworkOptions : NSObject

/**
Allows you to override the default configuration host.
*/
@property (nonatomic, nullable) NSString *configHost;
/**
Defaults to false. If set true the configHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesConfigSubdirectory;

/**
Allows you to override the default event host.
*/
@property (nonatomic, nullable) NSString *eventsHost;
/**
Allows you to override the tracking event host. Set this to automatically use an alternate custom domain when ATTStatus has been authorized.
*/
@property (nonatomic, nullable) NSString *eventsTrackingHost;
/**
Defaults to false. If set true the eventsHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesEventsSubdirectory;

/**
Allows you to override the default identity host.
*/
@property (nonatomic, nullable) NSString *identityHost;
/**
Allows you to override the tracking identity host. Set this to automatically use an alternate custom domain when ATTStatus has been authorized.
*/
@property (nonatomic, nullable) NSString *identityTrackingHost;
/**
Defaults to false. If set true the identityHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesIdentitySubdirectory;

/**
Allows you to override the default alias host.
*/
@property (nonatomic, nullable) NSString *aliasHost;
/**
Allows you to override the tracking alias host. Set this to automatically use an alternate custom domain when ATTStatus has been authorized.
*/
@property (nonatomic, nullable) NSString *aliasTrackingHost;
/**
Defaults to false. If set true the aliasHost above with overwrite the subdirectory of the URL in addition to the host.
*/
@property (nonatomic) BOOL overridesAliasSubdirectory;

@property (nonatomic) NSArray<NSData *> *certificates;

@property (nonatomic) BOOL pinningDisabledInDevelopment;

@property (nonatomic) BOOL pinningDisabled;
/**
Defaults to false. Prevents the eventsHost above from overwriting the alias endpoint.
*/
@property (nonatomic) BOOL eventsOnly;

@end

/**
 Planning settings for kit blocking
 */
@interface MPDataPlanOptions : NSObject
/**
 Data Plan.
 
 Data plan value (JSON schema) for blocking data to kits.
 */
@property (nonatomic, strong, readwrite, nullable) NSDictionary *dataPlan;

/**
 Whether to block unplanned events from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockEvents;

/**
 Whether to block unplanned event attributes from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockEventAttributes;

/**
 Whether to block unplanned user attributes from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockUserAttributes;

/**
 Whether to block unplanned user identities from being sent to kits, default false
 */
@property (nonatomic, readwrite) BOOL blockUserIdentities;

@end

/**
 Main configuration object for initial SDK setup.
 */
@interface MParticleOptions : NSObject

/**
 Creates an options object with your specified App key and Secret.
 
 These values can be retrieved from your App's dashboard within the mParticle platform.
 */
+ (instancetype)optionsWithKey:(NSString *)apiKey secret:(NSString *)secret;

/**
 App key.
 
 mParticle uses this to attribute incoming data to your app's acccount/workspace/platform.
 */
@property (nonatomic, strong, readwrite) NSString *apiKey;

/**
 App secret. 
 
 An additional authentication token used to produce a signature header required by the server.
 */
@property (nonatomic, strong, readwrite) NSString *apiSecret;

/**
 If you have an App and App Extension, setting this value will share user defaults data between them.
 */
@property (nonatomic, strong, readwrite) NSString *sharedGroupID;


/**
 Allows you to specify a specific installation type, or specify that the SDK should detect automatically.
 
 You can specify that this is a known-install, known-upgrade or known-same-version.
 
 For the first release of your app with the SDK, all users will appear as new to the SDK since it has no persistence.
 To avoid inflated install count, you will want to override this setting from autodetect and specifically
 tell the SDK whether or not this is an install, based on your app's existing persistence mechanisms.
 
 For future releases, the mParticle SDK will already be in the installed app, so you can change this value back to auto detect.
 */
@property (nonatomic, readwrite) MPInstallationType installType;

/**
 This identity request object allows you to customize the information included in the initial Identify request sent by the SDK.
 */
@property (nonatomic, strong, readwrite) MPIdentityApiRequest *identifyRequest;

/**
 SDK Environment. Autodetected as development or production, you can also override.
 */
@property (nonatomic, readwrite) MPEnvironment environment;

/**
 Whether the SDK should automatically collect UIApplicationDelegate information.
 
 If set to NO, you will need to manually add some calls to the SDK within certain AppDelegate methods.
 If set to YES (the default), the SDK will intercept app delegate messages before forwarding them to your app.
 
 This mechanism is acheived using NSProxy and without introducing dangerous swizzling.
 */
@property (nonatomic, readwrite) BOOL proxyAppDelegate;

/**
 Whether the SDK should automatically attempt to measure sessions. Ignored in App Extensions.
 
 If set to YES (the default), the SDK will start a timer when the app enters the background and will end the session if a
 user leaves the app for a configurable number of seconds without bringing it back to foreground.
 
 Note that the above behavior does not apply to apps with long-running background sessions.
 
 Also note that the SDK will still start a session automatically when startWithOptions is called, even if automaticSessionTracking is disabled, unless `shouldBeginSession` is also set to NO.
 @see shouldBeginSession
 */
@property (nonatomic, readwrite) BOOL automaticSessionTracking;

/**
 Whether the SDK should start a session on SDK init. (Defaults to YES.)
 
 The behavior of this flag does not change depending on whether automatic session tracking is enabled.
 
 If set to YES, the SDK will start session immediately when you call `startWithOptions:`
 If set to NO, the SDK will not create a session as as result of `startWithOptions:` being called.
 
 If your application can be launched into the background, you will want to set this to NO in that situation to avoid spurious sessions that do not correspond to user activity.
 You can detect being launched into the background from within `didFinishLaunchingWithOptions:` based on whether `launchOptions[UIApplicationLaunchOptionsRemoteNotificationsKey]["content-available"]` exists and is set to the `NSNumber` value `@1`.
 
 Note that even if this flag is set to NO, the SDK will still create sessions as a result of other application lifecycle events, unless `automaticSessionTracking` is also set to NO.
 */
@property (nonatomic, readwrite) BOOL shouldBeginSession;

/**
 The browser user agent.
 
 This is normally collected by the SDK automatically. If you are already incurring the cost of instantiating
 a webview to collect this, and wish to avoid the performance cost of duplicate work, (or if you need to customize
 the value) you can pass this into the SDK as a string.
 */
@property (nonatomic, strong, nullable) NSString *customUserAgent;

/**
 Whether browser user agent should be collected by the SDK. This value is ignored (always NO) if you specify a non-nil custom user agent.
 */
@property (nonatomic, readwrite) BOOL collectUserAgent;

/**
 Default user agent to be sent in case collecting the browser user agent fails repeatedly, times out or the APIs are unavailable.
 (Ignored if `customUserAgent` is set.) By default, a value of the form "mParticle Apple SDK/<SDK Version>" will be used as a fallback.
 */
@property (nonatomic, copy, readwrite) NSString *defaultAgent;

/**
 Whether the SDK should attempt to collect Apple Search Ads attribution information. Defaults to YES
 */
@property (nonatomic, readwrite) BOOL collectSearchAdsAttribution;

/**
 Determines whether the mParticle Apple SDK will automatically track Remote and Local Notification events. Defaults to YES
 */
@property (nonatomic, readwrite) BOOL trackNotifications;

/**
 This value is not currently read by the SDK and should not be used at this time.
 */
@property (nonatomic, readwrite) BOOL startKitsAsync;

/**
 Log level. (Defaults to 'None'.)
 
 This controls the verbosity of the SDK.
 
 By default the SDK will produce no output. If you modify this for your development builds, please consider using
 a preprocessor directive or similar mechanism to ensure your change is not accidentally applied in production.
 */
@property (nonatomic, readwrite) MPILogLevel logLevel;

/**
 A custom handler callback for mParticle log messages. If set, this block will be invoked each time mParticle would normally log a message to the console.
 N.B.: The format/wording of mParticle log messages may change between releases--please avoid using this programatically to detect SDK behavior unless absolutely necessary, and then only as a temporary workaround.
 */
@property (nonatomic, copy, readwrite) void (^customLogger)(NSString *message);

/**
 Upload interval.
 
 Batches of data are sent periodically to the mParticle servers at the rate defined by this property. This continues while the app is in the background (e.g. playing music).
 */
@property (nonatomic, readwrite) NSTimeInterval uploadInterval;

/**
 Session timeout.
 
 Sets the user session timeout interval. A session is ended if the app goes into the background for longer than the session timeout interval, counted since the last event was logged.
 
 */
@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;

/**
 Allows you to override the default HTTPS hosts and certificates used by the SDK, if required.
 
 (Provided to accomodate certain advanced use cases. Most integrations of the SDK will not require modifying this property.)
 */
@property (nonatomic, strong, readwrite, nullable) MPNetworkOptions *networkOptions;

/**
 Consent state.
 
 Allows you to record one or more consent purposes and whether or not the user agreed to each one.
 */
@property (nonatomic, strong, nullable) MPConsentState *consentState;

/**
 Data Plan ID.
 
 If set, this informs the SDK of which data plan each event is supposed to conform to.
 */
@property (nonatomic, strong, readwrite, nullable) NSString *dataPlanId;

/**
 Data Plan Version.
 
 If set, this informs the SDK of which version of the data plan each event is supposed to conform to.
 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *dataPlanVersion;

/**
 Data Plan Options.
 
 Settings for blocking data to kits
 */
@property (nonatomic, strong, readwrite, nullable) MPDataPlanOptions *dataPlanOptions;

/**
 Disabled Kits.
 
 Include the Kit Integration ID of any kit you'd like to disable
 @see MPKitInstance
 */
@property (nonatomic, strong, readwrite, nullable) NSArray<NSNumber *> *disabledKits;

/**
 Set the App Tracking Transparency Authorization Status upon starting the SDK.
 Only sets a new state if it has changed.
 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *attStatus;

/**
 Set the App Tracking Transparency Authorization Status timestamp upon starting the SDK.
 Requires @attStatus to be set and is only set if the authorization state is different from the stored state.
 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *attStatusTimestampMillis;

/**
 Set a maximum threshold for stored configuration age, in seconds.
 
 When the SDK starts, before we attempt to fetch a fresh config from the server, we
 will load the most recent previous config from disk. when configMaxAgeSeconds is set, we will
 check the timestamp on that config and, if its age is greater than the threshold, instead
 of loading it we will delete it and wait for the fresh config to arrive.
 
 This field is especially useful if your application often updates the kit/forwarding logic and
 has a portion of user's who experience prolonged network interruptions. In these cases, a reasonable
 configMaxAgeSeconds will prevent those users from potentially using very old forwarding logic.
 */
@property (nonatomic, strong, readwrite, nullable) NSNumber *configMaxAgeSeconds;

/**
 Set a maximum threshold for stored events, batches, and sessions, in seconds.
 
 By default, data is persisted for 90 days before being deleted to minimize data loss, however
 this can lead to excessive storage usage on some users' devices. This is exacerbated if you log
 a large number of events, or events with a lot of data (attributes, etc).
 
 You can set this to any value greater than 0 seconds, so if you have storage usage concerns, set a lower
 value such as 48 hours or 1 week. Or alternatively, if you have data loss concerns, you can set this to an even
 longer value than the default.
 */
@property (nonatomic, strong, nullable) NSNumber *persistenceMaxAgeSeconds;

/**
 Set an array of instances of kit (MPKitProtocol wrapped in MPSideloadedKit) objects to be "sideloaded".
 
 The difference between these kits and mParticle UI enabled kits is that they do not receive a server side configuration and are always activated.
 Registration is done locally, and these kits will receive all of the usual MPKitProtocol callback method calls. Some use cases
 include debugging (logging all MPKitProtocol callbacks) and creating custom integrations that are not yet officially supported.
 
 At the moment, all events are forwarded as event filtering is not yet supported. This will come in a future release.
 */
@property (nonatomic, strong, readwrite, nullable) NSArray<MPSideloadedKit*> *sideloadedKits;

/**
 Identify callback.
 
 This will be called when an identify request completes.
 
 This applies to both the initial identify request triggered by the SDK and any identify requests you may send.
 */
@property (nonatomic, copy) void (^onIdentifyComplete)(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error);

/**
 Attribution callback.
 
 This will be called each time a kit returns attribution info.
 */
@property (nonatomic, copy) void (^onAttributionComplete)(MPAttributionResult *_Nullable attributionResult, NSError *_Nullable error);

/**
 Custom handler to modify or block batch data before upload.

 If set, this will be called when a new batch of data is created. By returning a different value, you can change the batch contents, or by returning 'nil' you can block the batch from being uploaded.

 Use with care. This feature was initially added to allow the value of existing fields to be modified. If you add new data in a format that the platform is not expecting, it may be dropped or not parsed correctly.

 Note: Use of this handler will also cause the field 'mb' (modified batch) to appear in the batch so we can distinguish for troubleshooting purposes whether data was changed.
 
 Also note: Unlike other callbacks, this block will be called on the SDK queue to prevent batches from being processed out of order. Please avoid excessively blocking in this handler as this will prevent the SDK from doing other tasks.
 */
@property (nonatomic, copy) NSDictionary *_Nullable (^onCreateBatch)(NSDictionary * batch);

@end

/**
 This is the main class of the mParticle SDK. It interfaces your app with the mParticle API
 so you can report and measure the many different metrics of your app.
 
 <b>Usage:</b>
 
 <b>Swift</b>
 <pre><code>
 let mParticle = MParticle.sharedInstance()
 </code></pre>
 
 <b>Objective-C</b>
 <pre><code>
 MParticle *mParticle = [MParticle sharedInstance];
 </code></pre>
 */
@interface MParticle : NSObject

#pragma mark Properties

/**
 This property is an instance of MPIdentityApi. It allows tracking login, logout, and identity changes.
 @see MPIdentityApi
 @see MParticleUser
 */
@property (nonatomic, strong, readonly) MPIdentityApi * identity;

/**
 This property is an instance of MPRokt. It allows you to access the Rokt SDK through mParticle
 @see MPRokt
 */
@property (nonatomic, strong, readonly) MPRokt * rokt;

/**
 If set to YES development logs will be output to the
 console, if set to NO the development logs will be suppressed. This property works in conjunction with
 the environment property. If the environment is Production, consoleLogging will always be NO,
 regardless of the value you assign to it.
 @see environment
 @see logLevel
 */
@property (nonatomic, readonly) BOOL consoleLogging DEPRECATED_MSG_ATTRIBUTE("set logLevel on MParticleOptions instead");

/**
 The environment property returns the running SDK environment: Development or Production.
 @see MPEnvironment
 @see startWithOptions:
 */
@property (nonatomic, readonly) MPEnvironment environment;

/**
 Flag indicating whether the mParticle SDK has been fully initialized yet or not. You can KVO this property to know when the SDK 
 successfully finishes initializing
 */
@property (nonatomic, readonly) BOOL initialized;

/**
 Specifies the log level output to the console while the app is under development: none, error, warning, and debug.
 When the environment is Production, the log level will always be none, regardless of the value you assign to it.
 @see environment
 */
@property (nonatomic) MPILogLevel logLevel;

/**
 A custom handler callback for mParticle log messages. If set, this block will be invoked each time mParticle would normally log a message to the console.
 N.B.: The format/wording of mParticle log messages may change between releases--please avoid using this programatically to detect SDK behavior unless absolutely necessary, and then only as a temporary workaround.
 @see MParticleOptions
 */
@property (nonatomic, copy, nullable, readwrite) void (^customLogger)(NSString *message);

/**
 Gets/Sets the opt-in/opt-out status for the application. Set it to YES to opt-out of event tracking. Set it to NO to opt-in of event tracking.
 The default value is NO (opt-in of event tracking)
 */
@property (nonatomic, readwrite) BOOL optOut;

/**
 A flag indicating whether the mParticle Apple SDK has proxied the App Delegate and is handling
 application notifications automatically.
 @see startWithOptions:
 */
@property (nonatomic, readonly) BOOL proxiedAppDelegate;

/**
 A flag indicating whether the mParticle Apple SDK is using
 automated Session tracking.
 @see MParticleOptions
 @see shouldBeginSession
 */
@property (nonatomic, readonly) BOOL automaticSessionTracking;

/**
 A flag indicating whether the SDK should start a session on SDK init. (Defaults to YES.)
 @see MParticleOptions
 */
@property (nonatomic, readwrite) BOOL shouldBeginSession;

/**
 The current session. You can access properties for Session ID and UUID.
 */
@property (atomic, strong, nullable, readonly) MParticleSession *currentSession;

/**
 Gets/Sets the user agent to a custom value.
 */
@property (atomic, strong, nullable, readonly) NSString *customUserAgent;

/**
 Determines whether the mParticle Apple SDK will instantiate a webview in order to collect the browser user agent.
 This value is required by attribution providers for fingerprint identification, when device IDs are not available.
 If you disable this flag, consider populating the user agent via the customUserAgent property above if you are using
 an attribution provider (such as Kochava or Tune) via mParticle. Defaults to YES
 */
@property (atomic, readonly) BOOL collectUserAgent;

/**
 Determines whether the SDK will attempt to collect Apple Search Ads attribution information. Defaults to YES
 */
@property (atomic, readonly) BOOL collectSearchAdsAttribution;

/**
 Allows you to proxy SDK traffic by overriding the default network endpoints and certificates used by the SDK.
 @see MParticleOptions
 */
@property (nonatomic, readonly, nullable) MPNetworkOptions *networkOptions;
 
 #if TARGET_OS_IOS == 1
 /**
 Gets/Sets the push notification token for the application.
 */
@property (nonatomic, strong, nullable) NSData *pushNotificationToken;
#endif

/**
 Determines whether the mParticle Apple SDK will automatically track Remote and Local Notification events. Defaults to YES
 */
@property (atomic, readonly) BOOL trackNotifications;

/**
 Gets the user session timeout interval. A session is ended if the app goes into the background for longer than the session timeout interval or when more than 1000 events are logged
 This value is no longer capped, any value from 1.0 to `DBL_MAX` seconds can be chosen.
 */
@property (nonatomic, readonly) NSTimeInterval sessionTimeout;

/**
 Unique identifier for this app running on this device. This unique identifier is synchronized with the mParticle servers.
 @returns A string containing the unique identifier or nil, if communication with the server could not yet be established.
 */
@property (nonatomic, strong, readonly, nullable) NSString *uniqueIdentifier;

/**
 Gets/Sets the interval to upload data to mParticle servers.
 
 Batches of data are sent periodically to the mParticle servers at the rate defined by the uploadInterval. Batches are also uploaded
 when the application is sent to the background or before they are terminated. When set, an upload is performed immediately before the sdk adheres to the new upload interval.
 The minimum uploadInterval is 1 second (1.0). The default uploadInterval is 10 minutes (600.0) on iOS and 6 seconds (6.0) on tvOS.
 */
@property (nonatomic, readwrite) NSTimeInterval uploadInterval;

/**
 mParticle Apple SDK version
 */
@property (nonatomic, strong, readonly) NSString *version;

/**
 Data plan id
 */
@property (nonatomic, strong, readonly) NSString *dataPlanId;

/**
 Data plan version
 */
@property (nonatomic, strong, readonly) NSNumber *dataPlanVersion;

/**
 Sets data plan options for kit blocking
 @see MParticleOptions
 */
@property (nonatomic, readonly) MPDataPlanOptions *dataPlanOptions;

/**
 Maximum threshold for stored configuration age, in seconds.
 @see MParticleOptions
 */
@property (nonatomic, readonly, nullable) NSNumber *configMaxAgeSeconds;

/**
 Maximum threshold for stored events, batches, and sessions, in seconds.
 @see MParticleOptions
 */
@property (nonatomic, readonly, nullable) NSNumber *persistenceMaxAgeSeconds;

/**
 The instance which manages all initialized kits. For internal use only
 */
@property (nonatomic, strong, readonly) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

/**
 The Kit Configuration needed should the initialization of kits need to be deferred until identity or consent is resolve. For internal use only
 */
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *deferredKitConfiguration_PRIVATE;

#pragma mark - Initialization

/**
 Returns the shared instance object.
 @returns the Singleton instance of the MParticle class.
 */
+ (instancetype)sharedInstance;

/**
 Starts the SDK with your API key and secret and installation type.
 It is required that you use either this method to authorize the SDK before
 using the other API methods. The apiKey and secret that are passed in to this method
 will override the `api_key` and `api_secret` parameters of the (optional) MParticleConfig.plist.
 @param options SDK startup options
 */
- (void)startWithOptions:(MParticleOptions *)options;

/**
 Switches the SDK to a new API key and secret.
 
 Will first batch all events that have not been sent to mParticle into upload records,
 then all SDK state including user defaults, database (except uploads), etc will be
 completely reset. After that, `startWithOptions` will be called with the new
 key and secret and the SDK will initialize again as if it is a new app launch.
 
 Any kits that do not implement the `stop` method will be deactivated and will
 not receive any events until the app is restarted. Any kits that were not used by the
 previous workspace will continue to be available even if they don't implement `stop`.
 Any sideloaded kits will need new instances passed in via `options.sideloadedKits`.
 It is recommended to implement the `stop` in all sideloaded kits, though if it is not
 implemented then the old instances will still not receive any new events.
 
 The apiKey and secret that are passed in to this method will override the `api_key`
 and `api_secret` parameters of the (optional) MParticleConfig.plist.
 
 @param options SDK startup options
 */
- (void)switchWorkspaceWithOptions:(MParticleOptions *)options;

#pragma mark - Application notifications
#if TARGET_OS_IOS == 1

/**
 Informs the mParticle SDK a remote notification has been received. This method should be called only if proxiedAppDelegate is disabled.
 @param userInfo A dictionary containing information related to the remote notification
 @see proxiedAppDelegate
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

/**
 Informs the mParticle SDK the push notification service could not complete the registration process. This method should be called only if proxiedAppDelegate is disabled.
 @param error An NSError object encapsulating the information why registration did not succeed
 @see proxiedAppDelegate
 */
- (void)didFailToRegisterForRemoteNotificationsWithError:(nullable NSError *)error;

/**
 Informs the mParticle SDK the app successfully registered with the push notification service. This method should be called only if proxiedAppDelegate is disabled.
 @param deviceToken A token that identifies the device+App to APNS
 @see proxiedAppDelegate
 */
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 Informs the mParticle SDK the app has been activated because the user selected a custom action from the alert panel of a remote notification.
 This method should be called only if proxiedAppDelegate is disabled.
 @param identifier The identifier associated with the custom action
 @param userInfo A dictionary that contains information related to the remote notification
 @see proxiedAppDelegate
 */
- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo;

/**
 Informs the mParticle SDK the app has been activated because the user selected a custom action from the alert panel of a remote notification.
 This method should be called only if proxiedAppDelegate is disabled.
 @param identifier The identifier associated with the custom action
 @param userInfo A dictionary that contains information related to the remote notification
 @param responseInfo The data dictionary sent by the action
 @see proxiedAppDelegate
 */
- (void)handleActionWithIdentifier:(nullable NSString *)identifier forRemoteNotification:(nullable NSDictionary *)userInfo withResponseInfo:(nonnull NSDictionary *)responseInfo;

#endif

/**
 Informs the mParticle SDK the app has been asked to open a resource identified by a URL.
 This method should be called only if proxiedAppDelegate is disabled.
 @param url The URL resource to open
 @param sourceApplication The bundle ID of the requesting app
 @param annotation A property list object supplied by the source app
 @see proxiedAppDelegate
 */
- (void)openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nullable id)annotation;

/**
 Informs the mParticle SDK the app has been asked to open a resource identified by a URL.
 This method should be called only if proxiedAppDelegate is disabled. This method is only available for iOS 9 and above.
 @param url The URL resource to open
 @param options The dictionary of launch options
 @see proxiedAppDelegate
 */
- (void)openURL:(NSURL *)url options:(nullable NSDictionary *)options;

/**
 Informs the mParticle SDK the app has been asked to open to continue an NSUserActivity.
 This method should be called only if proxiedAppDelegate is disabled. This method is only available for iOS 9 and above.
 @param userActivity The NSUserActivity that caused the app to be opened
 @param restorationHandler A block to execute if your app creates objects to perform the task.
 @see proxiedAppDelegate
 */
- (BOOL)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray<id<UIUserActivityRestoring>> * __nullable restorableObjects))restorationHandler;

/**
 DEPRECATED: This method will permanently remove ALL MParticle data from the device, including MParticle UserDefaults and Database, it will also halt any further upload or download behavior that may be prepared
 
 NOTE: This method is less comprehensive than the new `reset:` method. It resets less state and is called within a `dispatch_sync()` which has the potential to deadlock in rare cases.

 If you have any reference to the MParticle instance, you must remove your reference by setting it to "nil", in order to avoid any unexpected behavior
 The SDK will be shut down and [MParticle sharedInstance] will return a new instance without apiKey or secretKey. MParticle can be restarted by calling MParticle.startWithOptions
 */
- (void)reset DEPRECATED_MSG_ATTRIBUTE("replace calls to `reset` with `reset:` and a completion handler");

/**
 This method will permanently remove ALL MParticle data from the device, including MParticle UserDefaults and Database, it will also halt any further upload or download behavior that may be prepared

 If you have any reference to the MParticle instance, you must remove your reference by setting it to "nil", in order to avoid any unexpected behavior
 The SDK will be shut down and [MParticle sharedInstance] will return a new instance without apiKey or secretKey. MParticle can be restarted by calling MParticle.startWithOptions
 
 @param completion A block to execute on the main thread after the SDK is completely reset
 */
- (void)reset:(nullable void (^)(void))completion;

#pragma mark - Basic Tracking
/**
 Contains a collection with all active timed events (timed events that had begun, but not yet ended). You should not keep a 
 separate reference collection containing the events being timed. The mParticle SDK manages the lifecycle of those events.
 @see beginTimedEvent:
 @returns A set with all active timed events
 */
- (nullable NSSet *)activeTimedEvents;

/**
 Begins timing an event. There can be many timed events going on at the same time, the only requirement is that each
 concurrent timed event must have a unique event name. After beginning a timed event you don't have to keep a reference
 to the event instance being timed, you can use the eventWithName: method to retrieve it later when ending the timed event.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)beginTimedEvent:(MPEvent *)event;

/**
 Ends timing an event and logs its data to the mParticle SDK. If you didn't keep a reference to the event
 being timed, you can use the eventWithName: method to retrieve it.
 @param event An instance of MPEvent
 @see beginTimedEvent:
 */
- (void)endTimedEvent:(MPEvent *)event;

/**
 When working with timed events you don't need to keep a reference to the event being timed. You can use this method
 to retrieve the event being timed passing the event name as parameter. If an instance of MPEvent, with a matching
 event name cannot be found, this method will return nil.
 @param eventName A string with the event name associated with the event being timed
 @returns An instance of MPEvent, if one could be found, or nil.
 @see endTimedEvent:
 */
- (nullable MPEvent *)eventWithName:(NSString *)eventName;

/**
 Logs an event. This is one of the most fundamental methods of the SDK. You can define all the characteristics
 of an event in an instance of MPEvent, MPCommerceEvent, or any other subclass of MPBaseEvent and pass that instance to this
 method to log its data to the mParticle SDK.
 @param event An instance of a subclass of MPBaseEvent (e.g MPEvent, MPCommerceEvent)
 @see MPEvent
 @see MPCommerceEvent
 */
- (void)logEvent:(MPBaseEvent *)event;

/**
 Logs an event. This is a convenience method for logging simple events; internally it creates an instance of MPEvent
 and calls logEvent:
 @param eventName The name of the event to be logged (required not nil.) The string cannot be longer than 255 characters
 @param eventType An enum value that indicates the type of event to be logged
 @param eventInfo A dictionary containing further information about the event. This dictionary is limited to 100 key
                  value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 4096 characters),
                  numbers, booleans, or dates
 @see logEvent:
 */
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;
/**
 Logs a screen event. You can define all the characteristics of a screen event (name, attributes, etc) in an
 instance of MPEvent and pass that instance to this method to log its data to the mParticle SDK.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)logScreenEvent:(MPEvent *)event;

/**
 Logs a screen event. This is a convenience method for logging simple screen events; internally it creates an instance
 of MPEvent and calls logScreenEvent:
 @param screenName The name of the screen to be logged (required not nil and up to 255 characters)
 @param eventInfo A dictionary containing further information about the screen. This dictionary is limited to 100 key
 value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 4096 characters), numbers,
 booleans, or dates
 @see logScreenEvent:
 */
- (void)logScreen:(NSString *)screenName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

/**
 Logs a screen event and gives developer option to choose whether this screen event should be uploaded to mParticle when logged or only passed to kits. This is a convenience method for logging simple screen events; internally it creates an instance
 of MPEvent and calls logScreenEvent:
 @param screenName The name of the screen to be logged (required not nil and up to 255 characters)
 @param eventInfo A dictionary containing further information about the screen. This dictionary is limited to 100 key
 value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 4096 characters), numbers,
 booleans, or dates
 @param shouldUploadEvent A boolean flag that indicates whether this screen event should be uploaded to mParticle when logged or only passed to kits
 @see logScreenEvent:
 */
- (void)logScreen:(NSString *)screenName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo shouldUploadEvent:(BOOL)shouldUploadEvent;

/**
 Sets the ATT Authorization state with the supplied timestamp, or uses the current time if none is supplied.
 @param status The authorization state of ATT, determines whether the user has approved access to app-related data that can be used for tracking the user or the device.
 @param attStatusTimestampMillis The time at which the authorization status change. If not supplied, current time will be used.
 @see MPCurrentEpochInMilliseconds - Please provide the timestamp in milliseconds
 @see MPIdentityIOSAdvertiserId
 */
- (void)setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:(nullable NSNumber *)attStatusTimestampMillis;

#pragma mark - Attribution
/**
 Convenience method for getting the most recently retrieved attribution info for all kits.
 @returns A dictionary containing the most recent attribution info that was retrieved by each kit
 @see MPKitInstance
 */
- (nullable NSDictionary<NSNumber *, MPAttributionResult *> *)attributionInfo;

#pragma mark - Error, Exception, and Crash Handling

/**
 Leaves a breadcrumb. Breadcrumbs are send together with crash reports to help with debugging.
 @param breadcrumbName The name of the breadcrumb (required not nil)
 */
- (void)leaveBreadcrumb:(NSString *)breadcrumbName;

/**
 Leaves a breadcrumb. Breadcrumbs are send together with crash reports to help with debugging.
 @param breadcrumbName The name of the breadcrumb (required not nil)
 @param eventInfo A dictionary containing further information about the breadcrumb
 */
- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

/**
 Logs an error with a message.
 @param message The name of the error to be tracked (required not nil)
 @see logError:eventInfo:
 */
- (void)logError:(NSString *)message;

/**
 Logs an error with a message and an attributes dictionary. The eventInfo is limited to
 100 key value pairs. The values in eventInfo cannot contain more than 4096 characters.
 @param message The name of the error event (required not nil)
 @param eventInfo A dictionary containing further information about the error
 */
- (void)logError:(NSString *)message eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

/**
 Logs an exception.
 @param exception The exception which occurred
 @see logException:topmostContext:
 */
- (void)logException:(NSException *)exception;

/**
 Logs an exception and a context.
 @param exception The exception which occurred
 @param topmostContext The topmost context of the app, typically the topmost view controller
 */
- (void)logException:(NSException *)exception topmostContext:(nullable id)topmostContext;

/**
 Logs a crash report with additional exception information.
 @param message An error message to associate with the crash which occurred
 @param stackTrace The stack trace from the crash which occurred
 @param plCrashReport Plausible Labs crash report file (required not nil)
 */
- (void)logCrash:(nullable NSString *)message
      stackTrace:(nullable NSString *)stackTrace
   plCrashReport:(NSString *)plCrashReport;

#pragma mark - eCommerce Transactions
/**
 Logs a commerce event.
 @param commerceEvent An instance of MPCommerceEvent
 @see MPCommerceEvent
 */
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent DEPRECATED_MSG_ATTRIBUTE("Replace calls to `logCommerceEvent:` with `logEvent:`");

/**
 Increases the LTV (LifeTime Value) amount of a user.
 @param increaseAmount The amount to be added to LTV
 @param eventName The name of the event (Optional). If not applicable, pass nil
 */
- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName;

/**
 Increases the LTV (LifeTime Value) amount of a user.
 @param increaseAmount The amount to be added to LTV
 @param eventName The name of the event (Optional). If not applicable, pass nil
 @param eventInfo A dictionary containing further information about the LTV
 */
- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;

#pragma mark - Extensions
/**
 Registers an extension against the code mParticle SDK. Extensions are external code, unknown to the core SDK, which
 conform to one of more known protocols. They allow the core SDK to function in ways beyond its core functionality.
 @param extension An instance of a class conforming to a MPExtensionProtocol specialization
 @see MPExtensionProtocol
 */
+ (BOOL)registerExtension:(id<MPExtensionProtocol>)extension;

#pragma mark - Integration Attributes

/**
 * Set the integration attributes for a given integration ID.
 *
 * Integration attributes are keys and values specific to a given integration. For example,
 * many integrations have their own internal user/device ID. mParticle will store integration attributes
 * for a given device, and will be able to use these values for server-to-server communication to services.
 * This is often useful when used in combination with a server-to-server feed, allowing the feed to be enriched
 * with the necessary integration attributes to be properly forwarded to the given integration.
 *
 * Note: this action will be performed asynchronously.
 *
 * @param attributes a dictionary of attributes that will replace any current attributes. The keys are predefined by mParticle.
 *                   Please consult with the mParticle docs or your solutions consultant for the correct value. You may
 *                   also pass a null or empty map here to remove all of the attributes.
 * @param integrationId mParticle integration ID. This may be the ID for a kit, or any mParticle integration.
 * @see MPKitInstance
 */
- (MPKitExecStatus *)setIntegrationAttributes:(NSDictionary<NSString *, NSString *> *)attributes forKit:(NSNumber *)integrationId;

/**
 * Clear the integration attributes for a given integration ID.
 *
 * Integration attributes are keys and values specific to a given integration. For example,
 * many integrations have their own internal user/device ID. mParticle will store integration attributes
 * for a given device, and will be able to use these values for server-to-server communication to services.
 * This is often useful when used in combination with a server-to-server feed, allowing the feed to be enriched
 * with the necessary integration attributes to be properly forwarded to the given integration.
 *
 * Note: this action will be performed asynchronously.
 *
 * @param integrationId mParticle integration ID. This may be the ID for a kit, or any mParticle integration.
 * @see MPKitInstance
 */
- (MPKitExecStatus *)clearIntegrationAttributesForKit:(NSNumber *)integrationId;

/**
 * Get the integration attributes for a given integration ID.
 *
 * Integration attributes are keys and values specific to a given integration. For example,
 * many integrations have their own internal user/device ID. mParticle will store integration attributes
 * for a given device, and will be able to use these values for server-to-server communication to services.
 * This is often useful when used in combination with a server-to-server feed, allowing the feed to be enriched
 * with the necessary integration attributes to be properly forwarded to the given integration.
 *
 * Note: this will make a direct call to SQLite and should not be called on the main thread.
 *
 * @param integrationId mParticle integration ID. This may be the ID for a kit, or any mParticle integration.
 * @see MPKitInstance
 */
- (nullable NSDictionary *)integrationAttributesForKit:(NSNumber *)integrationId;

#pragma mark - Kits
/**
 Allows you to schedule code to run after all kits have been initialized. If kits have already been initialized,
 your block will be invoked immediately. If not, your block will be copied and the copy will be invoked once
 kit initialization is finished.
 @param block A block to be invoked once kits are initialized
 */
- (void)onKitsInitialized:(void(^)(void))block;

/**
 Returns whether a kit is active or not. You can retrieve if a kit has been already initialized and
 can be used.
 @param integrationId An NSNumber representing the kit to be checked
 @returns Whether the kit is active or not.
 */
- (BOOL)isKitActive:(NSNumber *)integrationId;

/**
 Retrieves the internal instance of a kit, for cases where you need to use properties and methods of that kit directly.
 
 This method is only applicable to kits that allocate themselves as an object instance or as a singleton. For the cases
 where kits are implemented with class methods, you can call those class methods directly
 @param integrationId An NSNumber representing the kit to be retrieved
 @returns The internal instance of the kit, or nil, if the kit is not active
 @see MPKitInstance
 */
- (nullable id const)kitInstance:(NSNumber *)integrationId;

/**
 Asynchronously retrieves the internal instance of a kit, for cases where you need to use properties and methods of that kit directly.
 
 This method is only applicable to kits that allocate themselves as an object instance or as a singleton. For the cases
 where kits are implemented with class methods, you can call those class methods directly
 @param kitCode An NSNumber representing the kit to be retrieved
 @param completionHandler A block to be called if or when the kit instance becomes available. If the kit never becomes
 active, the block will never be called. If the kit is class based, the instance will be nil
 @see MPKitInstance
 */
- (void)kitInstance:(NSNumber *)kitCode completionHandler:(void (^)(id _Nullable kitInstance))completionHandler;

#pragma mark - Location
#if TARGET_OS_IOS == 1
/**
 Enables or disables the inclusion of location information to messages when your app is running on the
 background. The default value is YES. Setting it to NO will cause the SDK to include location
 information only when your app is running on the foreground.
 @see beginLocationTracking:minDistance:
 */
@property (nonatomic) BOOL backgroundLocationTracking;

#ifndef MPARTICLE_LOCATION_DISABLE
/**
 Gets/Sets the current location of the active session.
 @see beginLocationTracking:minDistance:
 */
@property (nonatomic, strong, nullable) CLLocation *location;

/**
 Begins geographic location tracking.
 
 The desired accuracy of the location is determined by a passed in constant for accuracy.
 Choices are kCLLocationAccuracyBestForNavigation, kCLLocationAccuracyBest,
 kCLLocationAccuracyNearestTenMeters, kCLLocationAccuracyHundredMeters,
 kCLLocationAccuracyKilometer, and kCLLocationAccuracyThreeKilometers.
 @param accuracy The desired accuracy
 @param distanceFilter The minimum distance (measured in meters) a device must move before an update event is generated.
 */
- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter;

/**
 Begins geographic location tracking.
 
 The desired accuracy of the location is determined by a passed in constant for accuracy.
 Choices are kCLLocationAccuracyBestForNavigation, kCLLocationAccuracyBest,
 kCLLocationAccuracyNearestTenMeters, kCLLocationAccuracyHundredMeters,
 kCLLocationAccuracyKilometer, and kCLLocationAccuracyThreeKilometers.
 @param accuracy The desired accuracy
 @param distanceFilter The minimum distance (measured in meters) a device must move before an update event is generated.
 @param authorizationRequest Type of authorization requested to use location services
 */
- (void)beginLocationTracking:(CLLocationAccuracy)accuracy minDistance:(CLLocationDistance)distanceFilter authorizationRequest:(MPLocationAuthorizationRequest)authorizationRequest;

/**
 Ends geographic location tracking.
 */
- (void)endLocationTracking;
#endif
#endif

#pragma mark - Network Performance
/**
 Allows you to log a network performance measurement independently from the mParticle SDK measurement. 
 @param urlString The absolute URL being measured
 @param httpMethod The method used in the network communication (e.g. GET, POST, etc)
 @param startTime The time when the network communication started measured in seconds since Unix Epoch Time: [[NSDate date] timeIntervalSince1970]
 @param duration The number of seconds it took for the network communication took to complete
 @param bytesSent The number of bytes sent
 @param bytesReceived The number of bytes received
 */
- (void)logNetworkPerformance:(NSString *)urlString httpMethod:(NSString *)httpMethod startTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration bytesSent:(NSUInteger)bytesSent bytesReceived:(NSUInteger)bytesReceived;

#pragma mark - Session management
/**
 Increments the value of a session attribute by the provided amount. If the key does not
 exist among the current session attributes, this method will add the key to the session attributes
 and set the value to the provided amount. If the key already exists and the existing value is not
 a number, the operation will abort.
 
 Note: this method has been changed to be async, return value will always be @0.
 
 @param key The attribute key
 @param value The increment amount
 @returns The static value @0
 */
- (nullable NSNumber *)incrementSessionAttribute:(NSString *)key byValue:(NSNumber *)value;

/**
 Set a single session attribute. The property will be combined with any existing attributes.
 There is a 100 count limit to existing session attributes. Passing in a nil value for an
 existing key will remove the session attribute.
 @param key The attribute key
 @param value The attribute value
 */
- (void)setSessionAttribute:(NSString *)key value:(nullable id)value;

/**
 Manually begins a new session. Calling this method is a no-op if a session already exists.
 */
- (void)beginSession;

/**
 Manually ends the current session. Calling this method is a no-op if no session exists.
 */
- (void)endSession;

/**
 Force uploads queued messages to mParticle.
 */
- (void)upload;

#pragma mark - Surveys
/**
 Returns the survey URL for a given provider.
 @param surveyProvider The survey provider
 @returns A string with the URL to the survey
 @see MPSurveyProvider
 */
- (nullable NSString *)surveyURL:(MPSurveyProvider)surveyProvider;


#pragma mark - User Notifications
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
/**
 Informs the mParticle SDK that the app has received a user notification while in the foreground.
 @param center The notification center that received the notification
 @param notification The notification that is about to be delivered
 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification NS_AVAILABLE_IOS(10.0);

/**
 Informs the mParticle SDK that the user has interacted with a given notification
 @param center The notification center that received the notification
 @param response The user’s response to the notification
 */
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response NS_AVAILABLE_IOS(10.0);
#endif


#pragma mark - Web Views
#if TARGET_OS_IOS == 1
/**
 Create a bridge between the mParticle web SDK and iOS SDK.
 
 This API will add a persistent [WKScriptMessageHandler](https://developer.apple.com/documentation/webkit/wkscriptmessagehandler) to the given `WKWebView`, signaling to the mParticle web SDK that it should delegate all API calls out to the native iOS SDK, rather than sending API calls directly. Note that this handler will persist across page loads.
 @param webView The web view to be initialized
 */
- (void)initializeWKWebView:(WKWebView *)webView;

/**
 Create a bridge between the mParticle web SDK and iOS SDK.
 
 This API will add a persistent [WKScriptMessageHandler](https://developer.apple.com/documentation/webkit/wkscriptmessagehandler) to the given `WKWebView`, signaling to the mParticle web SDK that it should delegate all API calls out to the native iOS SDK, rather than sending API calls directly. Note that this handler will persist across page loads.
 @param webView The web view to be initialized
 @param bridgeName The name of the webview bridge
 */
- (void)initializeWKWebView:(WKWebView *)webView bridgeName:(nullable NSString *)bridgeName;

#pragma mark - Manual Notification logging
/**
 Logs a Notification event for a notification that has been reviewed but not acted upon. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only set Notification manually:
 */
- (void)logNotificationReceivedWithUserInfo:(nonnull NSDictionary *)userInfo;

/**
 Logs a Notification event for a notification that has been reviewed and acted upon. This is a convenience method for manually logging Notification events; Set trackNotifications to false on MParticleOptions to disable automatic tracking of Notifications and only set Notification manually:
 */
- (void)logNotificationOpenedWithUserInfo:(nonnull NSDictionary *)userInfo andActionIdentifier:(nullable NSString *)actionIdentifier;

#endif

#pragma mark - Wrapper SDK Information

/**
 Internal use only. Used by our wrapper SDKs to identify themselves during initialization.
 */
+ (void)_setWrapperSdk_internal:(MPWrapperSdk)wrapperSdk version:(nonnull NSString *)wrapperSdkVersion;

/**
 Internal use only. Used by our SDK to determine if configuration needs refreshed.
 */
+ (BOOL)isOlderThanConfigMaxAgeSeconds;

@end

NS_ASSUME_NONNULL_END
