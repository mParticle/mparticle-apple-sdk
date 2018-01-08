#import "AppDelegate.h"

@import mParticle_Apple_SDK;

@interface AppDelegate() <UISplitViewControllerDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    splitViewController.delegate = self;

    // Starts the mParticle SDK
    MParticle *mParticle = [MParticle sharedInstance];
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"Your_App_Key" secret:@"Your_App_Secret"];
    [MParticle.sharedInstance startWithOptions:options];

    // Debug log level to the console. The default log level is
    // MPLogLevelWarning (only warning and error log messages are displayed to the console)
    mParticle.logLevel = MPILogLevelDebug;
    
    return YES;
}

#pragma mark UISplitViewControllerDelegate
- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}

@end
