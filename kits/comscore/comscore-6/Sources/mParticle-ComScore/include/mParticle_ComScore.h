#import <Foundation/Foundation.h>

FOUNDATION_EXPORT double mParticle_ComScoreVersionNumber;
FOUNDATION_EXPORT const unsigned char mParticle_ComScoreVersionString[];

#if defined(__has_include) && __has_include(<mParticle_ComScore/MPKitComScore.h>)
    #import <mParticle_ComScore/MPKitComScore.h>
#else
    #import "MPKitComScore.h"
#endif
