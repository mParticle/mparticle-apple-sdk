#import "AppDelegate.h"
#import <mParticle_Apple_SDK/mParticle.h>
#import <AdSupport/AdSupport.h>
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import "PLCrashReportTextFormatter+StackTrace.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //initialize mParticle
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"REPLACE WITH APP KEY"
                                                          secret:@"REPLACE WITH APP SECRET"];
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


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
