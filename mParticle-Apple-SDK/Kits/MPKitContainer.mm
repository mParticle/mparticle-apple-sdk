//
//  MPKitContainer.mm
//
//  Copyright 2016 mParticle, Inc.
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

#import "MPKitContainer.h"
#import "MPKitAbstract.h"
#import "MPKitExecStatus.h"
#import "MPEnums.h"
#import "MPKitForesee.h"
#include "MessageTypeName.h"
#import "MPStateMachine.h"
#include "MPHasher.h"
#import "MPKitConfiguration.h"
#import <UIKit/UIKit.h>
#import "MPForwardRecord.h"
#import "MPPersistenceController.h"
#import "MPLogger.h"
#import "MPKitFilter.h"
#include "EventTypeName.h"
#import "MPEvent.h"
#import "MPCommerceEvent.h"
#import "MPCommerceEvent+Dictionary.h"
#import "MPEventProjection.h"
#include <map>
#import "MPAttributeProjection.h"
#import "MPPromotion.h"
#import "MPPromotion+Dictionary.h"
#import "MPProduct.h"
#import "MPProduct+Dictionary.h"
#import "NSDictionary+MPCaseInsensitive.h"
#import "MPKitAbstract.h"
#import "NSUserDefaults+mParticle.h"

#if defined(MP_KIT_ADJUST)
    #import "MPKitAdjust.h"
#endif

#if defined(MP_KIT_APPBOY)
    #import "MPKitAppboy.h"
#endif

#if defined(MP_KIT_APPSFLYER)
    #import "MPKitAppsFlyer.h"
#endif

#if defined(MP_KIT_BRANCHMETRICS)
    #import "MPKitBranchMetrics.h"
#endif

#if defined(MP_KIT_CRITTERCISM)
    #import "MPKitCrittercism.h"
#endif

#if defined(MP_KIT_COMSCORE)
    #import "MPKitComScore.h"
#endif

#if defined(MP_KIT_FLURRY)
    #import "MPKitFlurry.h"
#endif

#if defined(MP_KIT_KAHUNA)
    #import "MPKitKahuna.h"
#endif

#if defined(MP_KIT_KOCHAVA)
    #import "MPKitKochava.h"
#endif

#if defined(MP_KIT_LOCALYTICS)
    #import "MPKitLocalytics.h"
#endif

#if defined(MP_KIT_WOOTRIC)
    #import "MPKitWootric.h"
#endif

NSString *const kitFileExtension = @"eks";

@interface MPKitContainer() {
    dispatch_semaphore_t kitsSemaphore;
    BOOL kitsInitialized;
}

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

@end


@implementation MPKitContainer

@synthesize kits = _kits;

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    kitsInitialized = NO;
    kitsSemaphore = dispatch_semaphore_create(1);
    
    if (![MPStateMachine sharedInstance].optOut) {
        [self initializeKits];
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleApplicationDidFinishLaunching:)
                               name:UIApplicationDidFinishLaunchingNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:UIApplicationDidFinishLaunchingNotification object:nil];
}

#pragma mark Notification handlers
- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    stateMachine.launchOptions = [notification userInfo];
    
    for (MPKitAbstract *kit in self.kits) {
        if (![kit started]) {
            if ([kit respondsToSelector:@selector(setLaunchOptions:)]) {
                [kit performSelector:@selector(setLaunchOptions:) withObject:stateMachine.launchOptions];
            }
            
            if ([kit respondsToSelector:@selector(start)]) {
                [kit start];
            }
        }
    }
}

#pragma mark Private methods
- (void)emplaceKit:(MPKitAbstract *)kit {
    if (!kit) {
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"kitCode == %@", kit.kitCode];
    id existingKit = [[self.kits filteredArrayUsingPredicate:predicate] firstObject];
    
    if (!existingKit) {
        [self.kits addObject:kit];
    }
}

- (void)flushSerializedKits {
    self.kits = nil;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    
    if ([fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:stateMachineDirectoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"pathExtension == '%@'", kitFileExtension];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        for (NSString *fileName in directoryContents) {
            NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:fileName];
            
            [fileManager removeItemAtPath:kitPath error:nil];
        }
    }
}

- (void)initializeKits {
    [self willChangeValueForKey:@"kits"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    
    if ([fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:stateMachineDirectoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"pathExtension == '%@'", kitFileExtension];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        if (directoryContents.count > 0) {
            _kits = [[NSMutableArray alloc] initWithCapacity:directoryContents.count];
            
            for (NSString *fileName in directoryContents) {
                NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:fileName];
                
                @try {
                    id unarchivedObject = [NSKeyedUnarchiver unarchiveObjectWithFile:kitPath];
                    
                    if ([unarchivedObject isKindOfClass:[MPKitConfiguration class]]) {
                        MPKitConfiguration *kitConfiguration = (MPKitConfiguration *)unarchivedObject;
                        self.kitConfigurations[kitConfiguration.kitCode] = kitConfiguration;
                        [self startKit:kitConfiguration.kitCode configuration:kitConfiguration.configuration];
                    }
                } @catch (NSException *exception) {
                    [self removeKitConfigurationAtPath:kitPath];
                }
            }
        }
    }
    
    kitsInitialized = YES;
    [self didChangeValueForKey:@"kits"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([MPStateMachine sharedInstance].logLevel >= MPLogLevelDebug) {
            NSArray<NSNumber *> *supportedKits = [self supportedKits];
            NSMutableString *listOfKits = [[NSMutableString alloc] initWithString:@"Included kits: {"];
            for (NSNumber *supportedKit in supportedKits) {
                [listOfKits appendFormat:@"%@, ", [MPKitAbstract nameForKit:supportedKit]];
            }
            
            [listOfKits deleteCharactersInRange:NSMakeRange(listOfKits.length - 2, 2)];
            [listOfKits appendString:@"}"];
            
            MPLogDebug(@"%@", listOfKits);
        }
    });
}

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
                                                  @"leaveBreadcrumb:":[NSString stringWithCString:mParticle::MessageTypeName::nameForMessageType(mParticle::Breadcrumb).c_str() encoding:NSUTF8StringEncoding]
                                                  };
    
    return methodMessageTypeDictionary;
}

- (MPKitAbstract *)startKit:(NSNumber *)kitCode configuration:(NSDictionary *)configuration {
    MPKitAbstract *kit = nil;
    MPKitInstance kitInstanceCode = (MPKitInstance)[kitCode integerValue];
    
    switch (kitInstanceCode) {
        case MPKitInstanceForesee:
            kit = [[MPKitForesee alloc] initWithConfiguration:configuration];
            break;
#if defined(MP_KIT_ADJUST)
        case MPKitInstanceAdjust:
            kit = [[MPKitAdjust alloc] initWithConfiguration:configuration];
            break;
#endif
#if defined(MP_KIT_APPBOY)
        case MPKitInstanceAppboy:
            kit = [[MPKitAppboy alloc] initWithConfiguration:configuration startImmediately:NO];
            break;
#endif

#if defined(MP_KIT_APPSFLYER)
        case MPKitInstanceAppsFlyer:
            kit = [[MPKitAppsFlyer alloc] initWithConfiguration:configuration];
            break;
#endif

#if defined(MP_KIT_BRANCHMETRICS)
        case MPKitInstanceBranchMetrics:
            kit = [[MPKitBranchMetrics alloc] initWithConfiguration:configuration startImmediately:NO];
            break;
#endif
#if defined(MP_KIT_CRITTERCISM)
        case MPKitInstanceCrittercism:
            kit = [[MPKitCrittercism alloc] initWithConfiguration:configuration];
            break;
#endif
#if defined(MP_KIT_COMSCORE)
        case MPKitInstanceComScore:
            kit = [[MPKitComScore alloc] initWithConfiguration:configuration];
            break;
#endif
#if defined(MP_KIT_FLURRY)
        case MPKitInstanceFlurry:
            kit = [[MPKitFlurry alloc] initWithConfiguration:configuration startImmediately:NO];
            break;
#endif
#if defined(MP_KIT_KAHUNA)
        case MPKitInstanceKahuna:
            kit = [[MPKitKahuna alloc] initWithConfiguration:configuration];
            break;
#endif
#if defined(MP_KIT_KOCHAVA)
        case MPKitInstanceKochava:
            kit = [[MPKitKochava alloc] initWithConfiguration:configuration];
            break;
#endif
#if defined(MP_KIT_LOCALYTICS)
        case MPKitInstanceLocalytics:
            kit = [[MPKitLocalytics alloc] initWithConfiguration:configuration startImmediately:NO];
            break;
#endif
#if defined(MP_KIT_WOOTRIC)
        case MPKitInstanceWootric:
            kit = [[MPKitWootric alloc] initWithConfiguration:configuration];
            break;
#endif
        default:
            break;
    }
    
    if (kit) {
        kit.kitCode = kitCode;
        [self emplaceKit:kit];
    }
    
    return kit;
}

- (id)transformValue:(NSString *)originalValue dataType:(MPDataType)dataType {
    id value = nil;
    
    switch (dataType) {
        case MPDataTypeString:
            value = originalValue;
            break;
            
        case MPDataTypeInt:
        case MPDataTypeLong: {
            NSInteger integerValue = [originalValue integerValue];
            
            if (integerValue != 0) {
                value = @(integerValue);
            } else {
                if ([originalValue isEqualToString:@"0"]) {
                    value = @(integerValue);
                } else {
                    value = [NSNull null];
                    MPLogError(@"Value '%@' was expected to be a number string.", originalValue);
                }
            }
        }
            break;
            
        case MPDataTypeFloat: {
            float floatValue = [originalValue floatValue];
            
            if (floatValue != HUGE_VAL && floatValue != -HUGE_VAL && floatValue != 0.0) {
                value = @(floatValue);
            } else {
                if ([originalValue isEqualToString:@"0"] || [originalValue isEqualToString:@"0.0"] || [originalValue isEqualToString:@".0"]) {
                    value = @(floatValue);
                } else {
                    value = [NSNull null];
                    MPLogError(@"Attribute '%@' was expected to be a number string.", originalValue);
                }
            }
        }
            break;
            
        case MPDataTypeBool: {
            NSString *lowercaseOriginalValue = [originalValue lowercaseString];
            
            if ([lowercaseOriginalValue isEqualToString:@"true"]) {
                value = @YES;
            } else if ([lowercaseOriginalValue isEqualToString:@"false"]) {
                value = @NO;
            } else {
                value = originalValue;
            }
        }
            break;
    }
    
    return value;
}

#pragma mark Public class methods
+ (MPKitContainer *)sharedInstance {
    static MPKitContainer *sharedInstance = nil;
    static dispatch_once_t kitProxyPredicate;
    
    dispatch_once(&kitProxyPredicate, ^{
        sharedInstance = [[MPKitContainer alloc] init];
    });
    
    return sharedInstance;
}

#pragma mark Public accessors
- (NSMutableArray<__kindof MPKitAbstract *> *)kits {
    if ([MPStateMachine sharedInstance].optOut) {
        _kits = nil;
        return nil;
    }
    
    if (_kits) {
        return _kits;
    } else if (!kitsInitialized) {
        [self initializeKits];
    }
    
    if (!_kits) {
        _kits = [[NSMutableArray alloc] initWithCapacity:1];
    }
    
    return _kits;
}

- (void)setKits:(NSMutableArray<__kindof MPKitAbstract *> *)kits {
    if (!kits) {
        kitsInitialized = NO;
    }
    
    _kits = kits;
}

- (NSMutableDictionary<NSNumber *, MPKitConfiguration *> *)kitConfigurations {
    if (_kitConfigurations) {
        return _kitConfigurations;
    }
    
    _kitConfigurations = [[NSMutableDictionary alloc] initWithCapacity:1];
    
    return _kitConfigurations;
}

- (BOOL)shouldIncludeEventWithAttributes:(NSDictionary<NSString *, id> *)attributes afterAttributeValueFilteringWithConfiguration:(MPKitConfiguration *)configuration {
    
    if (!configuration.attributeValueFilteringIsActive) {
        return YES;
    }
    
    __block BOOL isMatch = NO;
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
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

#pragma mark Filtering methods
- (void)filterKit:(MPKitAbstract *)kit forCommerceEvent:(MPCommerceEvent *const)commerceEvent completionHandler:(void (^)(MPKitFilter *kitFilter, BOOL finished))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    NSNumber *zero = @0;
    __block MPKitFilter *kitFilter;
    void (^completionHandlerCopy)(MPKitFilter *, BOOL finished) = [completionHandler copy];
    
    // Attribute value filtering
    if (![self shouldIncludeEventWithAttributes:commerceEvent.userDefinedAttributes afterAttributeValueFilteringWithConfiguration:kitConfiguration]) {
        kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:YES];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Event type filter
    __block NSString *hashValue = [NSString stringWithCString:mParticle::EventTypeName::hashForEventType(static_cast<mParticle::EventType>([commerceEvent type])).c_str() encoding:NSUTF8StringEncoding];
    
    __block BOOL shouldFilter = kitConfiguration.eventTypeFilters[hashValue] && [kitConfiguration.eventTypeFilters[hashValue] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    __block MPCommerceEvent *forwardCommerceEvent = [commerceEvent copy];
    
    // Entity type filter
    MPCommerceEventKind commerceEventKind = [commerceEvent kind];
    NSString *commerceEventKindValue = [@(commerceEventKind) stringValue];
    shouldFilter = [kitConfiguration.commerceEventEntityTypeFilters[commerceEventKindValue] isEqualToNumber:zero];
    if (shouldFilter) {
        switch (commerceEventKind) {
            case MPCommerceEventKindProduct:
            case MPCommerceEventKindImpression:
                [forwardCommerceEvent setProducts:nil];
                [forwardCommerceEvent setImpressions:nil];
                break;
                
            case MPCommerceEventKindPromotion:
                [forwardCommerceEvent.promotionContainer setPromotions:nil];
                break;
                
            default:
                forwardCommerceEvent = nil;
                break;
        }
        
        if (forwardCommerceEvent) {
            kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:forwardCommerceEvent shouldFilter:NO];
            completionHandlerCopy(kitFilter, YES);
        } else {
            kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:commerceEvent shouldFilter:NO];
            completionHandlerCopy(kitFilter, YES);
        }
        
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
                        [forwardCommerceEvent setProducts:products];
                    }
                }
                    break;
                    
                case MPCommerceEventKindImpression:
                    forwardCommerceEvent.impressions = [commerceEvent copyImpressionsMatchingHashedProperties:appFamilyFilter];
                    break;
                    
                case MPCommerceEventKindPromotion:
                    forwardCommerceEvent.promotionContainer = [commerceEvent.promotionContainer copyMatchingHashedProperties:appFamilyFilter];
                    break;
                    
                default:
                    break;
            }
        }
        
        // Commerce event attribute filter (expanded attributes)
        __block NSString *auxString;
        __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] init];
        
        [[forwardCommerceEvent beautifiedAttributes] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            auxString = [NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key];
            hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
            
            id filterValue = kitConfiguration.commerceEventAttributeFilters[hashValue];
            BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
            
            if (!filterValue || (filterValue && !filterValueIsFalse)) {
                filteredAttributes[key] = obj;
            }
        }];
        
        [forwardCommerceEvent setBeautifiedAttributes:(filteredAttributes.count > 0 ? filteredAttributes : nil)];
        
        // Commerce event attribute filter (user defined attributes)
        filteredAttributes = [[NSMutableDictionary alloc] init];
        
        [[forwardCommerceEvent userDefinedAttributes] enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            auxString = [NSString stringWithFormat:@"%@%@", [@([commerceEvent type]) stringValue], key];
            hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[auxString lowercaseString] UTF8String]).c_str() encoding:NSUTF8StringEncoding];
            
            id filterValue = kitConfiguration.commerceEventAttributeFilters[hashValue];
            BOOL filterValueIsFalse = [filterValue isEqualToNumber:zero];
            
            if (!filterValue || (filterValue && !filterValueIsFalse)) {
                filteredAttributes[key] = obj;
            }
        }];
        
        [forwardCommerceEvent setUserDefinedAttributes:(filteredAttributes.count > 0 ? filteredAttributes : nil)];
    }
    
    [self projectKit:kit
       commerceEvent:forwardCommerceEvent
   completionHandler:^(vector<MPCommerceEvent *> projectedCommerceEvents, vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections) {
       NSArray<MPEventProjection *> *appliedProjectionsArray = !appliedProjections.empty() ? [NSArray arrayWithObjects:&appliedProjections[0] count:appliedProjections.size()] : nil;
       
       if (!projectedEvents.empty()) {
           const auto lastProjectedEvent = projectedEvents.back();
           
           for (auto &projectedEvent : projectedEvents) {
               kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:NO appliedProjections:appliedProjectionsArray];
               completionHandlerCopy(kitFilter, lastProjectedEvent == projectedEvent);
           }
       }
       
       if (!projectedCommerceEvents.empty()) {
           const auto lastProjectedCommerceEvent = projectedCommerceEvents.back();
           
           for (auto &projectedCommerceEvent : projectedCommerceEvents) {
               kitFilter = [[MPKitFilter alloc] initWithCommerceEvent:projectedCommerceEvent shouldFilter:NO appliedProjections:appliedProjectionsArray];
               completionHandlerCopy(kitFilter, lastProjectedCommerceEvent == projectedCommerceEvent);
           }
       }
   }];
}

- (void)filterKit:(MPKitAbstract *)kit forEvent:(MPEvent *const)event selector:(SEL)selector completionHandler:(void (^)(MPKitFilter *kitFilter, BOOL finished))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    NSNumber *zero = @0;
    __block MPKitFilter *kitFilter;
    void (^completionHandlerCopy)(MPKitFilter *, BOOL) = [completionHandler copy];
    
    // Attribute value filtering
    if (![self shouldIncludeEventWithAttributes:event.info afterAttributeValueFilteringWithConfiguration:kitConfiguration]) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:YES];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Event type filter
    __block NSString *hashValue = [NSString stringWithCString:mParticle::EventTypeName::hashForEventType(static_cast<mParticle::EventType>(event.type)).c_str() encoding:NSUTF8StringEncoding];
    
    __block BOOL shouldFilter = kitConfiguration.eventTypeFilters[hashValue] && [kitConfiguration.eventTypeFilters[hashValue] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Message type filter
    NSString *selectorString = NSStringFromSelector(selector);
    NSString *messageType = [self methodMessageTypeMapping][selectorString];
    if (messageType) {
        shouldFilter = kitConfiguration.messageTypeFilters[messageType] && [kitConfiguration.messageTypeFilters[messageType] isEqualToNumber:zero];
        
        if (shouldFilter) {
            kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
            completionHandlerCopy(kitFilter, YES);
            return;
        }
    }
    
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
    
    __block NSString *auxString = [[NSString stringWithFormat:@"%@%@", eventTypeString, event.name] lowercaseString];
    hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([auxString cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                   encoding:NSUTF8StringEncoding];
    
    shouldFilter = nameFilters[hashValue] && [nameFilters[hashValue] isEqualToNumber:zero];
    if (shouldFilter) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:shouldFilter];
        completionHandlerCopy(kitFilter, YES);
        return;
    }
    
    // Attributes
    MPMessageType messageTypeCode = (MPMessageType)mParticle::MessageTypeName::messageTypeForName(string([messageType UTF8String]));
    if (messageTypeCode != MPMessageTypeEvent && messageTypeCode != MPMessageTypeScreenView) {
        messageTypeCode = MPMessageTypeUnknown;
    }
    
    MPEvent *forwardEvent = [event copy];
    
    if (event.info) {
        __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] initWithCapacity:forwardEvent.info.count];
        
        [forwardEvent.info enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            auxString = [NSString stringWithFormat:@"%@%@%@", eventTypeString, event.name, key];
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
        
        forwardEvent.info = filteredAttributes.count > 0 ? filteredAttributes : nil;
    }
    
    [self projectKit:kit
               event:forwardEvent
         messageType:messageTypeCode
   completionHandler:^(vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections) {
       __weak auto lastProjectedEvent = projectedEvents.back();
       NSArray<MPEventProjection *> *appliedProjectionsArray = !appliedProjections.empty() ? [NSArray arrayWithObjects:&appliedProjections[0] count:appliedProjections.size()] : nil;
       
       for (auto &projectedEvent : projectedEvents) {
           BOOL finished = projectedEvent == lastProjectedEvent;
           kitFilter = [[MPKitFilter alloc] initWithEvent:projectedEvent shouldFilter:shouldFilter appliedProjections:appliedProjectionsArray];
           completionHandlerCopy(kitFilter, finished);
       }
   }];
}

- (MPKitFilter *)filterKit:(MPKitAbstract *)kit forSelector:(SEL)selector {
    MPKitFilter *kitFilter = nil;
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    
    if (kitConfiguration) {
        NSString *selectorString = NSStringFromSelector(selector);
        NSString *messageType = [self methodMessageTypeMapping][selectorString];
        
        if (messageType) {
            BOOL shouldFilter = kitConfiguration.messageTypeFilters[messageType] && [kitConfiguration.messageTypeFilters[messageType] isEqualToNumber:@0];
            
            kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter] : nil;
        }
    }
    
    return kitFilter;
}

- (MPKitFilter *)filterKit:(MPKitAbstract *)kit forUserAttributes:(NSDictionary *)userAttributes {
    if (!userAttributes) {
        return nil;
    }
    
    MPKitFilter *kitFilter = nil;
    __block NSMutableDictionary *filteredAttributes = [[NSMutableDictionary alloc] initWithCapacity:userAttributes.count];
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    
    if (kitConfiguration) {
        [userAttributes enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
            NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                                     encoding:NSUTF8StringEncoding];
            
            BOOL shouldFilter = kitConfiguration.userAttributeFilters[hashValue] && [kitConfiguration.userAttributeFilters[hashValue] isEqualToNumber:@0];
            if (!shouldFilter) {
                filteredAttributes[key] = [value copy];
            }
        }];
    }
    
    if (filteredAttributes.count > 0) {
        kitFilter = [[MPKitFilter alloc] initWithFilter:YES filteredAttributes:filteredAttributes];
    }
    
    return kitFilter;
}

- (MPKitFilter *)filterKit:(MPKitAbstract *)kit forUserAttributeKey:(NSString *)key value:(id)value {
    if (!key) {
        return nil;
    }
    
    NSString *hashValue = [NSString stringWithCString:mParticle::Hasher::hashString([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]).c_str()
                                             encoding:NSUTF8StringEncoding];
    
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    
    MPKitFilter *kitFilter = nil;
    BOOL shouldFilter = NO;
    
    if (kitConfiguration) {
        shouldFilter = kitConfiguration.userAttributeFilters[hashValue] && [kitConfiguration.userAttributeFilters[hashValue] isEqualToNumber:@0];
        
        kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter] : nil;
    }
    
    return kitFilter;
}

- (MPKitFilter *)filterKit:(MPKitAbstract *)kit forUserIdentityKey:(NSString *)key identityType:(MPUserIdentity)identityType {
    NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)identityType];
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    
    MPKitFilter *kitFilter = nil;
    BOOL shouldFilter = NO;
    
    if (kitConfiguration) {
        shouldFilter = kitConfiguration.userIdentityFilters[identityTypeString] && [kitConfiguration.userIdentityFilters[identityTypeString] isEqualToNumber:@0];
        
        kitFilter = shouldFilter ? [[MPKitFilter alloc] initWithFilter:shouldFilter] : nil;
    }
    
    return kitFilter;
}

#pragma mark Projection methods
- (void)projectKit:(MPKitAbstract *)kit commerceEvent:(MPCommerceEvent *const)commerceEvent completionHandler:(void (^)(vector<MPCommerceEvent *> projectedCommerceEvents, vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > MPMessageTypeCommerceEvent) ||
        ![kitConfiguration.configuredMessageTypeProjections[MPMessageTypeCommerceEvent] boolValue])
    {
        vector<MPCommerceEvent *> projectedCommerceEvents;
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        
        projectedCommerceEvents.push_back(commerceEvent);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
        });
        
        return;
    }
    
    __weak MPKitContainer *weakSelf = self;
    
    // Projections are executed on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong MPKitContainer *strongSelf = weakSelf;
        dispatch_semaphore_wait(strongSelf->kitsSemaphore, DISPATCH_TIME_FOREVER);
        
        // Filter projections only to those of 'messageType'
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageType == %ld", (long)MPMessageTypeCommerceEvent];
        NSArray *projections = [kitConfiguration.projections filteredArrayUsingPredicate:predicate];
        
        // Priming projections
        vector<MPCommerceEvent *> projectedCommerceEvents;
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        __block vector<MPEventProjection *> applicableEventProjections;
        MPEventType typeOfCommerceEvent = [commerceEvent type];
        MPCommerceEventKind kindOfCommerceEvent = [commerceEvent kind];
        
        NSArray *const products = [&commerceEvent] {
            return [commerceEvent kind] == MPCommerceEventKindProduct ? commerceEvent.products : (NSArray *)nil;
        }();
        
        NSArray *const promotions = [&commerceEvent] {
            return [commerceEvent kind] == MPCommerceEventKindPromotion ? commerceEvent.promotionContainer.promotions : (NSArray *)nil;
        }();
        
        BOOL (^isApplicableEventProjection)(MPEventProjection *, NSDictionary *) = ^(MPEventProjection *eventProjection, NSDictionary *sourceDictionary) {
            __block BOOL isApplicable = NO;
            
            [sourceDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                NSString *keyHash = [NSString stringWithCString:mParticle::Hasher::hashString(to_string(typeOfCommerceEvent) + string([[key lowercaseString] UTF8String])).c_str()
                                                       encoding:NSUTF8StringEncoding];
                
                isApplicable = [eventProjection.attributeKey isEqualToString:keyHash] && [eventProjection.attributeValue isEqualToString:value];
                *stop = isApplicable;
            }];
            
            return isApplicable;
        };
        
        if (projections.count > 0) {
            // Identifying which projections are applicable
            for (MPEventProjection *eventProjection in projections) {
                if (eventProjection.eventType == typeOfCommerceEvent) {
                    if (!MPIsNull(eventProjection.attributeKey) && !MPIsNull(eventProjection.attributeValue)) {
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
                        string attributeToHash = to_string(typeOfCommerceEvent) + string([[key lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                        
                        int hashValue = mParticle::Hasher::hashFromString(attributeToHash);
                        hashKeyMap[hashValue] = key;
                    }
                    
                    key = hashKeyMap[[attributeProjection.name intValue]];
                    
                    if (!MPIsNull(key) && sourceDictionary[key]) {
                        value = [strongSelf transformValue:sourceDictionary[key] dataType:attributeProjection.dataType];
                        
                        if (!MPIsNull(value)) {
                            projectedDictionary[attributeProjection.projectedName] = value;
                        }
                    } else if (attributeProjection.required) {
                        return (NSDictionary *)[NSNull null];
                    }
                }
                    break;
                    
                case MPProjectionMatchTypeField:
                case MPProjectionMatchTypeString:
                    if (sourceDictionary[attributeProjection.name]) {
                        value = [strongSelf transformValue:sourceDictionary[attributeProjection.name] dataType:attributeProjection.dataType];
                        
                        if (!MPIsNull(value)) {
                            projectedDictionary[attributeProjection.projectedName] = value;
                        }
                    } else if (attributeProjection.required) {
                        return (NSDictionary *)[NSNull null];
                    }
                    break;
                    
                case MPProjectionMatchTypeStatic:
                    value = [strongSelf transformValue:attributeProjection.name dataType:attributeProjection.dataType];
                    
                    if (!MPIsNull(value)) {
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
                    projectedCommerceEvents.push_back(commerceEvent);
                }
            } // for (event projection)
        } // If (applying projections)
        
        // If no projection was applied, uses the original commerce event.
        if (projectedCommerceEvents.empty() && projectedEvents.empty()) {
            projectedCommerceEvents.push_back(commerceEvent);
        }
        
        dispatch_semaphore_signal(strongSelf->kitsSemaphore);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(projectedCommerceEvents, projectedEvents, appliedProjections);
        });
    });
}

- (void)projectKit:(MPKitAbstract *)kit event:(MPEvent *const)event messageType:(MPMessageType)messageType completionHandler:(void (^)(vector<MPEvent *> projectedEvents, vector<MPEventProjection *> appliedProjections))completionHandler {
    MPKitConfiguration *kitConfiguration = self.kitConfigurations[kit.kitCode];
    
    if (!kitConfiguration.configuredMessageTypeProjections ||
        !(kitConfiguration.configuredMessageTypeProjections.count > messageType) ||
        ![kitConfiguration.configuredMessageTypeProjections[messageType] boolValue])
    {
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        projectedEvents.push_back(event);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(projectedEvents, appliedProjections);
        });
        
        return;
    }
    
    __weak MPKitContainer *weakSelf = self;
    
    // Projections are executed on a background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong MPKitContainer *strongSelf = weakSelf;
        dispatch_semaphore_wait(strongSelf->kitsSemaphore, DISPATCH_TIME_FOREVER);
        
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
                            if ([key isEqualToString:attributeProjection.name]) {
                                projectedAttributeValue = [strongSelf transformValue:obj dataType:attributeProjection.dataType];
                                
                                if ((NSNull *)projectedAttributeValue != [NSNull null]) {
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
                                
                                if ((NSNull *)projectedAttributeValue != [NSNull null]) {
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
                            projectedAttributes[projectedAttributeKey] = [strongSelf transformValue:attributeProjection.name dataType:attributeProjection.dataType];
                            [projectedKeys addObject:projectedAttributeKey];
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
        
        // Filter projections only to those of 'messageType'
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"messageType == %ld", (long)messageType];
        NSArray *projections = [kitConfiguration.projections filteredArrayUsingPredicate:predicate];
        
        // Apply projections
        vector<MPEvent *> projectedEvents;
        vector<MPEventProjection *> appliedProjections;
        MPEvent *projectedEvent;
        MPEventProjection *defaultProjection = nil;
        NSDictionary *projectedAttributes;
        
        if (projections.count > 0) {
            int eventNameHash = 0;
            
            for (MPEventProjection *eventProjection in projections) {
                BOOL shouldProjectEvent = NO;
                
                switch (eventProjection.matchType) {
                    case MPProjectionMatchTypeString:
                        if ([event.name isEqualToString:eventProjection.name]) {
                            if (eventProjection.attributeKey && eventProjection.attributeValue) {
                                shouldProjectEvent = [event.info[eventProjection.attributeKey] isEqualToString:eventProjection.attributeValue];
                            } else {
                                shouldProjectEvent = YES;
                            }
                        }
                        break;
                        
                    case MPProjectionMatchTypeHash: {
                        if (eventNameHash == 0) {
                            string nameToHash = messageType == MPMessageTypeScreenView ? "0" : to_string(event.type);
                            nameToHash += string([[event.name lowercaseString] cStringUsingEncoding:NSUTF8StringEncoding]);
                            eventNameHash = mParticle::Hasher::hashFromString(nameToHash);
                        }
                        
                        if (eventNameHash == [eventProjection.name integerValue]) {
                            if (eventProjection.attributeKey && eventProjection.attributeValue) {
                                shouldProjectEvent = [event.info[eventProjection.attributeKey] isEqualToString:eventProjection.attributeValue];
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
                            if (eventProjection.attributeKey && eventProjection.attributeValue) {
                                if ([event.info[eventProjection.attributeKey] isEqualToString:eventProjection.attributeValue]) {
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
                projectedEvents.push_back(event);
            }
        }
        
        dispatch_semaphore_signal(strongSelf->kitsSemaphore);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            completionHandler(projectedEvents, appliedProjections);
        });
    });
}

#pragma mark Public methods
- (NSArray<__kindof MPKitAbstract *> *)activeKits {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"active == YES"];
    NSArray<__kindof MPKitAbstract *> *activeKits = [self.kits filteredArrayUsingPredicate:predicate];
    
    return activeKits;
}

- (void)configureKits:(NSArray<NSDictionary *> *)kitConfigurations {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    if (MPIsNull(kitConfigurations) || stateMachine.optOut) {
        [self flushSerializedKits];
        
        return;
    }
    
    dispatch_semaphore_wait(kitsSemaphore, DISPATCH_TIME_FOREVER);
    
    MPKitAbstract *kit;
    NSPredicate *predicate;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    NSString *kitPath;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userAttributes = userDefaults[kMPUserAttributeKey];
    NSArray *userIdentities = userDefaults[kMPUserIdentityArrayKey];
    NSArray<NSNumber *> *supportedKits = [self supportedKits];
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];

    // Adds all currently configured kits to a list
    vector<NSNumber *> removeKits;
    for (kit in activeKits) {
        removeKits.push_back(kit.kitCode);
    }
    
    // Configure kits according to server instructions
    for (NSDictionary *kitConfigurationDictionary in kitConfigurations) {
        MPKitConfiguration *kitConfiguration = nil;
        BOOL shouldPersistKit = YES;
        
        NSNumber *kitCode = kitConfigurationDictionary[@"id"];
        
        predicate = [NSPredicate predicateWithFormat:@"SELF == %@", kitCode];
        BOOL isKitSupported = [supportedKits filteredArrayUsingPredicate:predicate].count > 0;

        if (isKitSupported) {
            predicate = [NSPredicate predicateWithFormat:@"kitCode == %@", kitCode];
            kit = [[self.kits filteredArrayUsingPredicate:predicate] firstObject];
            
            if (kit) {
                NSData *kitConfigData = [NSJSONSerialization dataWithJSONObject:kitConfigurationDictionary options:0 error:nil];
                NSString *kitConfigString = [[NSString alloc] initWithData:kitConfigData encoding:NSUTF8StringEncoding];
                NSNumber *configurationHash = @(mParticle::Hasher::hashFromString([kitConfigString cStringUsingEncoding:NSUTF8StringEncoding]));
                
                kitConfiguration = self.kitConfigurations[kitCode];
                shouldPersistKit = !(kitConfiguration && [kitConfiguration.configurationHash isEqualToNumber:configurationHash]);
                if (shouldPersistKit) {
                    [kitConfiguration updateConfiguration:kitConfigurationDictionary];
                    kit.configuration = kitConfiguration.configuration;
                    [kit setBracketConfiguration:kitConfiguration.bracketConfiguration];
                }
            } else {
                kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:kitConfigurationDictionary];
                self.kitConfigurations[kitCode] = kitConfiguration;
                
                kit = [self startKit:kitCode configuration:kitConfiguration.configuration];
                
                if (kit) {
                    if (![kit started]) {
                        if ([kit respondsToSelector:@selector(setLaunchOptions:)]) {
                            [kit performSelector:@selector(setLaunchOptions:) withObject:stateMachine.launchOptions];
                        }
                        
                        if ([kit respondsToSelector:@selector(start)]) {
                            [kit start];
                        }
                    }
                    
                    [self emplaceKit:kit];
                }
                
                [kit setBracketConfiguration:kitConfiguration.bracketConfiguration];
            }
            
            if (kit) {
                if (userAttributes && [kit respondsToSelector:@selector(setUserAttribute:value:)]) {
                    NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
                    NSString *key;
                    id value;
                    Class NSStringClass = [NSString class];
                    
                    while ((key = [attributeEnumerator nextObject])) {
                        value = userAttributes[key];
                        value = [value isKindOfClass:NSStringClass] ? (NSString *)value : [value stringValue];
                        [kit setUserAttribute:key value:value];
                    }
                }
                
                if (userIdentities && [kit respondsToSelector:@selector(setUserIdentity:identityType:)]) {
                    for (NSDictionary *userIdentity in userIdentities) {
                        MPUserIdentity identityType = (MPUserIdentity)[userIdentity[kMPUserIdentityTypeKey] intValue];
                        NSString *identityString = userIdentity[kMPUserIdentityIdKey];
                        
                        [kit setUserIdentity:identityString identityType:identityType];
                    }
                }
            }
            
            if (shouldPersistKit) {
                if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
                    [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
                }
                
                kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.%@", kitCode, kitFileExtension]];
                
                if ([fileManager fileExistsAtPath:kitPath]) {
                    [fileManager removeItemAtPath:kitPath error:nil];
                }
                
                [NSKeyedArchiver archiveRootObject:kitConfiguration toFile:kitPath];
            }
        } else {
            MPLogWarning(@"SDK is trying to configure the %@ kit, however it is not currently configured in your Podfile.", [MPKitAbstract nameForKit:kitCode]);
        }
        
        if (!removeKits.empty()) {
            for (size_t i = 0; i < removeKits.size(); ++i) {
                if ([removeKits.at(i) isEqualToNumber:kitCode]) {
                    removeKits.erase(removeKits.begin() + i);
                    break;
                }
            }
        }
    }
    
    // Remove currently configured kits that were not in the instructions from the server
    if (!removeKits.empty()) {
        for (vector<NSNumber *>::iterator ekIterator = removeKits.begin(); ekIterator != removeKits.end(); ++ekIterator) {
            predicate = [NSPredicate predicateWithFormat:@"kitCode == %@", *ekIterator];
            kit = [[self.kits filteredArrayUsingPredicate:predicate] firstObject];
            kit.active = NO;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSDictionary *userInfo = @{mParticleKitInstanceKey:*ekIterator,
                                           mParticleEmbeddedSDKInstanceKey:*ekIterator};
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeInactiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeInactiveNotification
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
            
            kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"EmbeddedKit%@.%@", *ekIterator, kitFileExtension]];
            
            if ([fileManager fileExistsAtPath:kitPath]) {
                [fileManager removeItemAtPath:kitPath error:nil];
            }
            
            [self.kits removeObject:kit];
            kit = nil;
        }
    }
    
    dispatch_semaphore_signal(kitsSemaphore);
}

- (void)removeKitConfigurationAtPath:(nonnull NSString *)kitPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:kitPath]) {
        [fileManager removeItemAtPath:kitPath error:nil];
        [[NSUserDefaults standardUserDefaults] removeMPObjectForKey:kMPHTTPETagHeaderKey];
    }
}

- (void)removeAllKitConfigurations {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    
    if ([fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:stateMachineDirectoryPath error:nil];
        NSString *predicateFormat = [NSString stringWithFormat:@"pathExtension == '%@'", kitFileExtension];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat];
        directoryContents = [directoryContents filteredArrayUsingPredicate:predicate];
        
        if (directoryContents.count > 0) {
            [[NSUserDefaults standardUserDefaults] removeMPObjectForKey:kMPHTTPETagHeaderKey];
            
            for (NSString *fileName in directoryContents) {
                NSString *kitPath = [stateMachineDirectoryPath stringByAppendingPathComponent:fileName];
                [fileManager removeItemAtPath:kitPath error:nil];
            }
        }
    }
}

- (nonnull NSArray<NSNumber *> *)supportedKits {
    NSArray<NSNumber *> *supportedKits = @[
                                           @(MPKitInstanceForesee),
#if defined(MP_KIT_ADJUST)
                                           @(MPKitInstanceAdjust),
#endif
#if defined(MP_KIT_APPBOY)
                                           @(MPKitInstanceAppboy),
#endif
#if defined(MP_KIT_APPSFLYER)
                                           @(MPKitInstanceAppsFlyer),
#endif
#if defined(MP_KIT_BRANCHMETRICS)
                                           @(MPKitInstanceBranchMetrics),
#endif
#if defined(MP_KIT_CRITTERCISM)
                                           @(MPKitInstanceCrittercism),
#endif
#if defined(MP_KIT_COMSCORE)
                                           @(MPKitInstanceComScore),
#endif
#if defined(MP_KIT_FLURRY)
                                           @(MPKitInstanceFlurry),
#endif
#if defined(MP_KIT_KAHUNA)
                                           @(MPKitInstanceKahuna),
#endif
#if defined(MP_KIT_KOCHAVA)
                                           @(MPKitInstanceKochava),
#endif
#if defined(MP_KIT_LOCALYTICS)
                                           @(MPKitInstanceLocalytics),
#endif
#if defined(MP_KIT_WOOTRIC)
                                           @(MPKitInstanceWootric),
#endif
                                           ];
    
    return supportedKits;
}

#pragma mark Forward methods
- (void)forwardCommerceEventCall:(MPCommerceEvent *)commerceEvent kitHandler:(void (^)(MPKitAbstract *kit, MPKitFilter *kitFilter, MPKitExecStatus **execStatus))kitHandler {
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        __block NSNumber *lastKit = nil;
        
        [self filterKit:kit
               forCommerceEvent:commerceEvent
              completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
                  if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
                      return;
                  }
                  
                  if ((kitFilter.forwardCommerceEvent || kitFilter.forwardEvent) &&
                      ([kit canExecuteSelector:@selector(logCommerceEvent:)] || [kit canExecuteSelector:@selector(logEvent:)]))
                  {
                      MPKitExecStatus *execStatus = nil;
                      
                      kitHandler(kit, kitFilter, &execStatus);
                      
                      NSNumber *currentKit = kit.kitCode;
                      if (execStatus.success && ![lastKit isEqualToNumber:currentKit] && (kitFilter.forwardEvent || kitFilter.forwardCommerceEvent)) {
                          lastKit = currentKit;
                          
                          MPForwardRecord *forwardRecord = [[MPForwardRecord alloc] initWithMessageType:MPMessageTypeCommerceEvent
                                                                                             execStatus:execStatus
                                                                                         kitFilter:kitFilter
                                                                                          originalEvent:commerceEvent];
                          
                          [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                          
                          MPLogDebug(@"Forwarded logCommerceEvent call to kit: %@", [kit kitName]);
                      }
                  }
              }];
    }
}

- (void)forwardSDKCall:(SEL)selector event:(MPEvent *)event messageType:(MPMessageType)messageType userInfo:(NSDictionary *)userInfo kitHandler:(void (^)(MPKitAbstract *kit, MPEvent *forwardEvent, MPKitExecStatus **execStatus))kitHandler {
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        __block NSNumber *lastKit = nil;
        
        void (^forwardWithFilter)(MPKitFilter *const) = ^(MPKitFilter *const kitFilter) {
            if (kitFilter.shouldFilter && !kitFilter.filteredAttributes) {
                return;
            }
            
            if (kitFilter.forwardEvent && [kit canExecuteSelector:selector]) {
                MPKitExecStatus *execStatus = nil;
                
                kitHandler(kit, kitFilter.forwardEvent, &execStatus);
                
                NSNumber *currentKit = kit.kitCode;
                if (execStatus.success && ![lastKit isEqualToNumber:currentKit] && kitFilter.forwardEvent && messageType != MPMessageTypeUnknown) {
                    lastKit = currentKit;
                    
                    MPForwardRecord *forwardRecord = nil;
                    
                    if (messageType == MPMessageTypeOptOut || messageType == MPMessageTypePushRegistration) {
                        forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                                          execStatus:execStatus
                                                                           stateFlag:[userInfo[@"state"] boolValue]];
                    } else {
                        forwardRecord = [[MPForwardRecord alloc] initWithMessageType:messageType
                                                                          execStatus:execStatus
                                                                           kitFilter:kitFilter
                                                                       originalEvent:event];
                    }
                    
                    [[MPPersistenceController sharedInstance] saveForwardRecord:forwardRecord];
                    
                    MPLogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), [kit kitName]);
                }
            }
        };
        
        if ([kit respondsToSelector:selector]) {
            if (event) {
                [self filterKit:kit
                       forEvent:event
                       selector:selector
              completionHandler:^(MPKitFilter *kitFilter, BOOL finished) {
                  forwardWithFilter(kitFilter);
              }];
            } else {
                MPKitFilter *kitFilter = [self filterKit:kit forSelector:selector];
                forwardWithFilter(kitFilter);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributeKey:(NSString *)key value:(id)value kitHandler:(void (^)(MPKitAbstract *kit))kitHandler {
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filterKit:kit forUserAttributeKey:key value:value];
            
            if (!kitFilter.shouldFilter && [kit canExecuteSelector:selector]) {
                kitHandler(kit);
                
                MPLogDebug(@"Forwarded user attribute key: %@ value: %@ to kit: %@", key, value, [kit kitName]);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userAttributes:(NSDictionary *)userAttributes kitHandler:(void (^)(MPKitAbstract *kit, NSDictionary *forwardAttributes))kitHandler {
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filterKit:kit forUserAttributes:userAttributes];
            
            if ([kit canExecuteSelector:selector]) {
                kitHandler(kit, kitFilter.filteredAttributes);
                
                MPLogDebug(@"Forwarded user attributes to kit: %@", [kit kitName]);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector userIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType kitHandler:(void (^)(MPKitAbstract *kit))kitHandler {
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [self filterKit:kit forUserIdentityKey:identityString identityType:identityType];
            
            if (!kitFilter.shouldFilter && [kit canExecuteSelector:selector]) {
                kitHandler(kit);
                
                MPLogDebug(@"Forwarded setting user identity: %@ to kit: %@", identityString, [kit kitName]);
            }
        }
    }
}

- (void)forwardSDKCall:(SEL)selector errorMessage:(NSString *)errorMessage exception:(NSException *)exception eventInfo:(NSDictionary *)eventInfo kitHandler:(void (^)(MPKitAbstract *kit, MPKitExecStatus **execStatus))kitHandler {
    NSArray<__kindof MPKitAbstract *> *activeKits = [self activeKits];
    
    for (MPKitAbstract *kit in activeKits) {
        if ([kit respondsToSelector:selector]) {
            MPKitFilter *kitFilter = [[MPKitFilter alloc] initWithFilter:NO];
            
            if (!kitFilter.shouldFilter && [kit canExecuteSelector:selector]) {
                MPKitExecStatus *execStatus = nil;
                
                kitHandler(kit, &execStatus);
                
                MPLogDebug(@"Forwarded %@ call to kit: %@", NSStringFromSelector(selector), [kit kitName]);
            }
        }
    }
}

@end
