//
//  Swift.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 3/24/23.
//

#ifndef MPARTICLE_LOCATION_DISABLE
    #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
#else
    #ifndef COCOAPODS
        #import <mParticle_Apple_SDK_NoLocation/mParticle_Apple_SDK-Swift.h>
    #else
        #import <mParticle_Apple_SDK/mParticle_Apple_SDK-Swift.h>
    #endif
#endif
