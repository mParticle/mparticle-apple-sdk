#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>
#if defined(__has_include) && __has_include(<mParticle_Apple_SDK/mParticle.h>)
    #import <mParticle_Apple_SDK/mParticle.h>
#elif defined(__has_include) && __has_include(<mParticle_Apple_SDK_NoLocation/mParticle.h>)
    #import <mParticle_Apple_SDK_NoLocation/mParticle.h>
#else
    #import "mParticle.h"
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.moduleName = @"RNExample";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
  
  //override point for customization after application launch.
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
  
  [[MParticle sharedInstance] startWithOptions:mParticleOptions];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self bundleURL];
}

- (NSURL *)bundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

@end
