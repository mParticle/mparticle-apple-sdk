#import <Foundation/Foundation.h>
#import "MPKitProtocol.h"
#import "MPEnums.h"
#import "MPCommerceEvent+Dictionary.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A wrapper for sideloaded kit instances that includes filtering configuration.
 
 Sideloaded kits are kit instances that are registered locally rather than configured
 from the mParticle server. They receive all MPKitProtocol callback method calls and
 can be configured with filters to control which events they receive.
 */
@interface MPSideloadedKit : NSObject

/**
 The kit instance that conforms to MPKitProtocol.
 */
@property (nonatomic, strong, readwrite) id<MPKitProtocol> kitInstance;

/**
 Initializes a new sideloaded kit wrapper with the given kit instance.
 
 @param kitInstance An instance of a class conforming to MPKitProtocol
 @returns A new MPSideloadedKit instance
 */
- (instancetype)initWithKitInstance:(id<MPKitProtocol>)kitInstance;

/**
 Adds an event type filter. Events matching this type will be filtered.
 
 @param eventType The event type to filter
 */
- (void)addEventTypeFilterWithEventType:(MPEventType)eventType;

/**
 Adds an event name filter for a specific event type and name combination.
 
 @param eventType The event type
 @param eventName The event name to filter
 */
- (void)addEventNameFilterWithEventType:(MPEventType)eventType eventName:(NSString *)eventName;

/**
 Adds a screen name filter. Screen events matching this name will be filtered.
 
 @param screenName The screen name to filter
 */
- (void)addScreenNameFilterWithScreenName:(NSString *)screenName;

/**
 Adds an event attribute filter for a specific event type, name, and attribute key combination.
 
 @param eventType The event type
 @param eventName The event name
 @param customAttributeKey The attribute key to filter
 */
- (void)addEventAttributeFilterWithEventType:(MPEventType)eventType eventName:(NSString *)eventName customAttributeKey:(NSString *)customAttributeKey;

/**
 Adds a screen attribute filter for a specific screen name and attribute key combination.
 
 @param screenName The screen name
 @param customAttributeKey The attribute key to filter
 */
- (void)addScreenAttributeFilterWithScreenName:(NSString *)screenName customAttributeKey:(NSString *)customAttributeKey;

/**
 Adds a user identity filter. User identities matching this type will be filtered.
 
 @param userIdentity The user identity type to filter
 */
- (void)addUserIdentityFilterWithUserIdentity:(MPUserIdentity)userIdentity;

/**
 Adds a user attribute filter. User attributes matching this key will be filtered.
 
 @param userAttributeKey The user attribute key to filter
 */
- (void)addUserAttributeFilterWithUserAttributeKey:(NSString *)userAttributeKey;

/**
 Adds a commerce event attribute filter for a specific event type and attribute key combination.
 
 @param eventType The commerce event type
 @param eventAttributeKey The attribute key to filter
 */
- (void)addCommerceEventAttributeFilterWithEventType:(MPEventType)eventType eventAttributeKey:(NSString *)eventAttributeKey;

/**
 Adds a commerce event entity type filter.
 
 @param commerceEventKind The commerce event kind to filter
 */
- (void)addCommerceEventEntityTypeFilterWithCommerceEventKind:(MPCommerceEventKind)commerceEventKind;

/**
 Adds a commerce event app family attribute filter.
 
 @param attributeKey The app family attribute key to filter
 */
- (void)addCommerceEventAppFamilyAttributeFilterWithAttributeKey:(NSString *)attributeKey;

/**
 Sets event attribute conditional forwarding based on attribute name and value.
 
 This is a special filter case that can only have one at a time. If onlyForward is true,
 ONLY matching events are forwarded; if false, any matching events are blocked.
 
 Note: This is iOS/Android only, web has a different signature.
 
 @param attributeName The attribute name to match
 @param attributeValue The attribute value to match
 @param onlyForward If YES, only matching events are forwarded; if NO, matching events are blocked
 */
- (void)setEventAttributeConditionalForwardingWithAttributeName:(NSString *)attributeName attributeValue:(NSString *)attributeValue onlyForward:(BOOL)onlyForward;

/**
 Adds a message type filter using message type constants.
 
 @param messageTypeConstant A message type constant string (see MPIConstants.h starting on line 393)
 */
- (void)addMessageTypeFilterWithMessageTypeConstant:(NSString *)messageTypeConstant;

/**
 Returns the complete filter configuration dictionary for this sideloaded kit.
 
 @returns A dictionary containing all configured filters
 */
- (NSDictionary<NSString *, id> *)getKitFilters;

@end

NS_ASSUME_NONNULL_END
