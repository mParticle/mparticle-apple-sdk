#import "AppDelegate.h"
#import <mParticle_Apple_SDK_ObjC/mParticle.h>
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import "PLCrashReportTextFormatter+StackTrace.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //initialize mParticle
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"REPLACE_WITH_APP_KEY"
                                                          secret:@"REPLACE_WITH_APP_SECRET"];
    MPIdentityApiRequest *identityRequest = [MPIdentityApiRequest requestWithEmptyUser];
    identityRequest.email = @"foo@example.com";
    identityRequest.customerId = @"123456";
    options.identifyRequest = identityRequest;
    options.onIdentifyComplete = ^(MPIdentityApiResult *_Nullable apiResult, NSError *_Nullable error) {
        if (apiResult) {
            [apiResult.user setUserAttribute:@"example attribute key"
                                       value:@"example attribute value"];
        } else {
            //handle failure - see https://docs.mparticle.com/developers/sdk/ios/idsync/#error-handling
        }
    };
    options.logLevel = MPILogLevelVerbose;
    
//    MPNetworkOptions *networkOptions = [[MPNetworkOptions alloc] init];
//    networkOptions.configHost = @"config2-origin-qa1.qa.corp.mparticle.com";
//    networkOptions.eventsHost = @"nativesdks-qa1.qa.corp.mparticle.com";
//    networkOptions.identityHost = @"identity-qa1.qa.corp.mparticle.com";
//    networkOptions.pinningDisabled = true;
//    
//    options.networkOptions = networkOptions;

    [[MParticle sharedInstance] startWithOptions:options];
    
    // An example on how to request IDFA tracking. This does not need to be be done in the App Delegate.
    // Remember to set your NSUserTrackingUsageDescription per https://developer.apple.com/documentation/apptrackingtransparency
    if (@available(iOS 14, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            switch (status) {
                case ATTrackingManagerAuthorizationStatusAuthorized:
                    // Tracking authorization dialog was shown
                    // and we are authorized
                    NSLog(@"Authorized");
                            
                    // Now that we are authorized we can get the IDFA
                    NSLog(@"%@", [ASIdentifierManager sharedManager].advertisingIdentifier);
                    break;
                case ATTrackingManagerAuthorizationStatusDenied:
                    // shown and permission is denied
                    NSLog(@"Denied");
                    break;
                case ATTrackingManagerAuthorizationStatusNotDetermined:
                    // Tracking authorization dialog has not been shown
                    NSLog(@"Not Determined");
                    break;
                case ATTrackingManagerAuthorizationStatusRestricted:
                    NSLog(@"Restricted");
                    break;
                default:
                    NSLog(@"Unknown");
                    break;
            }
        }];
    }
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:
             (UNAuthorizationOptionAlert +
              UNAuthorizationOptionSound + UNAuthorizationOptionBadge)
       completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Fail to Register: %@", error.localizedDescription);
        } else {
            NSLog(@"Notification Request Successful");
        }
    }];
    
    return YES;
}


@end
