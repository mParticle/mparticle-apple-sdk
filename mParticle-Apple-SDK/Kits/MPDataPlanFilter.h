#import <Foundation/Foundation.h>
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "mParticle.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MPDataPlanFilterProtocol <NSObject>

- (BOOL)isBlockedUserIdentityType:(MPIdentity)userIdentityType;
- (BOOL)isBlockedUserAttributeKey:(NSString *)userAttributeKey;
- (MPEvent * _Nullable)transformEventForEvent:(MPEvent *)event;
- (MPEvent * _Nullable)transformEventForScreenEvent:(MPEvent *)screenEvent;

@end

@interface MPDataPlanFilter: NSObject<MPDataPlanFilterProtocol>

- (NSMutableDictionary<NSString *, NSArray<NSString *> *> *)getPointInfo;

- (instancetype)initWithDataPlanOptions:(MPDataPlanOptions *)dataPlanOptions;

- (MPBaseEvent *)transformEventForBaseEvent:(MPBaseEvent *)baseEvent;
- (MPEvent *)transformEventForEvent:(MPEvent *)mpEvent;
- (MPCommerceEvent *)transformEventForCommerceEvent:(MPCommerceEvent *)commerceEvent;
- (MPEvent *)transformEventForScreenEvent:(MPEvent *)screenEvent;
- (BOOL)isBlockedUserAttributeKey:(NSString *)userAttributeKey;
- (BOOL)isBlockedUserIdentityType:(MPIdentity)userIdentityType;

@end

NS_ASSUME_NONNULL_END
