#import <Foundation/Foundation.h>
@import mParticle_Apple_SDK_Swift;

@class MPCommerceEvent;
@class MPBaseEvent;
@class MPConsentState;

@interface MPKitFilter : NSObject

@property (nonatomic, strong, readonly, nullable) NSArray<MPKitProjectionSnapshot *> *appliedProjections;
@property (nonatomic, strong, readonly, nullable) NSDictionary *filteredAttributes;
@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *originalCommerceEvent;
@property (nonatomic, strong, readonly, nullable) MPBaseEvent *originalEvent;
@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *originalCommerceEventCopy;
@property (nonatomic, strong, readonly, nullable) MPBaseEvent *originalEventCopy;
@property (nonatomic, strong, readonly, nullable) MPCommerceEvent *forwardCommerceEvent;
@property (nonatomic, strong, readonly, nullable) MPBaseEvent *forwardEvent;
@property (nonatomic, strong, readonly, nullable) MPConsentState *forwardConsentState;
@property (nonatomic, readonly) BOOL shouldFilter;

- (nonnull instancetype)initWithFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithFilter:(BOOL)shouldFilter filteredAttributes:(nullable NSDictionary *)filteredAttributes;
- (nonnull instancetype)initWithEvent:(nonnull MPBaseEvent *)event shouldFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithEvent:(nonnull MPBaseEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(nullable NSArray<MPKitProjectionSnapshot *> *)appliedProjections eventCopy:(nullable MPBaseEvent *)eventCopy commerceEventCopy:(nullable MPCommerceEvent *)commerceEventCopy;
- (nonnull instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter;
- (nonnull instancetype)initWithCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter appliedProjections:(nullable NSArray<MPKitProjectionSnapshot *> *)appliedProjections;
- (nonnull instancetype)initWithConsentState:(nonnull MPConsentState *)state shouldFilter:(BOOL)shouldFilter;

@end
