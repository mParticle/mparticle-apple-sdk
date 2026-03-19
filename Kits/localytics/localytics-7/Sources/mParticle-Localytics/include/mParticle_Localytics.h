#import <UIKit/UIKit.h>

//! Project version number for mParticle-Localytics.
FOUNDATION_EXPORT double mParticle_LocalyticsVersionNumber;

//! Project version string for mParticle-Localytics.
FOUNDATION_EXPORT const unsigned char mParticle_LocalyticsVersionString[];

#if defined(__has_include) && __has_include(<mParticle_Localytics/MPKitLocalytics.h>)
    #import <mParticle_Localytics/MPKitLocalytics.h>
#else
    #import "MPKitLocalytics.h"
#endif
