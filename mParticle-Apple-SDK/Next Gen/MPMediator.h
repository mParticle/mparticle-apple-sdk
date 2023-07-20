//
//  MPMediator.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>
#import "MPEventLogging.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPMediator : NSObject

@property (readonly) MPEventLogging *eventLogging;

@end

NS_ASSUME_NONNULL_END
