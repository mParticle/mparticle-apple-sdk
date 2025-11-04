//
//  MPKitTestClassSideloaded.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 3/2/23.
//  Copyright © 2023 mParticle, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPKitProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPKitTestClassSideloaded : NSObject<MPKitProtocol>

@property (nonatomic, readonly) BOOL started;
@property (nonatomic, strong, nullable) MPKitAPI *kitApi;
@property (nonatomic, strong, nonnull) NSNumber *sideloadedKitCode;

@end

NS_ASSUME_NONNULL_END
