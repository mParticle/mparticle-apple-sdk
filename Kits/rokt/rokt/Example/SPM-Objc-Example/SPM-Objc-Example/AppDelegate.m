#import "AppDelegate.h"
@import mParticle_Apple_SDK;
@import mParticle_Rokt;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[MParticle sharedInstance] startWithOptions:[MParticleOptions optionsWithKey:@"us2-db9c17968390524f8b04a51027f0cc76" secret:@"gGrsbRzGWGRYRefV8w_JMH4xwE8d45-1U1NLkuBwcxiCQHhj4ST0iMkrGuynDmVt"]];
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
