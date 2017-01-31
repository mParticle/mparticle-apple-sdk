//
//  MPKitDataTransformation.mm
//
//  Copyright 2017 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MPKitDataTransformation.h"
#include "EventTypeName.h"
#include <map>
#include "MessageTypeName.h"
#import "MPAttributeProjection.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEvent.h"
#import "MPEventProjection.h"
#include "MPHasher.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPKitConfiguration.h"
#import "MPKitFilter.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPStateMachine.h"
#import "MPTransactionAttributes.h"
#import "MPTransactionAttributes+Dictionary.h"
#import "NSArray+MPCaseInsensitive.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "NSUserDefaults+mParticle.h"
#import <UIKit/UIKit.h>
#include <vector>

@interface MPKitDataTransformation() {
    dispatch_semaphore_t projectionSemaphore;
}

@end

@implementation MPKitDataTransformation

- (instancetype)init {
    self = [super init];
    if (self) {
        projectionSemaphore = dispatch_semaphore_create(1);
    }
    
    return self;
}

#pragma mark Private methods
- (NSDictionary *)methodMessageTypeMapping {
    NSString *messageTypeEvent = [NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Event).c_str() encoding:NSUTF8StringEncoding];
    
    NSDictionary *methodMessageTypeDictionary = @{@"logEvent:":messageTypeEvent,
                                                  @"logScreen:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::ScreenView).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logScreenEvent:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::ScreenView).c_str() encoding:NSUTF8StringEncoding],
                                                  @"beginSession":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::SessionStart).c_str() encoding:NSUTF8StringEncoding],
                                                  @"endSession":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::SessionEnd).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logTransaction:":messageTypeEvent,
                                                  @"logLTVIncrease:eventName:eventInfo:":messageTypeEvent,
                                                  @"leaveBreadcrumb:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logError:exception:topmostContext:eventInfo:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::CrashReport).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logNetworkPerformanceMeasurement:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::NetworkPerformance).c_str() encoding:NSUTF8StringEncoding],
                                                  @"profileChange:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Profile).c_str() encoding:NSUTF8StringEncoding],
                                                  @"setOptOut:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::OptOut).c_str() encoding:NSUTF8StringEncoding],
                                                  @"logCommerceEvent:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::CommerceEvent).c_str() encoding:NSUTF8StringEncoding],
                                                  @"leaveBreadcrumb:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding],
                                                  @"checkForDeferredDeepLinkWithCompletionHandler:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::AppStateTransition).c_str() encoding:NSUTF8StringEncoding]
                                                  };
    
    return methodMessageTypeDictionary;
}

- (void)project:(id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(MPKitConfiguration *)kitConfiguration event:(MPEventAbstract *const)event messageType:(MPMessageType)messageType completionHandler:(void (^)(vector<MPCommerceEvent *> projectedCommerceEvents, vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections))completionHandler {
    __weak MPKitDataTransformation *weakSelf = self;
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > messageType) ||
        ![kitConfiguration.configuredMessageTypeProjections[messageType] boolValue])
    {
        vector<MPCommerceEvent *> projectedCommerceEvents;
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        
        if (event.kind == MPEventKindAppEvent) {
            projectedEvents.push_back((MPEvent *)event);
        } else if (event.kind == MPEventKindCommerceEvent) {
            projectedCommerceEvents.push_back((MPCommerceEvent *)event);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
        });
        
        return;
    }

    // Filter projections only to those of 'messageType'
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageType == %ld", (long)messageType];
    NSArray *projections = [kitConfiguration.projections filteredArrayUsingPredicate:predicate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong MPKitDataTransformation *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        dispatch_semaphore_wait(strongSelf->projectionSemaphore, DISPATCH_TIME_FOREVER);

        vector<MPCommerceEvent *> projectedCommerceEvents;
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        
        if (event.kind == MPEventKindCommerceEvent) {
            MPCommerceEvent *commerceEvent = (MPCommerceEvent *)event;
            // Priming projections
            __block vector<MPEventProjection *> applicableEventProjections;
            MPCommerceEventKind kindOfCommerceEvent = [commerceEvent commerceEventKind];
            
            NSArray *const products = [&commerceEvent] {
                return [commerceEvent commerceEventKind] == MPCommerceEventKindProduct ? commerceEvent.products : (NSArray *)nil;
            }();
            
            NSArray *const promotions = [&commerceEvent] {
                return [commerceEvent commerceEventKind] == MPCommerceEventKindPromotion ? commerceEvent.promotionContainer.promotions : (NSArray *)nil;
            }();
            
            BOOL (^isApplicableEventProjection)(MPEventProjection *, NSDictionary *) = ^ BOOL (MPEventProjection *eventProjection, NSDictionary *sourceDictionary) {
                
                __block BOOL foundNonMatch = NO;
                [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                    __block BOOL isApplicable = NO;
                    [sourceDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                        NSString *keyHash = [NSString stringWithCString:mParticle::Hasher::hashString(to_string(event.type) + string([[key lowercaseString] UTF8String])).c_str()
                                                               encoding:NSUTF8StringEncoding];
                        
                        isApplicable = [projectionMatch.attributeKey isEqualToString:keyHash] && [projectionMatch.attributeValues caseInsensitiveContainsObject:value];
                        *stop = isApplicable;
                    }];
                    foundNonMatch = !isApplicable;
                    *stop = foundNonMatch;
                }];
                
                return !foundNonMatch;
            };
            
            if (projections.count > 0) {
                // Identifying which projections are applicable
                for (MPEventProjection *eventProjection in projections) {
                    if (eventProjection.eventType == event.type) {
                        if (!MPIsNull(eventProjection.projectionMatches)) {
                            switch (eventProjection.propertyKind) {
                                case MPProjectionPropertyKindEventField:
                                    if (isApplicableEventProjection(eventProjection, [[commerceEvent beautifiedAttributes] transformValuesToString])) {
                                        applicableEventProjections.push_back(eventProjection);
                                    }
                                    break;
                                    
                                case MPProjectionPropertyKindEventAttribute:
                                    if (isApplicableEventProjection(eventProjection, [[commerceEvent userDefinedAttributes] transformValuesToString])) {
                                        applicableEventProjections.push_back(eventProjection);
                                    }
                                    break;
                                    
                                case MPProjectionPropertyKindProductField:
                                    if (kindOfCommerceEvent == MPCommerceEventKindProduct) {
                                        [products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                                            *stop = isApplicableEventProjection(eventProjection, [[product beautifiedAttributes] transformValuesToString]);
                                            if (*stop) {
                                                applicableEventProjections.push_back(eventProjection);
                                            }
                                        }];
                                    } else if (kindOfCommerceEvent == MPCommerceEventKindImpression) {
                                        NSDictionary *impressions = commerceEvent.impressions;
                                        __block BOOL stopIteration = NO;
                                        
                                        [impressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSSet *productImpressions, BOOL *stop) {
                                            [productImpressions enumerateObjectsUsingBlock:^(MPProduct *productImpression, BOOL *stop) {
                                                stopIteration = isApplicableEventProjection(eventProjection, [[productImpression beautifiedAttributes] transformValuesToString]);
                                                if (stopIteration) {
                                                    applicableEventProjections.push_back(eventProjection);
                                                    *stop = YES;
                                                }
                                            }];
                                            
                                            if (stopIteration) {
                                                *stop = YES;
                                            }
                                        }];
                                    }
                                    break;
                                    
                                case MPProjectionPropertyKindProductAttribute:
                                    if (kindOfCommerceEvent == MPCommerceEventKindProduct) {
                                        [products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                                            *stop = isApplicableEventProjection(eventProjection, [[product userDefinedAttributes] transformValuesToString]);
                                            if (*stop) {
                                                applicableEventProjections.push_back(eventProjection);
                                            }
                                        }];
                                    } else if (kindOfCommerceEvent == MPCommerceEventKindImpression) {
                                        NSDictionary *impressions = commerceEvent.impressions;
                                        __block BOOL stopIteration = NO;
                                        
                                        [impressions enumerateKeysAndObjectsUsingBlock:^(NSString *listName, NSSet *productImpressions, BOOL *stop) {
                                            [productImpressions enumerateObjectsUsingBlock:^(MPProduct *productImpression, BOOL *stop) {
                                                stopIteration = isApplicableEventProjection(eventProjection, [[productImpression userDefinedAttributes] transformValuesToString]);
                                                if (stopIteration) {
                                                    applicableEventProjections.push_back(eventProjection);
                                                    *stop = YES;
                                                }
                                            }];
                                            
                                            if (stopIteration) {
                                                *stop = YES;
                                            }
                                        }];
                                    }
                                    break;
                                    
                                case MPProjectionPropertyKindPromotionField: {
                                    if (kindOfCommerceEvent == MPCommerceEventKindPromotion) {
                                        [promotions enumerateObjectsUsingBlock:^(MPPromotion *promotion, NSUInteger idx, BOOL *stop) {
                                            *stop = isApplicableEventProjection(eventProjection, [[promotion beautifiedAttributes] transformValuesToString]);
                                            if (*stop) {
                                                applicableEventProjections.push_back(eventProjection);
                                            }
                                        }];
                                    }
                                }
                                    break;
                                    
                                case MPProjectionPropertyKindPromotionAttribute:
                                    break;
                            }
                        } else {
                            applicableEventProjections.push_back(eventProjection);
                        }
                    }
                } // for
            } // If (projection.count)
            
            // Block to project a dictionary according to an attribute projection
            NSDictionary * (^projectDictionaryWithAttributeProjection)(NSDictionary *, MPAttributeProjection *) = ^(NSDictionary *sourceDictionary, MPAttributeProjection *attributeProjection) {
                NSMutableDictionary *projectedDictionary = [[NSMutableDictionary alloc] init];
                id value;
                
                switch (attributeProjection.matchType) {
                    case MPProjectionMatchTypeHash: {
                        map<int, NSString *> hashKeyMap;
                        NSString *key;
                        NSEnumerator *keyEnumerator = [sourceDictionary keyEnumerator];
                        while ((key = [keyEnumerator nextObject])) {
                            string attributeToHash = to_string(event.type) + string([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                            
                            int hashValue = mParticle::Hasher::hashFromString(attributeToHash);
                            hashKeyMap[hashValue] = key;
                        }
                        
                        key = hashKeyMap[[attributeProjection.name intValue]];
                        
                        if (!MPIsNull(key)) {
                            value = [strongSelf transformValue:sourceDictionary[key] dataType:attributeProjection.dataType];
                            
                            if (value) {
                                projectedDictionary[attributeProjection.projectedName] = value;
                            }
                        } else if (attributeProjection.required) {
                            return (NSDictionary *)[NSNull null];
                        }
                    }
                        break;
                        
                    case MPProjectionMatchTypeField:
                    case MPProjectionMatchTypeString:
                        if ([sourceDictionary valueForCaseInsensitiveKey:attributeProjection.name]) {
                            value = [strongSelf transformValue:[sourceDictionary valueForCaseInsensitiveKey:attributeProjection.name] dataType:attributeProjection.dataType];
                            
                            if (value) {
                                projectedDictionary[attributeProjection.projectedName] = value;
                            }
                        } else if (attributeProjection.required) {
                            return (NSDictionary *)[NSNull null];
                        }
                        break;
                        
                    case MPProjectionMatchTypeStatic:
                        value = [strongSelf transformValue:attributeProjection.name dataType:attributeProjection.dataType];
                        
                        if (value) {
                            projectedDictionary[attributeProjection.projectedName] = value;
                        }
                        break;
                        
                    case MPProjectionMatchTypeNotSpecified:
                        break;
                }
                
                if (projectedDictionary.count == 0) {
                    projectedDictionary = nil;
                }
                
                return (NSDictionary *)projectedDictionary;
            };
            
            // Block to project a commerce event according to attribute projections
            NSDictionary * (^projectCommerceEventWithAttributes)(MPCommerceEvent *, NSArray *) = ^(MPCommerceEvent *commerceEvent, NSArray<MPAttributeProjection *> *attributeProjections) {
                NSMutableDictionary *projectedCommerceEventDictionary = [[NSMutableDictionary alloc] init];
                NSDictionary *sourceDictionary;
                NSDictionary *projectedDictionary;
                NSPredicate *predicate;
                NSArray<MPAttributeProjection *> *filteredAttributeProjections;
                
                vector<MPProjectionPropertyKind> propertyKinds = {MPProjectionPropertyKindEventField, MPProjectionPropertyKindEventAttribute};
                
                for (auto propertyKind : propertyKinds) {
                    predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d", (int)propertyKind];
                    filteredAttributeProjections = [attributeProjections filteredArrayUsingPredicate:predicate];
                    
                    if (filteredAttributeProjections.count > 0) {
                        if (propertyKind == MPProjectionPropertyKindEventField) {
                            sourceDictionary = [[commerceEvent beautifiedAttributes] transformValuesToString];
                        } else if (propertyKind == MPProjectionPropertyKindEventAttribute) {
                            sourceDictionary = [[commerceEvent userDefinedAttributes] transformValuesToString];
                        } else {
                            continue;
                        }
                    }
                    
                    for (MPAttributeProjection *attributeProjection in attributeProjections) {
                        projectedDictionary = projectDictionaryWithAttributeProjection(sourceDictionary, attributeProjection);
                        
                        if (projectedDictionary) {
                            if ((NSNull *)projectedDictionary != [NSNull null]) {
                                [projectedCommerceEventDictionary addEntriesFromDictionary:projectedDictionary];
                            } else {
                                return (NSDictionary *)[NSNull null];
                            }
                        }
                    }
                }
                
                if (projectedCommerceEventDictionary.count == 0) {
                    projectedCommerceEventDictionary = nil;
                }
                
                return (NSDictionary *)projectedCommerceEventDictionary;
            };
            
            // Block to project a product according to attribute projections
            NSDictionary * (^projectProductWithAttributes)(MPProduct *, NSArray *) = ^(MPProduct *product, NSArray<MPAttributeProjection *> *attributeProjections) {
                NSMutableDictionary *projectedProductDictionary = [[NSMutableDictionary alloc] init];
                NSDictionary *sourceDictionary;
                NSDictionary *projectedDictionary;
                NSPredicate *predicate;
                NSArray<MPAttributeProjection *> *filteredAttributeProjections;
                
                vector<MPProjectionPropertyKind> propertyKinds = {MPProjectionPropertyKindProductField, MPProjectionPropertyKindProductAttribute};
                
                for (auto propertyKind : propertyKinds) {
                    predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d", (int)propertyKind];
                    filteredAttributeProjections = [attributeProjections filteredArrayUsingPredicate:predicate];
                    
                    if (filteredAttributeProjections.count > 0) {
                        if (propertyKind == MPProjectionPropertyKindProductField) {
                            sourceDictionary = [[product beautifiedAttributes] transformValuesToString];
                        } else if (propertyKind == MPProjectionPropertyKindProductAttribute) {
                            sourceDictionary = [[product userDefinedAttributes] transformValuesToString];
                        } else {
                            continue;
                        }
                        
                        for (MPAttributeProjection *attributeProjection in filteredAttributeProjections) {
                            projectedDictionary = projectDictionaryWithAttributeProjection(sourceDictionary, attributeProjection);
                            
                            if (projectedDictionary) {
                                if ((NSNull *)projectedDictionary != [NSNull null]) {
                                    [projectedProductDictionary addEntriesFromDictionary:projectedDictionary];
                                } else {
                                    return (NSDictionary *)[NSNull null];
                                }
                            }
                        }
                    }
                }
                
                if (projectedProductDictionary.count == 0) {
                    return (NSDictionary *)nil;
                }
                
                return (NSDictionary *)projectedProductDictionary;
            };
            
            // Block to apply maximum custom attributes to the projected dictionary
            void (^applyMaxCustomAttributes)(MPCommerceEvent *, MPEventProjection *, NSMutableDictionary *) = ^(MPCommerceEvent *commerceEvent, MPEventProjection *eventProjection, NSMutableDictionary *projectedDictionary) {
                NSUInteger maxCustomParams = eventProjection.maxCustomParameters;
                NSDictionary *userDictionary = [[commerceEvent userDefinedAttributes] transformValuesToString];
                
                if (eventProjection.appendAsIs && maxCustomParams > 0) {
                    if (userDictionary.count > maxCustomParams) {
                        NSMutableArray *keys = [[userDictionary allKeys] mutableCopy];
                        
                        [keys sortUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
                            return [key1 compare:key2];
                        }];
                        
                        NSRange deletionRange = NSMakeRange(maxCustomParams - 1, maxCustomParams - userDictionary.count);
                        [keys removeObjectsInRange:deletionRange];
                        
                        for (NSString *key in keys) {
                            projectedDictionary[key] = userDictionary[key];
                        }
                    } else {
                        [projectedDictionary addEntriesFromDictionary:userDictionary];
                    }
                }
            };
            
            // Applying projections
            if (!applicableEventProjections.empty()) {
                for (auto &eventProjection : applicableEventProjections) {
                    NSMutableDictionary *projectedCommerceEventDictionary = [[NSMutableDictionary alloc] init];
                    NSDictionary *projectedDictionary;
                    vector<NSMutableDictionary *> projectedDictionaries;
                    BOOL requirementsMet = YES;
                    
                    // Projecting commerce event fields and attributes
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d || propertyKind == %d", (int)MPProjectionPropertyKindEventField, (int)MPProjectionPropertyKindEventAttribute];
                    NSArray<MPAttributeProjection *> *attributeProjections = [eventProjection.attributeProjections filteredArrayUsingPredicate:predicate];
                    
                    if (attributeProjections.count > 0) {
                        projectedDictionary = projectCommerceEventWithAttributes(commerceEvent, attributeProjections);
                        
                        if (projectedDictionary) {
                            if ((NSNull *)projectedDictionary != [NSNull null]) {
                                [projectedCommerceEventDictionary addEntriesFromDictionary:projectedDictionary];
                            } else {
                                requirementsMet = NO;
                            }
                        }
                    }
                    
                    // Projecting products/promotions attributes
                    switch (kindOfCommerceEvent) {
                        case MPCommerceEventKindProduct: {
                            vector<NSUInteger> productIndexes;
                            NSUInteger numberOfProducts = products.count;
                            
                            if (numberOfProducts > 0) {
                                if (eventProjection.behaviorSelector == MPProjectionBehaviorSelectorForEach) {
                                    productIndexes.reserve(numberOfProducts);
                                    
                                    for (NSUInteger idx = 0; idx < numberOfProducts; ++idx) {
                                        productIndexes.push_back(idx);
                                    }
                                } else {
                                    productIndexes.push_back(numberOfProducts - 1);
                                }
                                
                                predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d || propertyKind == %d", (int)MPProjectionPropertyKindProductField, (int)MPProjectionPropertyKindProductAttribute];
                                attributeProjections = [eventProjection.attributeProjections filteredArrayUsingPredicate:predicate];
                                
                                for (auto idx : productIndexes) {
                                    MPProduct *product = products[idx];
                                    projectedDictionary = projectProductWithAttributes(product, attributeProjections);
                                    
                                    if (projectedDictionary) {
                                        if ((NSNull *)projectedDictionary != [NSNull null]) {
                                            NSMutableDictionary *projectedProductDictionary = [[NSMutableDictionary alloc] initWithDictionary:projectedDictionary];
                                            
                                            if (projectedCommerceEventDictionary.count > 0) {
                                                [projectedProductDictionary addEntriesFromDictionary:projectedCommerceEventDictionary];
                                            }
                                            
                                            applyMaxCustomAttributes(commerceEvent, eventProjection, projectedProductDictionary);
                                            
                                            projectedDictionaries.push_back(projectedProductDictionary);
                                        } else {
                                            requirementsMet = NO;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                            break;
                            
                        case MPCommerceEventKindPromotion: {
                            vector<NSUInteger> promotionIndexes;
                            NSUInteger numberOfPromotions = promotions.count;
                            
                            if (numberOfPromotions > 0) {
                                if (eventProjection.behaviorSelector == MPProjectionBehaviorSelectorForEach) {
                                    promotionIndexes.reserve(numberOfPromotions);
                                    
                                    for (NSUInteger index = 0; index < numberOfPromotions; ++index) {
                                        promotionIndexes.push_back(index);
                                    }
                                } else {
                                    promotionIndexes.push_back(numberOfPromotions - 1);
                                }
                                
                                predicate = [NSPredicate predicateWithFormat:@"propertyKind == %d", (int)MPProjectionPropertyKindPromotionField];
                                attributeProjections = [eventProjection.attributeProjections filteredArrayUsingPredicate:predicate];
                                
                                for (auto idx : promotionIndexes) {
                                    MPPromotion *promotion = promotions[idx];
                                    NSDictionary *sourceDictionary = [[promotion beautifiedAttributes] transformValuesToString];
                                    
                                    for (MPAttributeProjection *attributeProjection in attributeProjections) {
                                        NSDictionary *projectedDictionary = projectDictionaryWithAttributeProjection(sourceDictionary, attributeProjection);
                                        
                                        if (projectedDictionary) {
                                            if ((NSNull *)projectedDictionary != [NSNull null]) {
                                                NSMutableDictionary *projectedPromotionDictionary = [[NSMutableDictionary alloc] initWithDictionary:projectedDictionary];
                                                
                                                if (projectedCommerceEventDictionary.count > 0) {
                                                    [projectedPromotionDictionary addEntriesFromDictionary:projectedCommerceEventDictionary];
                                                }
                                                
                                                applyMaxCustomAttributes(commerceEvent, eventProjection, projectedPromotionDictionary);
                                                
                                                projectedDictionaries.push_back(projectedPromotionDictionary);
                                            } else {
                                                requirementsMet = NO;
                                                break;
                                            }
                                        }
                                    }
                                    
                                    if (!requirementsMet) {
                                        break;
                                    }
                                }
                            }
                        }
                            break;
                            
                        default:
                            break;
                    }
                    
                    // The collection of projected dictionaries become events or commerce events
                    if (requirementsMet) {
                        if (!projectedDictionaries.empty()) {
                            for (auto &projectedDictionary : projectedDictionaries) {
                                if (eventProjection.outboundMessageType == MPMessageTypeCommerceEvent) {
                                    MPCommerceEvent *projectedCommerceEvent = [commerceEvent copy];
                                    [projectedCommerceEvent setUserDefinedAttributes:projectedDictionary];
                                    projectedCommerceEvents.push_back(projectedCommerceEvent);
                                } else {
                                    MPEvent *projectedEvent = [[MPEvent alloc] initWithName:(eventProjection.projectedName ? : @" ") type:MPEventTypeTransaction];
                                    projectedEvent.info = projectedDictionary;
                                    projectedEvents.push_back(projectedEvent);
                                }
                                
                                appliedProjections.push_back(eventProjection);
                            }
                        } else {
                            if (eventProjection.outboundMessageType == MPMessageTypeCommerceEvent) {
                                MPCommerceEvent *projectedCommerceEvent = [commerceEvent copy];
                                projectedCommerceEvents.push_back(projectedCommerceEvent);
                            } else {
                                MPEvent *projectedEvent = [[MPEvent alloc] initWithName:(eventProjection.projectedName ? : @" ") type:MPEventTypeTransaction];
                                projectedEvents.push_back(projectedEvent);
                            }
                            
                            appliedProjections.push_back(eventProjection);
                        }
                    } else {
                        projectedCommerceEvents.push_back(commerceEvent);
                    }
                } // for (event projection)
            } // If (applying projections)
            
            // If no projection was applied, uses the original commerce event.
            if (projectedCommerceEvents.empty() && projectedEvents.empty()) {
                projectedCommerceEvents.push_back(commerceEvent);
            }
        } else if (event.kind == MPEventKindAppEvent) {
            // Attribute projection lambda function
            NSDictionary * (^projectAttributes)(MPEvent *const, MPEventProjection *const) = ^(MPEvent *const event, MPEventProjection *const eventProjection) {
                NSDictionary *eventInfo = event.info;
                if (!eventInfo) {
                    return (NSDictionary *)nil;
                }
                
                NSMutableArray<MPAttributeProjection *> *attributeProjections = [[NSMutableArray alloc] initWithArray:eventProjection.attributeProjections];
                NSUInteger maxCustomParams = eventProjection.maxCustomParameters;
                NSMutableArray *projectedKeys = [[NSMutableArray alloc] init];
                NSMutableArray *nonProjectedKeys = [[NSMutableArray alloc] init];
                __block NSMutableDictionary *projectedAttributes = [[NSMutableDictionary alloc] init];
                
                if (eventInfo.count > 0) {
                    [nonProjectedKeys addObjectsFromArray:[eventInfo allKeys]];
                    [projectedAttributes addEntriesFromDictionary:[eventInfo copy]];
                }
                
                __block BOOL doesNotContainRequiredAttribute = NO;
                __block NSMutableArray<MPAttributeProjection *> *removeAttributeProjections = [[NSMutableArray alloc] init];
                
                // Building a map between keys and their respective hashes
                __block std::map<NSString *, int> keyHashMap;
                __block std::map<int, NSString *> hashKeyMap;
                NSString *key;
                NSEnumerator *keyEnumerator = [eventInfo keyEnumerator];
                while ((key = [keyEnumerator nextObject])) {
                    string attributeToHash = messageType == MPMessageTypeScreenView ? "0" : to_string(event.type);
                    attributeToHash += string([[event.name lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                    attributeToHash += string([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                    
                    int hashValue = mParticle::Hasher::hashFromString(attributeToHash);
                    keyHashMap[key] = hashValue;
                    hashKeyMap[hashValue] = key;
                }
                
                [eventInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                    [removeAttributeProjections removeAllObjects];
                    NSString *projectedAttributeKey;
                    id projectedAttributeValue;
                    
                    for (MPAttributeProjection *attributeProjection in attributeProjections) {
                        BOOL stopInnerLoop = NO;
                        
                        switch (attributeProjection.matchType) {
                            case MPProjectionMatchTypeString: {
                                if ([key caseInsensitiveCompare:attributeProjection.name] == NSOrderedSame) {
                                    projectedAttributeValue = [strongSelf transformValue:obj dataType:attributeProjection.dataType];
                                    
                                    if (projectedAttributeValue) {
                                        projectedAttributeKey = attributeProjection.projectedName ? : key;
                                        [projectedAttributes removeObjectForKey:key];
                                        projectedAttributes[projectedAttributeKey] = projectedAttributeValue;
                                        [projectedKeys addObject:projectedAttributeValue];
                                        [removeAttributeProjections addObject:attributeProjection];
                                    } else if (attributeProjection.required) {
                                        doesNotContainRequiredAttribute = YES;
                                        *stop = YES;
                                        stopInnerLoop = YES;
                                    }
                                } else if (attributeProjection.required && MPIsNull(eventInfo[attributeProjection.name])) {
                                    doesNotContainRequiredAttribute = YES;
                                    *stop = YES;
                                    stopInnerLoop = YES;
                                }
                            }
                                break;
                                
                            case MPProjectionMatchTypeHash: {
                                int hashValue = keyHashMap[key];
                                
                                if (hashValue == [attributeProjection.name integerValue]) {
                                    projectedAttributeValue = [strongSelf transformValue:obj dataType:attributeProjection.dataType];
                                    
                                    if (projectedAttributeValue) {
                                        projectedAttributeKey = attributeProjection.projectedName ? : key;
                                        [projectedAttributes removeObjectForKey:key];
                                        projectedAttributes[projectedAttributeKey] = projectedAttributeValue;
                                        [projectedKeys addObject:projectedAttributeValue];
                                        [removeAttributeProjections addObject:attributeProjection];
                                    } else if (attributeProjection.required) {
                                        doesNotContainRequiredAttribute = YES;
                                        *stop = YES;
                                        stopInnerLoop = YES;
                                    }
                                } else if (attributeProjection.required) {
                                    auto iterator = hashKeyMap.find([attributeProjection.name intValue]);
                                    
                                    if (iterator == hashKeyMap.end()) {
                                        doesNotContainRequiredAttribute = YES;
                                        *stop = YES;
                                        stopInnerLoop = YES;
                                    }
                                }
                            }
                                break;
                                
                            case MPProjectionMatchTypeField:
                                projectedAttributeKey = attributeProjection.projectedName ? : key;
                                projectedAttributes[projectedAttributeKey] = event.name;
                                [projectedKeys addObject:projectedAttributeKey];
                                [removeAttributeProjections addObject:attributeProjection];
                                break;
                                
                            case MPProjectionMatchTypeStatic:
                                projectedAttributeKey = attributeProjection.projectedName ? : key;
                                projectedAttributeValue = [strongSelf transformValue:attributeProjection.name dataType:attributeProjection.dataType];
                                
                                if (projectedAttributeValue) {
                                    projectedAttributes[projectedAttributeKey] = projectedAttributeValue;
                                    [projectedKeys addObject:projectedAttributeKey];
                                }
                                [removeAttributeProjections addObject:attributeProjection];
                                break;
                                
                            case MPProjectionMatchTypeNotSpecified:
                                break;
                        }
                        
                        if (stopInnerLoop) {
                            break;
                        }
                    }
                    
                    if (removeAttributeProjections.count > 0) {
                        [attributeProjections removeObjectsInArray:removeAttributeProjections];
                    }
                }];
                
                if (doesNotContainRequiredAttribute) {
                    return (NSDictionary *)[NSNull null];
                }
                
                // If the number of attributes is greater than the max number allowed, sort the keys and remove the excess from the bottom of the list
                [nonProjectedKeys removeObjectsInArray:projectedKeys];
                
                if (eventProjection.appendAsIs && maxCustomParams > 0) {
                    if (nonProjectedKeys.count > maxCustomParams) {
                        NSInteger numberOfRemainingSlots = maxCustomParams - projectedKeys.count;
                        
                        if (numberOfRemainingSlots > 0) {
                            [nonProjectedKeys sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                                return [obj1 compare:obj2];
                            }];
                            
                            [nonProjectedKeys removeObjectsInRange:NSMakeRange(0, numberOfRemainingSlots)];
                            [projectedAttributes removeObjectsForKeys:nonProjectedKeys];
                        }
                    }
                } else {
                    [projectedAttributes removeObjectsForKeys:nonProjectedKeys];
                }
                
                if (projectedAttributes.count == 0) {
                    projectedAttributes = nil;
                }
                
                return (NSDictionary *)projectedAttributes;
            }; // End of attribute projection lambda function
            
            // Apply projections
            MPEvent *projectedEvent;
            MPEventProjection *defaultProjection = nil;
            NSDictionary *projectedAttributes;
            NSDictionary<NSString *, NSString *> *eventInfo = [((MPEvent *)event).info transformValuesToString];
            
            if (projections.count > 0) {
                int eventNameHash = 0;
                
                for (MPEventProjection *eventProjection in projections) {
                    BOOL shouldProjectEvent = NO;
                    
                    switch (eventProjection.matchType) {
                        case MPProjectionMatchTypeString:
                            if ([((MPEvent *)event).name caseInsensitiveCompare:eventProjection.name] == NSOrderedSame) {
                                if (eventProjection.projectionMatches) {
                                    __block BOOL foundNonMatch = NO;
                                    [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                                        if (![projectionMatch.attributeValues caseInsensitiveContainsObject:[eventInfo valueForCaseInsensitiveKey:projectionMatch.attributeKey]]) {
                                            foundNonMatch = YES;
                                            *stop = YES;
                                        }
                                    }];
                                    shouldProjectEvent = !foundNonMatch;
                                } else {
                                    shouldProjectEvent = YES;
                                }
                            }
                            break;
                            
                        case MPProjectionMatchTypeHash: {
                            if (eventNameHash == 0) {
                                string nameToHash = messageType == MPMessageTypeScreenView ? "0" : to_string(((MPEvent *)event).type);
                                nameToHash += string([[((MPEvent *)event).name lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                                eventNameHash = mParticle::Hasher::hashFromString(nameToHash);
                            }
                            
                            if (eventNameHash == [eventProjection.name integerValue]) {
                                if (eventProjection.projectionMatches) {
                                    __block BOOL foundNonMatch = NO;
                                    [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                                        if (![projectionMatch.attributeValues caseInsensitiveContainsObject:[eventInfo valueForCaseInsensitiveKey:projectionMatch.attributeKey]]) {
                                            foundNonMatch = YES;
                                            *stop = YES;
                                        }
                                    }];
                                    shouldProjectEvent = !foundNonMatch;
                                } else {
                                    shouldProjectEvent = YES;
                                }
                            }
                        }
                            break;
                            
                        case MPProjectionMatchTypeNotSpecified:
                            shouldProjectEvent = YES;
                            break;
                            
                        default: // Filter and Static... only applicable to attributes
                            break;
                    }
                    
                    if (shouldProjectEvent) {
                        projectedEvent = [event copy];
                        projectedAttributes = projectAttributes(projectedEvent, eventProjection);
                        
                        if ((NSNull *)projectedAttributes != [NSNull null]) {
                            projectedEvent.info = projectedAttributes;
                            
                            if (eventProjection.projectedName) {
                                if (eventProjection.projectionMatches) {
                                    __block BOOL foundNonMatch = NO;
                                    [eventProjection.projectionMatches enumerateObjectsUsingBlock:^(MPProjectionMatch * _Nonnull projectionMatch, NSUInteger idx, BOOL * _Nonnull stop) {
                                        if (![projectionMatch.attributeValues caseInsensitiveContainsObject:[eventInfo valueForCaseInsensitiveKey:projectionMatch.attributeKey]]) {
                                            foundNonMatch = YES;
                                            *stop = YES;
                                        }
                                    }];
                                    if (!foundNonMatch) {
                                        projectedEvent.name = eventProjection.projectedName;
                                    }
                                    
                                } else {
                                    projectedEvent.name = eventProjection.projectedName;
                                }
                            }
                            
                            projectedEvents.push_back(projectedEvent);
                            appliedProjections.push_back(eventProjection);
                        }
                    }
                }
            }
            
            // Default projection, applied only if no other projection was applicable
            if (projectedEvents.empty()) {
                defaultProjection = kitConfiguration.defaultProjections[messageType];
                
                if (!MPIsNull(defaultProjection)) {
                    projectedEvent = [event copy];
                    projectedAttributes = projectAttributes(projectedEvent, defaultProjection);
                    
                    if ((NSNull *)projectedAttributes != [NSNull null]) {
                        projectedEvent.info = projectedAttributes;
                        
                        if (defaultProjection.projectedName && defaultProjection.projectionType == MPProjectionTypeEvent) {
                            projectedEvent.name = defaultProjection.projectedName;
                        }
                        
                        projectedEvents.push_back(projectedEvent);
                        appliedProjections.push_back(defaultProjection);
                    }
                }
                
                if (projectedEvents.empty()) {
                    projectedEvents.push_back((MPEvent *)event);
                }
            }
        }
        
        dispatch_semaphore_signal(strongSelf->projectionSemaphore);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
        });
    });
}

- (BOOL)shouldIncludeEventAttributes:(MPEventAbstract *)event afterAttributeValueFilteringWithConfiguration:(MPKitConfiguration *)configuration {
    if (!configuration.attributeValueFilteringIsActive) {
        return YES;
    }
    
    NSDictionary<NSString *, id> *attributes = event.kind == MPEventKindCommerceEvent ? ((MPCommerceEvent *)event).userDefinedAttributes : ((MPEvent *)event).info;
    if (attributes.count == 0) {
        attributes = nil;
    }
    
    __block BOOL isMatch = NO;
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *hashedAttribute = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
        if ([hashedAttribute isEqualToString:configuration.attributeValueFilteringHashedAttribute]) {
            *stop = YES;
            if ([obj isKindOfClass:[NSString class]]) {
                NSString *value = (NSString *)obj;
                NSString *hashedValue = [NSString stringWithCString:mParticle::Hasher::hashString([[value lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                if ([hashedValue isEqualToString:configuration.attributeValueFilteringHashedValue]) {
                    isMatch = YES;
                }
            }
        }
    }];
    
    BOOL shouldInclude = configuration.attributeValueFilteringShouldIncludeMatches ? isMatch : !isMatch;
    return shouldInclude;
}

- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType {
    id value = nil;
    
    switch (dataType) {
        case MPDataTypeString:
            if (MPIsNull(originalValue)) {
                return nil;
            }
            
            value = originalValue;
            break;
            
        case MPDataTypeInt:
        case MPDataTypeLong: {
            if (MPIsNull(originalValue)) {
                return @0;
            }
            
            NSInteger integerValue = [originalValue integerValue];
            
            if (integerValue != 0) {
                value = @(integerValue);
            } else {
                if ([originalValue isEqualToString:@"0"]) {
                    value = @(integerValue);
                } else {
                    value = nil;
                    MPILogError(@"Value '%@' was expected to be a number string.", originalValue);
                }
            }
        }
            break;
            
        case MPDataTypeFloat: {
            if (MPIsNull(originalValue)) {
                return @0.0;
            }
            
            float floatValue = [originalValue floatValue];
            
            if (floatValue != HUGE_VAL && floatValue != -HUGE_VAL && floatValue != 0.0) {
                value = @(floatValue);
            } else {
                if ([originalValue isEqualToString:@"0"] || [originalValue isEqualToString:@"0.0"] || [originalValue isEqualToString:@".0"]) {
                    value = @(floatValue);
                } else {
                    value = [NSNull null];
                    MPILogError(@"Attribute '%@' was expected to be a number string.", originalValue);
                }
            }
        }
            break;
            
        case MPDataTypeBool: {
            if (MPIsNull(originalValue)) {
                return @NO;
            }
            
            if ([originalValue caseInsensitiveCompare:@"true"] == NSOrderedSame) {
                value = @YES;
            } else {
                value = @NO;
            }
        }
            break;
    }
    
    return value;
}

#pragma mark Public methods
- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forEvent:(nullable MPEventAbstract *const)event selector:(nonnull SEL)selector completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler {
    __block MPEventAbstract *forwardEvent = [event copy];
    __block MPKitFilter *kitFilter;
    NSNumber *zero = @0;
    void (^completionHandlerCopy)(MPKitFilter *, BOOL finished) = [completionHandler copy];
    
    NSString *selectorString = NSStringFromSelector(selector);
    NSString *messageType = [self methodMessageTypeMapping][selectorString];

    __block BOOL shouldFilter = NO;

    // No event filter
    if (!event) {
        shouldFilter = kitConfiguration.messageTypeFilters[messageType] && [kitConfiguration.messageTypeFilters[messageType] isEqualToNumber:zero];
        MPKitFilter *kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter filteredAttributes:nil] : nil;
        
        completionHandler(kitFilter, YES);
        return;
    }
    
    // Attribute value filtering
    if (![self shouldIncludeEventAttributes:event afterAttributeValueFilteringWithConfiguration:kitConfiguration]) {
        if (event.kind == MPEventKindCommerceEvent) {
            kitFilter = [[MPKitFilter alloc] initWithEvent:event shouldFilter:YES appliedProjections:nil];
        } else {
            kitFilter = [[MPKitFilter alloc] initWithFilter:YES filteredAttributes:nil];
        }
        
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Event type filter
    __block NSString *hashValue = [NSString stringWithCString:mParticle::EventTypeName::hashForEventType(static_cast<mParticle::EventType>(event.type)).c_str() encoding:NSUTF8StringEncoding];
    
    shouldFilter = kitConfiguration.eventTypeFilters[hashValue] && [kitConfiguration.eventTypeFilters[hashValue] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter filteredAttributes:nil];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Message type filter
    shouldFilter = kitConfiguration.messageTypeFilters[messageType] && [kitConfiguration.messageTypeFilters[messageType] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter filteredAttributes:nil];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    if (event.kind == MPEventKindCommerceEvent) {
        MPCommerceEvent *commerceEvent = (MPCommerceEvent *)event;
        
        // Entity type filter
        MPCommerceEventKind commerceEventKind = [commerceEvent commerceEventKind];
        NSString *commerceEventKindValue = [@(commerceEventKind) stringValue];
        shouldFilter = [kitConfiguration.commerceEventEntityTypeFilters[commerceEventKindValue] isEqualToNumber:zero];
        if (shouldFilter) {
            switch (commerceEventKind) {
                case MPCommerceEventKindProduct:
                case MPCommerceEventKindImpression:
                    [(MPCommerceEvent *)forwardEvent setProducts:nil];
                    [(MPCommerceEvent *)forwardEvent setImpressions:nil];
                    break;
                    
                case MPCommerceEventKindPromotion:
                    [((MPCommerceEvent *)forwardEvent).promotionContainer setPromotions:nil];
                    break;
                    
                default:
                    forwardEvent = nil;
                    break;
            }
            
            kitFilter = [[MPKitFilter alloc] initWithEvent:(forwardEvent ? forwardEvent : commerceEvent)
                                              shouldFilter:NO
                                        appliedProjections:nil];
            
            completionHandlerCopy(kitFilter, YES);
            
            return;
        } else { // App family attribute and Commerce event attribute filters
            // App family attribute filter
            NSDictionary *appFamilyFilter = kitConfiguration.commerceEventAppFamilyAttributeFilters[commerceEventKindValue];
            
            if (appFamilyFilter.count > 0) {
                switch (commerceEventKind) {
                    case MPCommerceEventKindProduct: {
                        __block NSMutableArray *products = [[NSMutableArray alloc] init];
                        
                        [commerceEvent.products enumerateObjectsUsingBlock:^(MPProduct *product, NSUInteger idx, BOOL *stop) {
                            MPProduct *filteredProduct = [product copyMatchingHashedProperties:appFamilyFilter];
                            
                            if (filteredProduct) {
                                [products addObject:filteredProduct];
                            }
                        }];
                        
                        if (products.count > 0) {
                            [(MPCommerceEvent *)forwardEvent setProducts:products];
                        }
                    }
                        break;
                        
                    case MPCommerceEventKindImpression:
                        ((MPCommerceEvent *)forwardEvent).impressions = [commerceEvent copyImpressionsMatchingHashedProperties:appFamilyFilter];
                        break;
                        
                    case MPCommerceEventKindPromotion:
                        ((MPCommerceEvent *)forwardEvent).promotionContainer = [commerceEvent.promotionContainer copyMatchingHashedProperties:appFamilyFilter];
                        break;
                        
                    default:
                        break;
                }
            }
            
            NSDictionary *commerceEventAttributeFilters = kitConfiguration.commerceEventAttributeFilters;
            if (commerceEventAttributeFilters) {
                // Commerce event attribute filter (expanded attributes)
                __block NSString *auxString;
                __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] init];
                
                [[(MPCommerceEvent *)forwardEvent beautifiedAttributes] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                    auxString = [NSString stringWithFormat:@"%@%@", [@(event.type) stringValue], key];
                    hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                    
                    id filterValue = commerceEventAttributeFilters[hashValue];
                    BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
                    
                    if (!filterValue || (filterValue && !filterValueIsFalse)) {
                        filteredAttributes[key] = obj;
                    }
                }];
                
                [(MPCommerceEvent *)forwardEvent setBeautifiedAttributes:(filteredAttributes.count > 0 ? filteredAttributes : nil)];
                
                // Commerce event attribute filter (user defined attributes)
                filteredAttributes = [[NSMutableDictionary alloc] init];
                
                [[(MPCommerceEvent *)forwardEvent userDefinedAttributes] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                    auxString = [NSString stringWithFormat:@"%@%@", [@(event.type) stringValue], key];
                    hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                    
                    id filterValue = commerceEventAttributeFilters[hashValue];
                    BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
                    
                    if (!filterValue || (filterValue && !filterValueIsFalse)) {
                        filteredAttributes[key] = obj;
                    }
                }];
                
                [(MPCommerceEvent *)forwardEvent setUserDefinedAttributes:(filteredAttributes.count > 0 ? filteredAttributes : nil)];
                
                // Transaction attributes
                __block MPTransactionAttributes *filteredTransactionAttributes = [[MPTransactionAttributes alloc] init];
                
                [[((MPCommerceEvent *)forwardEvent).transactionAttributes beautifiedDictionaryRepresentation] enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
                    auxString = [NSString stringWithFormat:@"%@%@", [@(event.type) stringValue], key];
                    hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
                    
                    id filterValue = commerceEventAttributeFilters[hashValue];
                    BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
                    
                    if (!filterValue || (filterValue && !filterValueIsFalse)) {
                        if ([key isEqualToString:kMPExpTAAffiliation]) {
                            filteredTransactionAttributes.affiliation = ((MPCommerceEvent *)forwardEvent).transactionAttributes.affiliation;
                        } else if ([key isEqualToString:kMPExpTAShipping]) {
                            filteredTransactionAttributes.shipping = ((MPCommerceEvent *)forwardEvent).transactionAttributes.shipping;
                        } else if ([key isEqualToString:kMPExpTATax]) {
                            filteredTransactionAttributes.tax = ((MPCommerceEvent *)forwardEvent).transactionAttributes.tax;
                        } else if ([key isEqualToString:kMPExpTARevenue]) {
                            filteredTransactionAttributes.revenue = ((MPCommerceEvent *)forwardEvent).transactionAttributes.revenue;
                        } else if ([key isEqualToString:kMPExpTATransactionId]) {
                            filteredTransactionAttributes.transactionId = ((MPCommerceEvent *)forwardEvent).transactionAttributes.transactionId;
                        } else if ([key isEqualToString:kMPExpTACouponCode]) {
                            filteredTransactionAttributes.couponCode = ((MPCommerceEvent *)forwardEvent).transactionAttributes.couponCode;
                        }
                    }
                }];
                
                ((MPCommerceEvent *)forwardEvent).transactionAttributes = filteredTransactionAttributes;
            }
        }
    } else if (event.kind == MPEventKindAppEvent) {
        NSDictionary *attributeFilters;
        NSDictionary *nameFilters;
        NSString *eventTypeString;
        
        if ([selectorString isEqualToString:@"logScreen:"]) { // Screen name and screen attribute filters
            eventTypeString = @"0";
            nameFilters = kitConfiguration.screenNameFilters;
            attributeFilters = kitConfiguration.screenAttributeFilters;
        } else { // Event name and event attribute filters
            eventTypeString = [@(event.type) stringValue];
            nameFilters = kitConfiguration.eventNameFilters;
            attributeFilters = kitConfiguration.eventAttributeFilters;
        }
        
        __block NSString *auxString = [[NSString stringWithFormat:@"%@%@", eventTypeString, ((MPEvent *)event).name] lowercaseString];
        hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([auxString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                       encoding:NSUTF8StringEncoding];
        
        shouldFilter = nameFilters[hashValue] && [nameFilters[hashValue] isEqualToNumber:zero];
        if (shouldFilter) {
            kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter filteredAttributes:nil];
            completionHandlerCopy(kitFilter, YES);
            return;
        }
        
        // Attributes
        if (((MPEvent *)event).info) {
            __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] initWithCapacity:((MPEvent *)forwardEvent).info.count];
            
            [((MPEvent *)forwardEvent).info enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
                auxString = [[NSString stringWithFormat:@"%@%@%@", eventTypeString, ((MPEvent *)event).name, key] lowercaseString];
                hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([auxString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                               encoding:NSUTF8StringEncoding];
                
                id attributeFilterValue = attributeFilters[hashValue];
                BOOL attributeFilterIsFalse = [attributeFilterValue isEqualToNumber:zero];
                
                if (!attributeFilterValue || (attributeFilterValue && !attributeFilterIsFalse)) {
                    filteredAttributes[key] = obj;
                } else if (attributeFilterValue && attributeFilterIsFalse) {
                    shouldFilter = YES;
                }
            }];
            
            ((MPEvent *)forwardEvent).info = filteredAttributes.count > 0 ? filteredAttributes : nil;
        }
    }
    
    MPMessageType messageTypeCode = (MPMessageType)mParticle::MessageTypeName::messageTypeForName(string([messageType UTF8String]));
    if (messageTypeCode < MPMessageTypeSessionStart || messageTypeCode > MPMessageTypeUserIdentityChange) {
        messageTypeCode = MPMessageTypeUnknown;
    }

    [self project:kitRegister kitConfiguration:kitConfiguration event:forwardEvent messageType:messageTypeCode completionHandler:^(vector<MPCommerceEvent *> projectedCommerceEvents, vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections) {
        NSArray<MPEventProjection *> *appliedProjectionsArray = !appliedProjections.empty() ? [NSArray arrayWithObjects:&appliedProjections[0] count:appliedProjections.size()] : nil;
        
        if (!projectedEvents.empty()) {
            __weak auto lastProjectedEvent = projectedEvents.back();
            
            for (auto &projectedEvent : projectedEvents) {
                kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:shouldFilter appliedProjections:appliedProjectionsArray];
                completionHandlerCopy(kitFilter, lastProjectedEvent == projectedEvent);
            }
        }
        
        if (!projectedCommerceEvents.empty()) {
            const auto lastProjectedCommerceEvent = projectedCommerceEvents.back();
            
            for (auto &projectedCommerceEvent : projectedCommerceEvents) {
                kitFilter = [[MPKitFilter alloc] initWithEvent:projectedCommerceEvent shouldFilter:NO appliedProjections:appliedProjectionsArray];
                completionHandlerCopy(kitFilter, lastProjectedCommerceEvent == projectedCommerceEvent);
            }
        }
    }];
}

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forUserAttributes:(nonnull NSDictionary *)userAttributes completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler {
    MPKitFilter *kitFilter = nil;
    if (!userAttributes) {
        completionHandler(kitFilter, YES);
        return;
    }
    
    __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    
    [userAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                 encoding:NSUTF8StringEncoding];
        
        BOOL shouldFilter = kitConfiguration.userAttributeFilters[hashValue] && [kitConfiguration.userAttributeFilters[hashValue] isEqualToNumber:@0];
        if (!shouldFilter) {
            filteredAttributes[key] = [value copy];
        }
    }];
    
    if (filteredAttributes.count > 0) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:YES filteredAttributes:filteredAttributes];
    }
    
    completionHandler(kitFilter, YES);
}

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forUserAttributeKey:(nonnull NSString *)key value:(nonnull id)value completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler {
    MPKitFilter *kitFilter = nil;
    if (!key) {
        completionHandler(kitFilter, YES);
        return;
    }
    
    NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                             encoding:NSUTF8StringEncoding];
    
    BOOL shouldFilter = kitConfiguration.userAttributeFilters[hashValue] && [kitConfiguration.userAttributeFilters[hashValue] isEqualToNumber:@0];
    
    kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter filteredAttributes:nil] : nil;
    
    completionHandler(kitFilter, YES);
}

- (void)filter:(nonnull id<MPExtensionKitProtocol>)kitRegister kitConfiguration:(nonnull MPKitConfiguration *)kitConfiguration forUserIdentityKey:(nonnull NSString *)key identityType:(MPUserIdentity)identityType completionHandler:(void (^ _Nonnull)(MPKitFilter * _Nonnull kitFilter, BOOL finished))completionHandler {
    NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)identityType];
    
    BOOL shouldFilter = kitConfiguration.userIdentityFilters[identityTypeString] && [kitConfiguration.userIdentityFilters[identityTypeString] isEqualToNumber:@0];
        
    MPKitFilter *kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter filteredAttributes:nil] : nil;
    
    completionHandler(kitFilter, YES);
}

@end
