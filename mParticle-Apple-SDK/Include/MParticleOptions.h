//
//  MParticleOptions.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>

#import "MPEnums.h"

@class MPSideloadedKit;
@class MPNetworkOptions;
@class MPIdentityApiResult;
@class MPAttributionResult;
@class MPDataPlanOptions;
@class MPIdentityApiRequest;
@class MPConsentState;

NS_ASSUME_NONNULL_BEGIN

/**
 Main configuration object for initial SDK setup.
 */
@interface MParticleOptions : NSObject

/**
 Creates an options object with your specified App key and Secret.
 
 These values can be retrieved from your App's dashboard within the mParticle platform.
 */
+ (instancetype)optionsWithKey:(NSString *)apiKey secret:(NSString *)secret;

/*
 App key. mParticle uses this to attribute incoming data to your app's acccount/workspace/platform.
 */
@property (nonatomic, strong, readwrite) NSString *apiKey;

/*
 App secret. An additional authentication token used to produce a signature header required by the server.
 */
@property (nonatomic, strong, readwrite) NSString *apiSecret;

/*
 If you have an App and App Extension, setting this value will share user defaults data between them.
 */
@property (nonatomic, strong, readwrite) NSString *sharedGroupID;


/*
 Allows you to specify a specific installation type, or specify that the SDK should detect automatically.
 
 You can specify that this is a known-install, known-upgrade or known-same-version.
 
 For the first release of your app with the SDK, all users will appear as new to the SDK since it has no persistence.
 To avoid inflated install count, you will want to override this setting from autodetect and specifically
 tell the SDK whether or not this is an install, based on your app's existing persistence mechanisms.
 
 For future releases, the mParticle SDK will already be in the installed app, so you can change this value back to auto detect.
 */
@property (nonatomic, readwrite) MPInstallationType installType;

/*
 This identity request object allows you to customize the information included in the initial Identify request sent by the SDK.
 */
@property (nonatomic, strong, readwrite) MPIdentityApiRequest *identifyRequest;

/*
 SDK Environment. Autodetected as development or production, you can also override.
 */
@property (nonatomic, readwrite) MPEnvironment environment;

/*
 Whether the SDK should automatically collect UIApplicationDelegate information.
 
 If set to NO, you will need to manually add some calls to the SDK within certain AppDelegate methods.
 If set to YES (the default), the SDK will intercept app delegate messages before forwarding them to your app.
 
 This mechanism is acheived using NSProxy and without introducing dangerous swizzling.
 */
@property (nonatomic, readwrite) BOOL proxyAppDelegate;

/*
 Whether the SDK should automatically attempt to measure sessions. Ignored in App Extensions.
 
 If set to YES (the default), the SDK will start a timer when the app enters the background and will end the session if a
 user leaves the app for a configurable number of seconds without bringing it back to foreground.
 
 Note that the above behavior does not apply to apps with long-running background sessions.
 
 Also note that the SDK will still start a session automatically when startWithOptions is called, even if automaticSessionTracking is disabled, unless `shouldBeginSession` is also set to NO.
 @see shouldBeginSession
 */
@property (nonatomic, readwrite) BOOL automaticSessionTracking;

/*
 Whether the SDK should start a session on SDK init. (Defaults to YES.)
 
 The behavior of this flag does not change depending on whether automatic session tracking is enabled.
 
 If set to YES, the SDK will start session immediately when you call `startWithOptions:`
 If set to NO, the SDK will not create a session as as result of `startWithOptions:` being called.
 
 If your application can be launched into the background, you will want to set this to NO in that situation to avoid spurious sessions that do not correspond to user activity.
 You can detect being launched into the background from within `didFinishLaunchingWithOptions:` based on whether `launchOptions[UIApplicationLaunchOptionsRemoteNotificationsKey]["content-available"]` exists and is set to the `NSNumber` value `@1`.
 
 Note that even if this flag is set to NO, the SDK will still create sessions as a result of other application lifecycle events, unless `automaticSessionTracking` is also set to NO.
 */
@property (nonatomic, readwrite) BOOL shouldBeginSession;

/*
 The browser user agent.
 
 This is normally collected by the SDK automatically. If you are already incurring the cost of instantiating
 a webview to collect this, and wish to avoid the performance cost of duplicate work, (or if you need to customize
 the value) you can pass this into the SDK as a string.
 */
@property (nonatomic, strong, nullable) NSString *customUserAgent;

/*
 Whether browser user agent should be collected by the SDK. This value is ignored (always NO) if you specify a non-nil custom user agent.
 */
@property (nonatomic, readwrite) BOOL collectUserAgent;

/*
 Default user agent to be sent in case collecting the browser user agent fails repeatedly, times out or the APIs are unavailable.
 (Ignored if `customUserAgent` is set.) By default, a value of the form "mParticle Apple SDK/<SDK Version>" will be used as a fallback.
 */
@property (nonatomic, copy, readwrite) NSString *defaultAgent;

/*
 Whether the SDK should attempt to collect Apple Search Ads attribution information. Defaults to YES
 */
@property (nonatomic, readwrite) BOOL collectSearchAdsAttribution;

/**
 Determines whether the mParticle Apple SDK will automatically track Remote and Local Notification events. Defaults to YES
 */
@property (nonatomic, readwrite) BOOL trackNotifications;

/*
 This value is not currently read by the SDK and should not be used at this time.
 */
@property (nonatomic, readwrite) BOOL startKitsAsync;

/*
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
 
 Batches of data are sent periodically to the mParticle servers at the rate defined by this property. Batches are also uploaded
 when the application is sent to the background.
 */
@property (nonatomic, readwrite) NSTimeInterval uploadInterval;

/**
 Session timeout.
 
 Sets the user session timeout interval. A session is ended if the app goes into the background for longer than the session timeout interval or when more than 1000 events are logged.
 */
@property (nonatomic, readwrite) NSTimeInterval sessionTimeout;

/**
 Allows you to override the default HTTPS hosts and certificates used by the SDK, if required.
 
 (Provided to accomodate certain advanced use cases. Most integrations of the SDK will not require modifying this property.)
 */
@property (nonatomic, strong, readwrite) MPNetworkOptions *networkOptions;

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

NS_ASSUME_NONNULL_END
