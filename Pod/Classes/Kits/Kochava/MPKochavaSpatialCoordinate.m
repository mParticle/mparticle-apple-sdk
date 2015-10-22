//
//  MPKochavaSpatialCoordinate.m
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

#if defined(MP_KIT_KOCHAVA)

#import "MPKochavaSpatialCoordinate.h"

NSString *const spatialX = @"SpatialX";
NSString *const spatialY = @"SpatialY";
NSString *const spatialZ = @"SpatialZ";

@implementation MPKochavaSpatialCoordinate

- (instancetype)initWithDictionary:(NSDictionary *)spatialDictionary {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    NSArray *keys = [spatialDictionary allKeys];
    BOOL containsSpatialCoordinate = [keys containsObject:spatialX] || [keys containsObject:spatialY] || [keys containsObject:spatialZ];
    if (!containsSpatialCoordinate) {
        return nil;
    }

    _x = [spatialDictionary[spatialX] floatValue];
    _y = [spatialDictionary[spatialY] floatValue];
    _z = [spatialDictionary[spatialZ] floatValue];
    
    return self;
}

@end

#endif
