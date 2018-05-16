#import "AppDelegate.h"

@import mParticle_Apple_SDK;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Starts the mParticle SDK
    MParticle *mParticle = [MParticle sharedInstance];
    [mParticle startWithKey:@"Your_App_Key" secret:@"Your_App_Secret"];
    
    // Debug log level to the console. The default log level is
    // MPLogLevelWarning (only warning and error log messages are displayed to the console)
    mParticle.logLevel = MPILogLevelDebug;
    
    return YES;
}

@end
