#import "MPDataPlanFilter.h"
#import "MPEvent.h"
#import "MPBaseEvent.h"
#import "MPCommerceEvent.h"
#import "MPIConstants.h"
#import "MPCommerceEvent+Dictionary.h"

@interface MPDataPlanFilter ()
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSArray<NSString *> *> *pointInfo;
@property (nonatomic) BOOL blockEvents;
@property (nonatomic) BOOL blockEventAttributes;
@property (nonatomic) BOOL blockUserAttributes;
@property (nonatomic) BOOL blockUserIdentities;
@property (nonatomic) NSDictionary *emptyDictionary;
@end

@implementation MPDataPlanFilter

- (instancetype)initWithDataPlanOptions:(MPDataPlanOptions *)dataPlanOptions {
    self = [super init];
    if (self) {
        _pointInfo = @{}.mutableCopy;
        _blockEvents = dataPlanOptions.blockEvents;
        _blockEventAttributes = dataPlanOptions.blockEventAttributes;
        _blockUserAttributes = dataPlanOptions.blockUserAttributes;
        _blockUserIdentities = dataPlanOptions.blockUserIdentities;
        _emptyDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: [NSNumber numberWithBool:false], @"additionalProperties", nil];
        NSDictionary *document = dataPlanOptions.dataPlan[@"version_document"];
        NSArray *points = document[@"data_points"];
        for (NSDictionary *point in points) {
            NSDictionary *match = point[@"match"];
            NSString *key = [self keyForMatch:match];
            if (!key) { continue; }
            if ([match[@"type"] isEqual:@"user_attributes"]) {
                _pointInfo[key] = [self getPlannedUserAttributes:point];
            } else if ([match[@"type"] isEqual:@"user_identities"]) {
                _pointInfo[key] = [self getPlannedUserIdentities:point];
            } else {
                _pointInfo[key] = [self getPlannedCustomAttributes:point];
                if ([match[@"type"] isEqual:@"product_action"] ||
                       [match[@"type"] isEqual:@"product_impression"] ||
                       [match[@"type"] isEqual:@"promotion_action"]) {
                NSString *productAttributeKey = [NSString stringWithFormat:@"%@.product_action_product", key];
                    _pointInfo[productAttributeKey] = [self getPlannedProductActionProductCustomAttributes:point];
                NSString *productImpressionKey = [NSString stringWithFormat:@"%@.product_impression_product", key];
                    _pointInfo[productImpressionKey] = [self getPlannedProductImpressionProductCustomAttributes:point];
                }
            }
        }
    }
    return self;
}

- (MPCommerceEvent *)transformEventForCommerceEvent:(MPCommerceEvent *)commerceEvent {
    return (MPCommerceEvent *)[self mutateEvent:commerceEvent isScreenEvent:false];
}

- (MPEvent *)transformEventForEvent:(MPEvent *)event {
    return (MPEvent *)[self mutateEvent:event isScreenEvent:false];
}

- (MPBaseEvent *)transformEventForBaseEvent:(MPBaseEvent*)event {
    return (MPBaseEvent *)[self mutateEvent:event isScreenEvent:false];
}

- (MPEvent*)transformEventForScreenEvent:(MPEvent *)screenEvent {
    return (MPEvent *)[self mutateEvent:screenEvent isScreenEvent:true];
}

- (BOOL)isBlockedUserAttributeKey:(NSString *)userAttributeKey {
    if (!_blockUserAttributes) {
        return NO;
    }
    
    NSArray *info = self.pointInfo[@"user_attributes"];
    if (info == nil) {
        return NO;
    }
    if ([info containsObject:userAttributeKey]) {
        return NO;
    }
    return YES;
}

- (BOOL)isBlockedUserIdentityType:(MPIdentity)userIdentityType {
    if (!_blockUserIdentities) {
        return NO;
    }
    NSArray *info = self.pointInfo[@"user_identities"];
    if (info == nil) {
        return NO;
    }
    if ([info containsObject:@(userIdentityType)]) {
        return NO;
    }
    return YES;
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)getPointInfo {
    return [NSDictionary dictionaryWithDictionary:_pointInfo];
}


- (NSArray<NSString *>*)getPlannedCustomAttributes:(NSDictionary *)point {
    NSDictionary *data = [self getDataFromPoint:point];
    NSDictionary *customAttributes = [self getConstrainedProperties:data targetName:@"custom_attributes"];
    return [self getConstrainedPropertiesKeySet: customAttributes];
}

- (NSArray<NSString *>*)getPlannedUserAttributes:(NSDictionary *)point {
    NSDictionary *definition = [self getDefinitionFromPoint:point];
    return [self getConstrainedPropertiesKeySet:definition];
}

- (NSArray<NSString *>*)getPlannedUserIdentities:(NSDictionary *)point {
    NSDictionary *definition = [self getDefinitionFromPoint:point];
    return [[self getConstrainedPropertiesKeySet:definition] valueForKeyPath:@"self.integerValue"];
}

- (NSArray<NSString *>*)getPlannedProductImpressionProductCustomAttributes:(NSDictionary *)point {
    NSDictionary *data = [self getDataFromPoint:point];
    NSDictionary *productImpressionData = [self getConstrainedProperties:data targetName:@"product_impressions"];
    if (productImpressionData == _emptyDictionary) {
        return [[NSArray<NSString *> alloc] init];
    }
    NSDictionary *items = productImpressionData[@"items"];
    if (items) {
        NSDictionary *products = [self getConstrainedProperties:items targetName:@"products"];
        if (products == _emptyDictionary) {
            return [[NSArray alloc] init];
        }
        return [self getPlannedAttributesFromProducts:products];
    }
    return (NSArray<NSString *> *)[NSNull null];
}

- (NSArray<NSString *>*)getPlannedProductActionProductCustomAttributes:(NSDictionary *)point {
    NSDictionary *data = [self getDataFromPoint:point];
    NSDictionary * productAction = [self getConstrainedProperties: data targetName:@"product_action"];
    NSDictionary * products = [self getConstrainedProperties:productAction targetName:@"products"];
    if (products == _emptyDictionary) {
        return [[NSArray alloc] init];
    }
    return [self getPlannedAttributesFromProducts:products];
}

- (NSArray<NSString *> *)getPlannedAttributesFromProducts:(NSDictionary *) products {
    NSDictionary *productItems = products[@"items"];
    if (productItems) {
        NSDictionary *customAttributes = [self getConstrainedProperties:productItems targetName:@"custom_attributes"];
        return [self getConstrainedPropertiesKeySet:customAttributes];
    }
    return (NSArray *)[NSNull null];
}

- (NSDictionary *)getDefinitionFromPoint:(NSDictionary *)point {
    NSDictionary *validator = point[@"validator"];
    return validator[@"definition"];
}

- (NSDictionary *)getDataFromPoint:(NSDictionary *)point {
    NSDictionary *definition = [self getDefinitionFromPoint:point];
    return [self getConstrainedProperties:definition targetName:@"data"];
}

- (NSDictionary *)getConstrainedProperties:(NSDictionary *)point targetName:(NSString *)targetName {
    if (point == _emptyDictionary) {
        return point;
    }
    NSDictionary *properties = point[@"properties"];
    NSNumber *additionalProperties = point[@"additionalProperties"];
    NSDictionary *targetDictionary = properties[targetName];
    if (properties) {
        return targetDictionary;
    } else {
        if (additionalProperties && [additionalProperties boolValue] == false) {
            return _emptyDictionary;
        } else {
            return nil;
        }
    }
}

- (NSArray<NSString *> *)getConstrainedPropertiesKeySet:(NSDictionary *)point {
    if (point == _emptyDictionary) {
        return [[NSArray<NSString *> alloc] init];
    }
    NSNumber *additionalProperties = point[@"additionalProperties"];
    NSDictionary *dataProperties = point[@"properties"];
    if (additionalProperties && ![additionalProperties boolValue]) {
        if (dataProperties) {
            return (NSArray<NSString *>*)dataProperties.allKeys;
        } else {
            return [[NSArray<NSString *> alloc] init];
        }
    } else {
        return (NSArray<NSString *> *)[NSNull null];
    }
}

- (NSString *)matchKeyForScreenName:(NSString *)screenName {
    return [self matchKeyForMatchType:@"screen_view" key:screenName];
}

- (NSString *)matchKeyForEventType:(NSString *)eventType eventName:(NSString *)eventName {
    NSString *mutatedType = [[eventType stringByReplacingOccurrencesOfString:@"_" withString:@""] lowercaseString];
    return [self matchKeyForMatchType:@"custom_event" type:mutatedType name:eventName];
}

- (NSString *)matchKeyForMatchType:(NSString *)matchType type:(NSString *)type name:(NSString *)name {
    return [NSString stringWithFormat:@"%@.%@.%@", matchType, name, type];
}

- (NSString *)matchKeyForMatchType:(NSString *)matchType key:(NSString *)key {
    NSString *mutatedKey = [key stringByReplacingOccurrencesOfString:@"_" withString:@""];
    return [NSString stringWithFormat:@"%@.%@", matchType, mutatedKey];
}

- (NSString *)keyForMatch:(NSDictionary *)match {
    NSDictionary *criteria = match[@"criteria"];
    NSString *matchType = match[@"type"];
    if ([matchType isEqual:@"custom_event"]) {
        NSString *eventName = criteria[@"event_name"];
        NSString *eventType = criteria[@"custom_event_type"];
        
        NSString *key = nil;
        if (eventName != nil && eventType != nil) {
            key = [self matchKeyForEventType:eventType eventName:eventName];
        }
        return key;
    } else if ([matchType isEqual:@"screen_view"]) {
        NSString *screenName = criteria[@"screen_name"];
        return [self matchKeyForScreenName:screenName];
    } else if ([matchType isEqual:@"product_action"]) {
        NSString *action = criteria[@"action"];
        return [self matchKeyForMatchType:matchType key:action];
    } else if ([matchType isEqual:@"promotion_action"]) {//
        NSString *action = criteria[@"action"];
        return [self matchKeyForMatchType:matchType key:action];
    } else if ([matchType isEqual:@"product_impression"]) {//
        return matchType;
    } else if ([matchType isEqual:@"user_attributes"]) {
        return matchType;
    } else if ([matchType isEqual:@"user_identities"]) {
        return matchType;
    }
    return nil;
}

- (NSString *)matchKeyFromBaseEvent:(MPBaseEvent *)event isScreenEvent:(BOOL)isScreenEvent {
    if ([event isKindOfClass:[MPEvent class]]) {
        MPEvent *customEvent = (MPEvent *)event;
        if (isScreenEvent) {
            return [self matchKeyForScreenName:customEvent.name];
        } else {
            return [self matchKeyForEventType:NSStringFromEventType(event.type) eventName:customEvent.name];
        }
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        MPCommerceEvent *commerceEvent = (MPCommerceEvent *)event;
        if (commerceEvent.kind == MPCommerceEventKindProduct) {
            return [self matchKeyForMatchType:@"product_action" key:[[NSStringFromEventType(event.type) lowercaseString]stringByReplacingOccurrencesOfString:@"product" withString:@""]];
        } else if (commerceEvent.kind == MPCommerceEventKindPromotion) {
            return [self matchKeyForMatchType:@"promotion_action" key:[[NSStringFromEventType(event.type) lowercaseString]stringByReplacingOccurrencesOfString:@"promotion" withString:@""]];
        } else if (commerceEvent.kind == MPCommerceEventKindImpression) {
            return @"product_impression";
        }
    }
    return nil;
}

- (MPBaseEvent *)mutateEvent:(MPBaseEvent *)event isScreenEvent:(BOOL)isScreenEvent {
    if (!_blockEvents && !_blockEventAttributes) {
        return event;
    }
    NSString *infoKey = [self matchKeyFromBaseEvent:event isScreenEvent:isScreenEvent];

    NSArray *info = self.pointInfo[infoKey];
    if (_blockEvents) {
        if (info == nil) {
            return nil;
        }
        if ((NSNull *)info == [NSNull null]) {
            return event;
        }
    }
    if (_blockEventAttributes) {
        NSMutableDictionary *updatedInfo = [NSMutableDictionary dictionary];
        for (NSString *key in info) {
            id value = event.customAttributes[key];
            if (value) {
                updatedInfo[key] = value;
            }
        }
        event.customAttributes = updatedInfo;
        if ([event isKindOfClass:[MPCommerceEvent class]]) {
            MPCommerceEvent *commerceEvent = (MPCommerceEvent *)event;
            if (commerceEvent.products && commerceEvent.products.count > 0) {
                NSString *productKey = [NSString stringWithFormat:@"%@.product_action_product", infoKey];
                commerceEvent.products = [self filterProducts:commerceEvent.products plannedAttributes:_pointInfo[productKey]];
            }
            if (commerceEvent.impressions && commerceEvent.impressions.count > 0) {
                NSString *productKey = [NSString stringWithFormat:@"%@.product_impression_product", infoKey];
                NSArray *keys = commerceEvent.impressions.allKeys;
                for (NSString *key in keys) {
                    NSArray<MPProduct *> *products = [commerceEvent.impressions[key] allObjects];
                    [commerceEvent.impressions[key] removeAllObjects];
                    products = [self filterProducts:products plannedAttributes:_pointInfo[productKey]];
                    if (products) {
                        NSMutableDictionary *impressions = commerceEvent.impressions.mutableCopy;
                        impressions[key] = [impressions[key] setByAddingObjectsFromArray:products];
                        [commerceEvent setImpressions:impressions];
                    }
                }
            }
        }
    }
    return event;
}

- (NSArray<MPProduct *> *)filterProducts:(NSArray<MPProduct *> *)products plannedAttributes:(NSArray<NSString *> *)plannedAttributes {
    if (!_blockEventAttributes || (NSNull *)plannedAttributes == [NSNull null]) {
        return products;
    }
    for (MPProduct *product in products) {
        NSDictionary *actualAttributes = product.userDefinedAttributes;
        NSMutableDictionary *resultAttributes = @{}.mutableCopy;
        for (NSString *attr in plannedAttributes) {
            id value = actualAttributes[attr];
           if (value) {
                resultAttributes[attr] = value;
           }
        }
        product.userDefinedAttributes = resultAttributes;
    }
    return products;
}

@end
