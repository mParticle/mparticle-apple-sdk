# react-native-mparticle

[![npm version](https://badge.fury.io/js/react-native-mparticle.svg)](https://badge.fury.io/js/react-native-mparticle)
[![Standard - JavaScript Style Guide](https://img.shields.io/badge/code_style-standard-brightgreen.svg)](http://standardjs.com/)

React Native allows developers to use a single code base to deploy features to multiple platforms. With the mParticle React Native library, you can leverage a single API to deploy your data to hundreds of integrations from your iOS and Android apps.

### Supported Features
| Method | Android | iOS |
| ---    | ---     | --- |
| Custom Events | <li> [X] </li> | <li> [X]  </li> |
| Page Views | <li> [X]  </li> | <li> [X]  </li> |
| Identity | <li> [X]  </li> | <li> [X]  </li> |
| eCommerce | <li> [X]  </li> | <li> [X]  </li> |
| Consent | <li> [X]  </li> | <li> [X]  </li> |

# Installation

**Download and install the mParticle React Native library** from npm:

```bash
$ npm install react-native-mparticle --save
```

## <a name="iOS"></a>iOS

1. **Copy your mParticle key and secret** from [your app's dashboard][1].

[1]: https://app.mparticle.com/setup/inputs/apps

2. **Install the SDK** using CocoaPods:

The npm install step above will automatically include our react framework and the core iOS framework in your project. However depending on your app and its other dependecies you must integrate it in 1 of 3 ways

A. Static Libraries are the React Native default but since mParticle iOS contains swift code you need to add an exception for it in the from of a pre-install command in the Podfile.
```bash
pre_install do |installer|
  installer.pod_targets.each do |pod|
    if pod.name == 'mParticle-Apple-SDK'
      def pod.build_type;
        Pod::BuildType.new(:linkage => :dynamic, :packaging => :framework)
      end
    end
  end
end
```
Then run the following command
```
bundle exec pod install
```

B&C. Frameworks are the default for Swift development and while it isn't preferred by React Native it is supported. Additionally you can define whether the frameworks are built staticly or dynamically. 

Update your Podfile to be ready to use dynamically linked frameworks by commenting out the following line
```bash
# :flipper_configuration => flipper_config,
```
Then run either of the following commands
```
$ USE_FRAMEWORKS=static bundle exec pod install
```
or
```
$ USE_FRAMEWORKS=dynamic bundle exec pod install
```

3. Import and start the mParticle Apple SDK into Swift or Objective-C.

The mParticle SDK is initialized by calling the `startWithOptions` method within the `application:didFinishLaunchingWithOptions:` delegate call.

Preferably the location of the initialization method call should be one of the last statements in the `application:didFinishLaunchingWithOptions:`.

The `startWithOptions` method requires an options argument containing your key and secret and an initial Identity request.

> Note that you must initialize the SDK in the `application:didFinishLaunchingWithOptions:` method. Other parts of the SDK rely on the `UIApplicationDidBecomeActiveNotification` notification to function properly. Failing to start the SDK as indicated will impair it. Also, please do **not** use _GCD_'s `dispatch_async` to start the SDK.

For more help, see [the iOS set up docs](https://docs.mparticle.com/developers/sdk/ios/getting-started/#create-an-input).

#### Swift Example

```swift
import mParticle_Apple_SDK

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //override point for customization after application launch.
        let mParticleOptions = MParticleOptions(key: "<<<App Key Here>>>", secret: "<<<App Secret Here>>>")
        
        //optional- Please see the Identity page for more information on building this object
        let request = MPIdentityApiRequest()
        request.email = "email@example.com"
        mParticleOptions.identifyRequest = request
        //optional
        mParticleOptions.onIdentifyComplete = { (apiResult, error) in
            NSLog("Identify complete. userId = %@ error = %@", apiResult?.user.userId.stringValue ?? "Null User ID", error?.localizedDescription ?? "No Error Available")
        }
        //optional
        mParticleOptions.onAttributionComplete = { (attributionResult, error) in
                    NSLog(@"Attribution Complete. attributionResults = %@", attributionResult.linkInfo)
        }
        MParticle.sharedInstance().start(with: mParticleOptions)        
        return true
}
```

#### Objective-C Example

Your import statement should be this:

```objective-c
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
#else
    #import "mParticle.h"
#endif
```

Next, you'll need to start the SDK:

```objective-c
- (BOOL)application:(UIApplication *)application
        didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    MParticleOptions *mParticleOptions = [MParticleOptions optionsWithKey:@"REPLACE ME"
                                                                   secret:@"REPLACE ME"];
    
    //optional - Please see the Identity page for more information on building this object
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithEmptyUser];
    request.email = @"email@example.com";
    mParticleOptions.identifyRequest = request;
    //optional
    mParticleOptions.onIdentifyComplete = ^(MPIdentityApiResult * _Nullable apiResult, NSError * _Nullable error) {
        NSLog(@"Identify complete. userId = %@ error = %@", apiResult.user.userId, error);
    };
    //optional
    mParticleOptions.onAttributionComplete(MPAttributionResult * _Nullable attributionResult, NSError * _Nullable error) {
        NSLog(@"Attribution Complete. attributionResults = %@", attributionResult.linkInfo)
    }
    
    [[MParticle sharedInstance] startWithOptions:mParticleOptions];
    
    return YES;
}
```

See [Identity](http://docs.mparticle.com/developers/sdk/ios/identity/) for more information on supplying an `MPIdentityApiRequest` object during SDK initialization.

4. Remember to start Metro with:
```bash
$ npm start
```
and build your workspace from xCode.


## <a name="Android"></a>Android

1. Copy your mParticle key and secret from [your workspace's dashboard](https://app.mparticle.com/setup/inputs/apps) and construct an `MParticleOptions` object.

2. Call `start` from the `onCreate` method of your app's `Application` class. It's crucial that the SDK be started here for proper session management. If you don't already have an `Application` class, create it and then specify its fully-qualified name in the `<application>` tag of your app's `AndroidManifest.xml`.

For more help, see [the Android set up docs](https://docs.mparticle.com/developers/sdk/android/getting-started/#create-an-input).

```kotlin
package com.example.myapp;

import android.app.Application;
import com.mparticle.MParticle;

class MyApplication : Application() {
    fun onCreate() {
        super.onCreate()
        val options: MParticleOptions = MParticleOptions.builder(this)
            .credentials("REPLACE ME WITH KEY", "REPLACE ME WITH SECRET")
            //optional
            .logLevel(MParticle.LogLevel.VERBOSE)
            //optional
            .identify(identifyRequest)
            //optional
            .identifyTask(
                BaseIdentityTask()
                    .addFailureListener { errorResponse -> }
                    .addSuccessListener{ result -> }
            )
            //optional
            .attributionListener(this)
            .build()
        MParticle.start(options)
    }
}
```

> **Warning:** Don't log events in your `Application.onCreate()`. Android may instantiate your `Application` class in the background without your knowledge, including when the user isn't using their device, and lead to unexpected results. 


# Usage

## Import the mParticle Module

```js
import MParticle from 'react-native-mparticle'
```

## Logging Events

To log basic events:

```js
MParticle.logEvent('Test event', MParticle.EventType.Other, { 'Test key': 'Test value' })
```

To log commerce events:

```js
const product = new MParticle.Product('Test product for cart', '1234', 19.99)
const transactionAttributes = new MParticle.TransactionAttributes('Test transaction id')
const event = MParticle.CommerceEvent.createProductActionEvent(MParticle.ProductActionType.AddToCart, [product], transactionAttributes)

MParticle.logCommerceEvent(event)
```

```js
const promotion = new MParticle.Promotion('Test promotion id', 'Test promotion name', 'Test creative', 'Test position')
const event = MParticle.CommerceEvent.createPromotionEvent(MParticle.PromotionActionType.View, [promotion])

MParticle.logCommerceEvent(event)
```

```js
const product = new MParticle.Product('Test product that was viewed', '5678', 29.99)
const impression = new MParticle.Impression('Test impression list name', [product])
const event = MParticle.CommerceEvent.createImpressionEvent([impression])

MParticle.logCommerceEvent(event)
```

To log screen events:

```js
MParticle.logScreenEvent('Test screen', { 'Test key': 'Test value' })
```

## User

To set, remove, and get user details, call the `User` or `Identity` methods as follows:

```js
MParticle.User.setUserAttribute('User ID', 'Test key', 'Test value')
```

```js
MParticle.User.setUserAttribute('User ID', MParticle.UserAttributeType.FirstName, 'Test first name')
```

```js
MParticle.User.setUserAttributeArray('User ID', 'Test key', ['Test value 1', 'Test value 2'])
```

```js
MParticle.User.setUserTag('User ID', 'Test value')
```

```js
MParticle.User.removeUserAttribute('User ID', 'Test key')
```

```js
MParticle.Identity.getUserIdentities((userIdentities) => {
	console.debug(userIdentities);
});
```

## IdentityRequest

```js
var request = new MParticle.IdentityRequest()
```

**Setting** user identities:

```js
var request = new MParticle.IdentityRequest();
request.setUserIdentity('example@example.com', MParticle.UserIdentityType.Email);
```

## Identity

```js
MParticle.Identity.getCurrentUser((currentUser) => {
    console.debug(currentUser.userID);
});
```

```js
var request = new MParticle.IdentityRequest();

MParticle.Identity.identify(request, (error, userId) => {
    if (error) {
        console.debug(error); //error is an MParticleError
    } else {
        console.debug(userId);
    }
});
```

```js
var request = new MParticle.IdentityRequest();
request.email = 'test email';

MParticle.Identity.login(request, (error, userId) => {
    if (error) {
        console.debug(error); //error is an MParticleError
    } else {
        console.debug(userId);
    }
});
```

```js
var request = new MParticle.IdentityRequest();

MParticle.Identity.logout(request, (error, userId) => {
    if (error) {
        console.debug(error);
    } else {
        console.debug(userId);
    }
});
```

```js
var request = new MParticle.IdentityRequest();
request.email = 'test email 2';

MParticle.Identity.modify(request, (error, userId) => {
    if (error) {
        console.debug(error); //error is an MParticleError
    } else {
        console.debug(userId);
    }
});
```

## Attribution
```
var attributions = MParticle.getAttributions();
```

In order to listen for Attributions asynchronously, you need to set the proper field in `MParticleOptions` as shown in the [Android](#Android) or the [iOS](#iOS) SDK start examples.

## Kits
Check if a kit is active

```
var isKitActive = MParticle.isKitActive(kitId);
```

Check and set the SDK's opt out status

```
var isOptedOut = MParticle.getOptOut();
MParticle.setOptOut(!isOptedOut);
```

## Push Registration

The method `MParticle.logPushRegistration()` accepts 2 parameters. For Android, provide both the `pushToken` and `senderId`. For iOS, provide the push token in the first parameter, and simply pass `null` for the second parameter.

### Android

```
MParticle.logPushRegistration(pushToken, senderId);
```

### iOS

```
MParticle.logPushRegistration(pushToken, null);
```

## GDPR Consent
Add a GDPRConsent

```
var gdprConsent = GDPRConsent()
    .setConsented(true)
    .setDocument("the document")
    .setTimestamp(new Date().getTime())  // optional, native SDK will automatically set current timestamp if omitted
    .setLocation("the location")
    .setHardwareId("the hardwareId");

MParticle.addGDPRConsentState(gdprConsent, "the purpose");
```

Remove a GDPRConsent
```
MParticle.removeGDPRConsentStateWithPurpose("the purpose");
```

## CCPA Consent
Add a CCPAConsent

```
var ccpaConsent = CCPAConsent()
    .setConsented(true)
    .setDocument("the document")
    .setTimestamp(new Date().getTime())  // optional, native SDK will automatically set current timestamp if omitted
    .setLocation("the location")
    .setHardwareId("the hardwareId");

MParticle.addCCPAConsentState(ccpaConsent);
```

Remove CCPAConsent
```
MParticle.removeCCPAConsentState();
```


# License

Apache 2.0
