#import "AppDelegate.h"
#import "mParticle.h"
#import "MPKitFirebaseGA4.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[MParticle sharedInstance] startWithOptions:[MParticleOptions optionsWithKey:@"REPLACE WITH YOUR MPARTICLE API KEY" secret:@"REPLACE WITH YOUR MPARTICLE API SECRET"]];
    [MParticle sharedInstance].logLevel = MPILogLevelVerbose;

    [[MParticle sharedInstance] logEvent:[[MPEvent alloc] initWithName:@"foo" type:MPEventTypeOther]];

    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
}


@end
