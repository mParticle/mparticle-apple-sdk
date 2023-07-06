//
//  MParticleShim.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import <Foundation/Foundation.h>

#import "MPEnums.h"

@class MParticle;
@class MPBaseEvent;
@class MPEvent;
@class MPCommerceEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MParticleShim : NSObject

@property (nonatomic, weak) MParticle *mpInstance;

- (instancetype)initWithInstance:(MParticle *)mpInstance;

- (void)logEvent:(MPBaseEvent *)event;
- (void)logEvent:(NSString *)eventName eventType:(MPEventType)eventType eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;
- (void)logScreenEvent:(MPEvent *)event;
- (void)logScreen:(NSString *)screenName eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo shouldUploadEvent:(BOOL)shouldUploadEvent;
- (void)logCommerceEvent:(MPCommerceEvent *)commerceEvent;
- (void)logError:(NSString *)message eventInfo:(nullable NSDictionary<NSString *, id> *)eventInfo;
- (void)logException:(NSException *)exception topmostContext:(id)topmostContext;
- (void)leaveBreadcrumb:(NSString *)breadcrumbName eventInfo:(NSDictionary<NSString *, id> *)eventInfo;
- (void)logLTVIncrease:(double)increaseAmount eventName:(NSString *)eventName eventInfo:(NSDictionary<NSString *, id> *)eventInfo;

@end

NS_ASSUME_NONNULL_END
