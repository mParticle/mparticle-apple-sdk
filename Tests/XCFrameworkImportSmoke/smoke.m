#import <Foundation/Foundation.h>

@import mParticle_Apple_SDK;
#import <mParticle_AppsFlyer/MPKitAppsFlyer.h>

void mparticle_kit_xcframework_import_smoke(void) {
    (void)NSClassFromString(@"MParticle");
    (void)NSClassFromString(@"MPKitAppsFlyer");
}
