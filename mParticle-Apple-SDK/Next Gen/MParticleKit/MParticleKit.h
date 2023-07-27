//
//  MParticleKit.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>
#import "MPKitProtocol.h"

@class MPNetworkCommunication;
@class MParticle;

NS_ASSUME_NONNULL_BEGIN

@interface MParticleKit : NSObject <MPKitProtocol>

@property (nonatomic, weak) MParticle *mpInstance;

@property (nonatomic, strong, nullable) MPNetworkCommunication *networkCommunication;

- (void)uploadBatchesWithCompletionHandler:(void(^)(BOOL success))completionHandler;

- (void)skipNextUpload;

@end

NS_ASSUME_NONNULL_END
