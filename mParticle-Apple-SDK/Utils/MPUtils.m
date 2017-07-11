//
//  MPUtils.m
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

#import "MPUtils.h"
#import "mParticle.h"
#import "MPIUserDefaults.h"

@implementation MPUtils

+ (NSNumber *)mpId {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSString *mpIdString = userDefaults[@"mpid"];
    NSNumber *mpId = nil;
    if (mpIdString) {
        mpId = [NSNumber numberWithLongLong:(long long)[mpIdString longLongValue]];
    }
    else {
        mpId = @0; //TODO
    }
    
    return mpId;
}

+ (void)setMpid:(NSNumber *)mpId {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[@"mpid"] = mpId;
    [userDefaults synchronize];
}

@end
