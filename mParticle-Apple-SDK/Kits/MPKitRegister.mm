//
//  MPKitRegister.mm
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

#import "MPKitRegister.h"
#import "MPStateMachine.h"
#import "MPConsumerInfo.h"
#include "MPBracket.h"

NSString *const MPKitBracketLowKey = @"lo";
NSString *const MPKitBracketHighKey = @"hi";

@interface MPKitRegister() {
    shared_ptr<mParticle::Bracket> bracket;
}

@end


@implementation MPKitRegister

- (instancetype)init {
    id invalidVar = nil;
    self = [self initWithCode:invalidVar name:invalidVar className:invalidVar startImmediately:NO];
    return nil;
}

- (nullable instancetype)initWithCode:(nonnull NSNumber *)code name:(nonnull NSString *)name className:(nonnull NSString *)className startImmediately:(BOOL)startImmediately {
    NSAssert(code != nil, @"Required parameter. It cannot be nil.");
    NSAssert(name != nil, @"Required parameter. It cannot be nil.");
    NSAssert(className != nil, @"Required parameter. It cannot be nil.");
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _code = code;
    _name = name;
    _className = className;
    _startImmediately = startImmediately;
    
    _wrapperInstance = nil;
    bracket = nullptr;

    return self;
}

- (nullable instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration {
    NSAssert(configuration != nil, @"Required parameter. It cannot be nil.");
    
    BOOL startImmediately = configuration[@"start_immediately"] ? [configuration[@"start_immediately"] boolValue] : YES;
    self = [self initWithCode:configuration[@"code"] name:configuration[@"name"] className:configuration[@"className"] startImmediately:startImmediately];
    
    return self;
}

- (BOOL)active {
    BOOL active = _wrapperInstance ? [_wrapperInstance active] : NO;
    
    if (active && bracket != nullptr) {
        return bracket->shouldForward();
    } else {
        return active;
    }
}

- (void)freeWrapperInstance {
    if ([_wrapperInstance respondsToSelector:@selector(deinit)]) {
        [_wrapperInstance deinit];
    }
    
    [self willChangeValueForKey:@"instance"];
    _wrapperInstance = nil;
    [self didChangeValueForKey:@"instance"];
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

@end
