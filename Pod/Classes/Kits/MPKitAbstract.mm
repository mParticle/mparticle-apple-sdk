//
//  MPKitAbstract.mm
//
//  Copyright 2015 mParticle, Inc.
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

#import "MPKitAbstract.h"
#import "MPDateFormatter.h"
#include "MPBracket.h"
#import "MPStateMachine.h"
#import "MPConsumerInfo.h"
#import "NSUserDefaults+mParticle.h"

NSString *const MPKitBracketLowKey = @"lo";
NSString *const MPKitBracketHighKey = @"hi";

@interface MPKitAbstract() {
    shared_ptr<mParticle::Bracket> bracket;
}

@end


@implementation MPKitAbstract

@synthesize userAttributes = _userAttributes;
@synthesize userIdentities = _userIdentities;

- (instancetype)initWithConfiguration:(NSDictionary *)configuration startImmediately:(BOOL)startImmediately {
    self = [super init];
    if (!self || !configuration) {
        return nil;
    }
    
    frameworkAvailable = NO;
    started = NO;
    kitDebugMode = NO;
    _forwardedEvents = NO;
    bracket = nullptr;
    _configuration = configuration;
    
    return self;
}

- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    return [self initWithConfiguration:configuration startImmediately:YES];
}

#pragma mark MPKitAbstract methods
- (BOOL)canExecuteSelector:(SEL)selector {
    static NSString *const startSelectorString = @"startWithDictionary:";
    
    if (!frameworkAvailable) {
        _forwardedEvents = NO;
        return NO;
    }
    
    if (!started) {
        _forwardedEvents = YES;
        NSString *selectorString = NSStringFromSelector(selector);
        return [selectorString isEqual:startSelectorString];
    }
    
    _forwardedEvents = YES;
    
    if (bracket != nullptr) {
        return bracket->shouldForward();
    }
    
    return YES;
}

- (BOOL)frameworkAvailable {
    return frameworkAvailable;
}

- (BOOL)started {
    if (started && bracket != nullptr) {
        return started && bracket->shouldForward();
    } else {
        return started;
    }
}

- (void)setBracketConfiguration:(NSDictionary *)bracketConfiguration {
    if (!bracketConfiguration) {
        if (bracket != nullptr) {
            bracket = nullptr;
        }
        
        return;
    }
    
    long mpId = [[MPStateMachine sharedInstance].consumerInfo.mpId longValue];
    short low = (short)[bracketConfiguration[MPKitBracketLowKey] integerValue];
    short high = (short)[bracketConfiguration[MPKitBracketHighKey] integerValue];
    
    if (bracket != nullptr) {
        bracket->mpId = mpId;
        bracket->low = low;
        bracket->high = high;
    } else {
        bracket = make_shared<mParticle::Bracket>(mpId, low, high);
    }
}

#pragma mark Public accessors
- (NSDictionary *)userAttributes {
    if (_userAttributes) {
        return _userAttributes;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _userAttributes = userDefaults[kMPUserAttributeKey];

    return _userAttributes;
}

- (NSArray *)userIdentities {
    if (_userIdentities) {
        return _userIdentities;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _userIdentities = userDefaults[kMPUserIdentityArrayKey];

    return _userIdentities;
}

#pragma mark Public methods
+ (nullable NSString *)nameForKit:(nonnull NSNumber *)kitCode {
    NSString *kitName = nil;
    
    switch ((MPKitInstance)[kitCode integerValue]) {
        case MPKitInstanceAppboy:
            kitName = @"Appboy";
            break;
            
        case MPKitInstanceKochava:
            kitName = @"Kochava";
            break;
            
        case MPKitInstanceKahuna:
            kitName = @"Kahuna";
            break;
            
        case MPKitInstanceComScore:
            kitName = @"comScore";
            break;
            
        case MPKitInstanceForesee:
            kitName = @"Foresee";
            break;
            
        case MPKitInstanceAdjust:
            kitName = @"Adjust";
            break;
            
        case MPKitInstanceBranchMetrics:
            kitName = @"Branch Metrics";
            break;
            
        case MPKitInstanceFlurry:
            kitName = @"Flurry";
            break;
            
        case MPKitInstanceLocalytics:
            kitName = @"Localytics";
            break;
            
        case MPKitInstanceCrittercism:
            kitName = @"Crittercism";
            break;

        case MPKitInstanceWootric:
            kitName = @"Wootric";
            break;
            
        case MPKitInstanceAppsFlyer:
            kitName = @"AppsFlyer";
            break;
            
        case MPKitInstanceTune:
            kitName = @"Tune";
            break;
    }
    
    return kitName;
}

- (id const)kitInstance {
    return nil;
}

- (NSString *)kitName {
    NSString *kitName = [MPKitAbstract nameForKit:_kitCode];
    return kitName;
}

- (NSDictionary *)parsedEventInfo:(NSDictionary *)eventInfo {
    if (!eventInfo || eventInfo.count == 0) {
        return nil;
    }
    
    NSMutableDictionary *messageDictionary = [[NSMutableDictionary alloc] initWithCapacity:eventInfo.count];
    NSEnumerator *eventEnumerator = [eventInfo keyEnumerator];
    NSString *key;
    NSString *value;
    
    while ((key = [eventEnumerator nextObject])) {
        value = [self stringRepresentation:eventInfo[key]];
        
        if (value) {
            messageDictionary[key] = value;
        }
    }
    
    return [messageDictionary copy];
}

- (NSString *)stringRepresentation:(id)value {
    NSString *stringRepresentation = nil;
    
    if ([value isKindOfClass:[NSString class]]) {
        stringRepresentation = value;
    } else if ([value isKindOfClass:[NSNumber class]]) {
        stringRepresentation = [(NSNumber *)value stringValue];
    } else if ([value isKindOfClass:[NSDate class]]) {
        stringRepresentation = [MPDateFormatter stringFromDateRFC3339:value];
    } else if ([value isKindOfClass:[NSData class]]) {
        stringRepresentation = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
        
    return stringRepresentation;
}

@end
