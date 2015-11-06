//
//  mParticle.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MPUserSegments.h"
#import "MPEvent.h"
#import "MPEnums.h"
#import "MPCart.h"
#import "MPCommerce.h"
#import "MPCommerceEvent.h"
#import "MPProduct.h"
#import "MPPromotion.h"
#import "MPTransactionAttributes.h"
#import "MPBags.h"

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
 Enables or disables the inclusion of location information to messages when your app is running on the
 background. The default value is YES. Setting it to NO will cause the SDK to include location
 information only when your app is running on the foreground.
 @see beginLocationTracking:minDistance:
 */
@property (nonatomic, unsafe_unretained) BOOL backgroundLocationTracking;

/**
 This property is an instance of MPBag, which used to describe a product bag to hold the state of products in the hands of a user. Please note a difference
 when compared with a shopping cart. A product bag is intendend to represent product samples shipped for trial by a user, which
 later may return the samples or add one or more to a shopping cart with the intent of purchasing them.
 
 Bags, and products added to them are persisted throughout the lifetime of the application. It is up to you to remove products from
 a bag, and remove bags according to their respective life-cycles in your app.
 
 You should not try to create independent instance of this class, instead you should use this property to perform all product bags operations.
 
 @see MPBags
 */
@property (nonatomic, strong, readonly) MPBags *bags;

/**
 This property is an instance of MPCommerce. It is used to execute transactional operations on the shopping cart.
 @see MPCommerce
 @see MPCart
 */
@property (nonatomic, strong, readonly) MPCommerce *commerce;

/**
 Forwards setting/resetting the debug mode for third party kits.
 This is a write only property.
 */
@property (nonatomic, unsafe_unretained) BOOL debugMode;
- (BOOL)debugMode UNAVAILABLE_ATTRIBUTE;

/**
 Enables or disables log outputs to the console. If set to YES development logs will be output to the
 console, if set to NO the development logs will be suppressed. This property works in conjunction with
 the environment property. If the environment is Production, consoleLogging will always be NO,
 regardless of the value you assign to it.
 @see environment
 @see logLevel
 */
@property (nonatomic, unsafe_unretained) BOOL consoleLogging;

/**
 The environment property returns the running SDK environment: Development or Production.
 @see MPEnvironment
 @see startWithKey:secret:installationType:environment:
 */
@property (nonatomic, unsafe_unretained, readonly) MPEnvironment environment;

/**
 Gets/Sets the current location of the active session.
 @see beginLocationTracking:minDistance:
 */
@property (nonatomic, strong) CLLocation *location;

/**
 Specifies the log level output to the console while the app is under development: none, error, warning, and debug.
 If consoleLogging is set to false, the log level will be set to none automatically. When the environment is
 Production, the log level will always be none, regardless of the value you assign to it.
 @see environment
 */
@property (nonatomic, unsafe_unretained) MPLogLevel logLevel;

/**
 Flag indicating whether network performance is being measured.
 @see beginMeasuringNetworkPerformance
 */
@property (nonatomic, unsafe_unretained, readonly) BOOL measuringNetworkPerformance;

/**
 Gets/Sets the opt-in/opt-out status for the application. Set it to YES to opt-out of event tracking. Set it to NO to opt-in of event tracking.
 */
@property (nonatomic, unsafe_unretained, readwrite) BOOL optOut;

/**
 A flag indicating whether the mParticle SDK has proxied the App Delegate and is handling
 application notifications automatically.
 @see startWithKey:secret:installationType:environment:proxyAppDelegate:
 */
@property (nonatomic, unsafe_unretained, readonly) BOOL proxiedAppDelegate;

/**
 Gets/Sets the push notification token for the application.
 @see registerForPushNotificationWithTypes:
 */
@property (nonatomic, strong) NSData *pushNotificationToken;

/**
 Gets/Sets the user session timeout interval. A session is ended if the app goes into the background for longer than the session timeout interval.
 */
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval sessionTimeout;

/**
 Unique identifier for this app running on this device. This unique identifier is synchronized with the mParticle servers.
 @retuns A string containing the unique identifier or nil, if communication with the server could not yet be established.
 */
@property (nonatomic, strong, readonly) NSString *uniqueIdentifier;

/**
 Gets/Sets the interval to upload data to mParticle servers.
 */
@property (nonatomic, unsafe_unretained, readwrite) NSTimeInterval uploadInterval;

/**
 mParticle SDK version
 */
@property (nonatomic, strong, readonly) NSString *version;

#pragma mark - Initialization

/**
 Returns the shared instance object.
 @returns the Singleton instance of the MParticle class.
 */
+ (instancetype)sharedInstance;

/**
 Starts the API with the api_key and api_secret saved in MParticleConfig.plist.  If you
 use startAPI instead of startAPIWithKey:secret: your API key and secret must
 be added to these parameters in the MParticleConfig.plist.
 @see startWithKey:secret:installationType:environment:
 */
- (void)start;

/**
 Starts the API with your API key and a secret.
 It is required that you use either this method or startAPI to authorize the API before
 using the other API methods.  The apiKey and secret that are passed in to this method
 will override the api_key and api_secret parameters of the (optional) MParticleConfig.plist.
 @param apiKey The API key for your account
 @param secret The API secret for your account
 @see startWithKey:secret:installationType:environment:
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret;

/**
 Starts the API with your API key and a secret and installation type.
 It is required that you use either this method or startAPI to authorize the API before
 using the other API methods.  The apiKey and secret that are passed in to this method
 will override the api_key and api_secret parameters of the (optional) MParticleConfig.plist.
 @param apiKey The API key for your account
 @param secret The API secret for your account
 @param installationType You can tell the mParticle SDK if this is a new install, an upgrade, or let the SDK detect it automatically.
 @param environment The environment property defining the running SDK environment: Development or Production. You can set it to a specific value, or let the
        SDK auto-detect the environment for you. Once the app is deployed to the App Store, setting this parameter will have no effect, since the SDK will set
        the environment to production.
 @see MPInstallationType
 @see MPEnvironment
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType environment:(MPEnvironment)environment;

/**
 Starts the API with your API key and a secret and installation type.
 It is required that you use either this method or startAPI to authorize the API before
 using the other API methods.  The apiKey and secret that are passed in to this method
 will override the api_key and api_secret parameters of the (optional) MParticleConfig.plist.
 @param apiKey The API key for your account
 @param secret The API secret for your account
 @param installationType You can tell the mParticle SDK if this is a new install, an upgrade, or let the SDK detect it automatically.
 @param environment The environment property defining the running SDK environment: Development or Production. You can set it to a specific value, or let the
        SDK auto-detect the environment for you. Once the app is deployed to the App Store, setting this parameter will have no effect, since the SDK will set
        the environment to production.
 @param proxyAppDelegate Flag indicating whether the mParticle SDK should handle logging remote notifications, app launches, and actions automatically. If you set to NO, 
        your app is resposible to calling required methods. Default is YES
 @see MPInstallationType
 @see MPEnvironment
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType environment:(MPEnvironment)environment proxyAppDelegate:(BOOL)proxyAppDelegate;

#pragma mark - Application notifications
/**
 Informs the mParticle SDK a local notification has been received. This method should be called only if proxiedAppDelegate is disabled.
 @param notification A local notification received by the app
 @see proxiedAppDelegate
 */
- (void)didReceiveLocalNotification:(UILocalNotification *)notification;

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
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

/**
 Informs the mParticle SDK the app successfully registered with the push notification service. This method should be called only if proxiedAppDelegate is disabled.
 @param deviceToken A token that identifies the device+App to APNS
 @see proxiedAppDelegate
 */
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

/**
 Informs the mParticle SDK the app has been activated because the user selected a custom action from the alert panel of a local notification. 
 This method should be called only if proxiedAppDelegate is disabled.
 @param identifier The identifier associated with the custom action
 @param notification The local notification object that was triggered
 @see proxiedAppDelegate
 */
- (void)handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification;

/**
 Informs the mParticle SDK the app has been activated because the user selected a custom action from the alert panel of a remote notification.
 This method should be called only if proxiedAppDelegate is disabled.
 @param identifier The identifier associated with the custom action
 @param userInfo A dictionary that contains information related to the remote notification
 @see proxiedAppDelegate
 */
- (void)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo;

/**
 Informs the mParticle SDK the app has been asked to open a resource identified by a URL.
 This method should be called only if proxiedAppDelegate is disabled.
 @param url The URL resource to open
 @param sourceApplication The bundle ID of the requesting app
 @param annotation A property list object supplied by the source app
 @see proxiedAppDelegate
 */
- (void)openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;

/**
 Informs the mParticle SDK the app has been asked to open a resource identified by a URL.
 This method should be called only if proxiedAppDelegate is disabled. This method is only available for iOS 9 and above.
 @param url The URL resource to open
 @param options The dictionary of launch options
 @see proxiedAppDelegate
 */
- (void)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options;

#pragma mark - Basic Tracking
/**
 Begins timing an event. There can be many timed events going on at the same time, the only requirement is that each
 concurrent timed event must have a unique event name. After beginning a timed event you don't have to keep a reference
 to the event instance being timed, you can use the eventWithName: method to retrive it later when ending the timed event.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)beginTimedEvent:(MPEvent *)event;

/**
 Ends timing an event and logs its data to the mParticle SDK. If you didn't keep a reference to the event
 being timed, you can use the eventWithName: method to retrive it.
 @param event An instance of MPEvent
 @see beginTimedEvent:
 */
- (void)endTimedEvent:(MPEvent *)event;

/**
 When working with timed events you don't need to keep a reference to the event being timed. You can use this method
 to retrive the event being timed passing the event name as parameter. If an instance of MPEvent, with a matching
 event name cannot be found, this method will return nil.
 @param eventName A string with the event name associated with the event being timed
 @returns An instance of MPEvent, if one could be found, or nil.
 @see endTimedEvent:
 */
- (MPEvent *)eventWithName:(NSString *)eventName;

/**
 Logs an event. This is one of the most fundamental method of the SDK. Developers define all the characteristics
 of an event (name, type, attributes, etc) in an instance of MPEvent and pass that instance to this method to
 log its data to the mParticle SDK.
 @param event An instance of MPEvent
 @see MPEvent
 */
- (void)logEvent:(MPEvent *)event;

/**
 Logs an event. This is a convenience method for logging simple events; internally it creates an instance of MPEvent
 and calls logEvent:
 @param eventName The name of the event to be logged (required not nil.) The string cannot be longer than 255 characters
 @param eventType An enum value that indicates the type of event to be logged
 @param eventInfo A dictionary containing further information about the event. This dictionary is limited to 100 key
 value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 255 characters), numbers,
 booleans, or dates
 @see logEvent:
 */
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary *)eventInfo;

/**
 Logs a screen event. Developers define all the characteristics of a screen event (name, attributes, etc) in an
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
 value pairs. Keys must be strings (up to 255 characters) and values can be strings (up to 255 characters), numbers,
 booleans, or dates
 @see logScreenEvent:
 */
- (void)logScreen:(NSString *)screenName eventInfo:(NSDictionary *)eventInfo;

#pragma mark - Error, Exception, and Crash Handling
/**
 Enables mParticle exception handling to automatically log events on uncaught exceptions.
 *** Currently unavailable ***
 */
- (void)beginUncaughtExceptionLogging;

/**
 Disables mParticle exception handling.
 *** Currently unavailable ***
 */
- (void)endUncaughtExceptionLogging;

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
- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(NSDictionary *)eventInfo;

/**
 Logs an error with a message.
 @param message The name of the error to be tracked (required not nil)
 @see logError:eventInfo:
 */
- (void)logError:(NSString *)message;

/**
 Logs an error with a message and an attributes dictionary. The eventInfo is limited to
 100 key value pairs. The strings in eventInfo cannot contain more than 255 characters.
 @param message The name of the error event (required not nil)
 @param eventInfo A dictionary containing further information about the error
 */
- (void)logError:(NSString *)message eventInfo:(NSDictionary *)eventInfo;

/**
 Logs an exception.
 @param exception The exception which occured
 @see logException:topmostContext:
 */
- (void)logException:(NSException *)exception;

/**
 Logs an exception and a context.
 @param exception The exception which occured
 @param topmostContext The topmost context of the app, typically the topmost view controller
 */
- (void)logException:(NSException *)exception topmostContext:(id)topmostContext;

#pragma mark - eCommerce Transactions
/**
 Logs a commerce event.
 @param commerceEvent An instance of MPCommerceEvent
 @see MPCommerceEvent
 */
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent;

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
- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(NSDictionary *)eventInfo;

#pragma mark - Kits
/**
 Retrieves the internal instance of a kit, so it can be used to invoke methods and properties of that kit directly.
 
 This method is only applicable to kits that allocate themselves as an object instance or a singleton. For the cases
 where kits are implemented with class methods, you can call those class methods directly
 @param kitInstance The enum representing the kit to be retrieved
 @returns The internal instance of the kit, or nil, if the kit is not active
 */
- (id const)kitInstance:(MPKitInstance)kitInstance;

/**
 Returns whether a kit is active or not. You can retrieve if a kit has been already initialized and
 can be used.
 @param kitInstance The enum representing the kit to be checked
 @returns Whether the kit is active or not.
 */
- (BOOL)isKitActive:(MPKitInstance)kitInstance;

#pragma mark - Location
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

#pragma mark - Network Performance
/**
 Begins measuring and reporting network performance.
 */
- (void)beginMeasuringNetworkPerformance;

/**
 Ends measuring and reporting network performance.
 */
- (void)endMeasuringNetworkPerformance;

/**
 Excludes a URL from network performance measurement. You can call this method multiple times, passing a URL at a time.
 @param url A URL to be removed from measurements
 */
- (void)excludeURLFromNetworkPerformanceMeasuring:(NSURL *)url;

/**
 Allows you to log a network performance measurement independently from the mParticle SDK measurement. In case you use sockets or other
 form of network communication not based on NSURLConnection.
 @param urlString The absolute URL being measured
 @param httpMethod The method used in the network communication (e.g. GET, POST, etc)
 @param startTime The time when the network communication started measured in seconds since Unix Epoch Time: [[NSDate date] timeIntervalSince1970]
 @param duration The number of seconds it took for the network communication took to complete
 @param bytesSent The number of bytes sent
 @param bytesReceived The number of bytes received
 */
- (void)logNetworkPerformance:(NSString *)urlString httpMethod:(NSString *)httpMethod startTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration bytesSent:(NSUInteger)bytesSent bytesReceived:(NSUInteger)bytesReceived;

/**
 By default mParticle SDK will remove the query part of all URLs. Use this method to add an exception to the default
 behavior and include the query compoment of any URL containing queryString. You can call this method multiple times, passing a query string at a time.
 @param queryString A string with the query component to be included and reported in network performance measurement.
 */
- (void)preserveQueryMeasuringNetworkPerformance:(NSString *)queryString;

/**
 Resets all network performance measurement filters and URL exclusions.
 */
- (void)resetNetworkPerformanceExclusionsAndFilters;

#pragma mark - Session management
/**
 Increments the value of a session attribute by the provided amount. If the key does not
 exist among the current session attributes, this method will add the key to the session attributes
 and set the value to the provided amount. If the key already exists and the existing value is not
 a number, the operation will abort and the returned value will be nil.
 @param key The attribute key
 @param value The increment amount
 @returns The new value amount or nil, in case of failure
 */
- (NSNumber *)incrementSessionAttribute:(NSString *)key byValue:(NSNumber *)value;

/**
 Set a single session attribute. The property will be combined with any existing attributes.
 There is a 100 count limit to existing session attributes. Passing in a nil value for an
 existing key will remove the session attribute.
 @param key The attribute key
 @param value The attribute value
 */
- (void)setSessionAttribute:(NSString *)key value:(id)value;

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
- (NSString *)surveyURL:(MPSurveyProvider)surveyProvider;

#pragma mark - User Identity
/**
 Increments the value of a user attribute by the provided amount. If the key does not
 exist among the current user attributes, this method will add the key to the user attributes
 and set the value to the provided amount. If the key already exists and the existing value is not
 a number, the operation will abort and the returned value will be nil.
 @param key The attribute key
 @param value The increment amount
 @returns The new value amount or nil, in case of failure
 */
- (NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value;

/**
 Logs a user out.
 */
- (void)logout;

/**
 Sets a single user attribute. The property will be combined with any existing attributes.
 There is a 100 count limit to user attributes. Passing in an empry string value (@"") for an
 existing key will remove the user attribute.
 @param key The user attribute key
 @param value The user attribute value
 */
- (void)setUserAttribute:(NSString *)key value:(id)value;

/**
 Sets User/Customer Identity
 @param identityString A string representing the user identity
 @param identityType The user identity type
 */
- (void)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType;

/**
 Sets a single user tag or attribute.  The property will be combined with any existing attributes.
 There is a 100 count limit to user attributes.
 @param tag The user tag/attribute
 */
- (void)setUserTag:(NSString *)tag;

/**
 Removes a single user attribute.
 @param key The user attribute key
 */
- (void)removeUserAttribute:(NSString *)key;

#pragma mark - User Segments
/**
 Retrieves user segments from mParticle's servers and returns the result as an array of MPUserSegments objects.
 If the method takes longer than timeout seconds to return, the local cached segments will be returned instead,
 and the newly retrieved segments will update the local cache once the results arrive.
 @param timeout The maximum number of seconds to wait for a response from mParticle's servers. This value can be fractional, like 0.1 (100 milliseconds)
 @param endpointId The endpoint id
 @param completionHandler A block to be called when the results are available. The user segments array is passed to this block
 @returns An array of MPUserSegments objects in the completion handler
 */
- (void)userSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(MPUserSegmentsHandler)completionHandler;

#pragma mark - Web Views
/**
 Updates isIOS flag to true in JS API via given webview.
 @param webView The web view to be initialized
 */
- (void)initializeWebView:(UIWebView *)webView;

/**
 Verifies if the url is mParticle sdk url i.e mp-sdk://
 @param requestUrl The request URL
 */
- (BOOL)isMParticleWebViewSdkUrl:(NSURL *)requestUrl;

/**
 Process log event from hybrid apps that are using iOS UIWebView control.
 @param requestUrl The request URL
 */
- (void)processWebViewLogEvent:(NSURL *)requestUrl;

#pragma mark - Deprecated and/or Unavailable
/**
 @deprecated
 @see environment property
 */
@property (nonatomic, readwrite) BOOL sandboxed __attribute__((unavailable("use the environment property instead")));
- (BOOL)sandboxed UNAVAILABLE_ATTRIBUTE;
- (void)setSandboxed:(BOOL)sandboxed UNAVAILABLE_ATTRIBUTE;

- (void)registerForPushNotificationWithTypes:(UIRemoteNotificationType)pushNotificationTypes __attribute__((unavailable("use Apple's own methods to register for remote notifications.")));
- (void)unregisterForPushNotifications __attribute__((unavailable("use Apple's own methods to unregister from remote notifications.")));

- (void)setEnvironment:(MPEnvironment)environment __attribute__((unavailable("use startWithKey:secret:installationType:environment: to set the running environment.")));

/**
 @deprecated use startWithKey:secret:installationType: instead
 @see environment property
 */
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret sandboxMode:(BOOL)sandboxMode installationType:(MPInstallationType)installationType __attribute__((unavailable("use startWithKey:secret:installationType:environment: instead")));
- (void)startWithKey:(NSString *)apiKey secret:(NSString *)secret installationType:(MPInstallationType)installationType __attribute__((unavailable("use startWithKey:secret:installationType:environment: instead.")));

/**
 @deprecated
 @see logEvent:
 */
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType __attribute__((unavailable("use logEvent: instead")));
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary *)eventInfo eventLength:(NSTimeInterval)eventLength __attribute__((unavailable("use logEvent: instead")));
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(NSDictionary *)eventInfo eventLength:(NSTimeInterval)eventLength category:(NSString *)category __attribute__((unavailable("use logEvent: instead")));

/**
 @deprecated
 @see logScreenEvent:
 */
- (void)logScreen:(NSString *)screenName __attribute__((unavailable("use logScreenEvent: instead")));

/**
 @deprecated
 @see logCommerceEvent:
 */
- (void)logTransaction:(MPProduct *)product __attribute__((unavailable("use logCommerceEvent: instead")));
- (void)logTransaction:(NSString *)productName affiliation:(NSString *)affiliation sku:(NSString *)sku unitPrice:(double)unitPrice quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount taxAmount:(double)taxAmount shippingAmount:(double)shippingAmount __attribute__((unavailable("use logCommerceEvent: instead")));
- (void)logTransaction:(NSString *)productName affiliation:(NSString *)affiliation sku:(NSString *)sku unitPrice:(double)unitPrice quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount taxAmount:(double)taxAmount shippingAmount:(double)shippingAmount transactionId:(NSString *)transactionId __attribute__((unavailable("use logCommerceEvent: instead")));
- (void)logTransaction:(NSString *)productName affiliation:(NSString *)affiliation sku:(NSString *)sku unitPrice:(double)unitPrice quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount taxAmount:(double)taxAmount shippingAmount:(double)shippingAmount transactionId:(NSString *)transactionId productCategory:(NSString *)productCategory __attribute__((unavailable("use logCommerceEvent: instead")));
- (void)logTransaction:(NSString *)productName affiliation:(NSString *)affiliation sku:(NSString *)sku unitPrice:(double)unitPrice quantity:(NSInteger)quantity revenueAmount:(double)revenueAmount taxAmount:(double)taxAmount shippingAmount:(double)shippingAmount transactionId:(NSString *)transactionId productCategory:(NSString *)productCategory currencyCode:(NSString *)currencyCode __attribute__((unavailable("use logCommerceEvent: instead")));

/**
 @deprecated
 @see logCommerceEvent:
 */
- (void)logProductEvent:(MPProductEvent)productEvent product:(MPProduct *)product __attribute__((unavailable("use logCommerceEvent: instead")));

/**
 @deprecated
 */
- (void)beginSession __attribute__((unavailable("Register to receive the mParticleSessionDidBegin notification instead.")));
- (void)endSession __attribute__((unavailable("Register to receive the mParticleSessionDidEnd notification instead.")));

@end
