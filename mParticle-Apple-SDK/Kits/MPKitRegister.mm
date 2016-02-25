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

    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"%@ : {\n", [self class]];
    [description appendFormat:@"    code: %@,\n", _code];
    [description appendFormat:@"    name: %@,\n", _name];
    [description appendString:@"}"];
    
    return description;
}

@end
