#import <UIKit/UIKit.h>

//! Project version number for mParticle-Appboy.
FOUNDATION_EXPORT double mParticle_AppboyVersionNumber;

//! Project version string for mParticle-Appboy.
FOUNDATION_EXPORT const unsigned char mParticle_AppboyVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <mParticle_Appboy/PublicHeader.h>

#if defined(__has_include) && __has_include(<mParticle_Appboy/MPKitAppboy.h>)
    #import <mParticle_Braze/MPKitBraze.h>
#else
    #import "MPKitBraze.h"
#endif
