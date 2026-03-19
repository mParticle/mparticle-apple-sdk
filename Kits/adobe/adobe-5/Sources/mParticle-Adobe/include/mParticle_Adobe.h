#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double mParticle_AdobeVersionNumber;
FOUNDATION_EXPORT const unsigned char mParticle_AdobeVersionString[];

#if defined(__has_include) && __has_include(<mParticle_Adobe/MPKitAdobe.h>)
    #import <mParticle_Adobe/MPKitAdobe.h>
    #import <mParticle_Adobe/MPIAdobe.h>
#else
    #import "MPKitAdobe.h"
    #import "MPIAdobe.h"
#endif
