//
//  MPNetworkPerformanceFactory.m
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

#import "MPNetworkPerformanceFactory.h"

static Class nPMClass = nil;
static id<MPExtensionNetworkPerformanceProtocol> networkPerformanceFactory = nil;

@implementation MPNetworkPerformanceFactory

@synthesize className = _className;

+ (nullable id<MPNetworkPerformanceMeasurementProtocol>)createNetworkPerformanceMeasurementWithURLRequest:(nonnull NSURLRequest *)request networkMeasurementMode:(MPNetworkMeasurementMode)networkMeasurementMode {
    id<MPNetworkPerformanceMeasurementProtocol> npmInstance = nil;
    if (networkPerformanceFactory) {
        npmInstance = [[nPMClass alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
    }

    return npmInstance;
}

+ (nullable Class)networkPerformanceMeasurementClass {
    return nPMClass;
}

+ (BOOL)registerExtension:(nonnull id<MPExtensionNetworkPerformanceProtocol>)extension {
    BOOL registered = NO;
    
    if ([extension conformsToProtocol:@protocol(MPExtensionNetworkPerformanceProtocol)]) {
        networkPerformanceFactory = extension;
        registered = YES;
    }
    
    return registered;
}

- (nonnull instancetype)initWithNPMClassName:(nonnull NSString *)className {
    self = [super init];
    if (self) {
        Class classToRegister = NSClassFromString(className);
        if ([classToRegister conformsToProtocol:@protocol(MPNetworkPerformanceMeasurementProtocol)]) {
            nPMClass = classToRegister;
            _className = className;
        }
    }
    
    return self;
}

@end
