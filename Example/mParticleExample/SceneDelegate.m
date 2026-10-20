#import "SceneDelegate.h"
#import <mParticle_Apple_SDK_ObjC/mParticle.h>

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    [self scene:scene openURLContexts:connectionOptions.URLContexts];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    // Forward payment redirects on both launch and subsequent scene activations.
    for (UIOpenURLContext *context in URLContexts) {
        [[MParticle sharedInstance].rokt handleURLCallback:context.URL];
    }
}

@end
