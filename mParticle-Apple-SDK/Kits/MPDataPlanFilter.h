#import <Foundation/Foundation.h>
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "mParticle.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPDataPlanFilter: NSObject

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
