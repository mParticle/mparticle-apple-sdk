#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double mParticle_AdobeMediaVersionNumber;
FOUNDATION_EXPORT const unsigned char mParticle_AdobeMediaVersionString[];

#if defined(__has_include) && __has_include(<mParticle_AdobeMedia/MPKitAdobeMedia.h>)
    #import <mParticle_AdobeMedia/MPKitAdobeMedia.h>
#else
    #import "MPKitAdobeMedia.h"
#endif
