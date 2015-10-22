//
//  MPConsumerInfo.h
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

#import <Foundation/Foundation.h>

#pragma mark - MPCookie

extern NSString *const kMPCKContent;
extern NSString *const kMPCKDomain;
extern NSString *const kMPCKExpiration;

@interface MPCookie : NSObject <NSCoding>

@property (nonatomic, unsafe_unretained) int64_t cookieId;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *domain;
@property (nonatomic, strong) NSString *expiration;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, unsafe_unretained, readonly) BOOL expired;

- (instancetype)initWithName:(NSString *)name configuration:(NSDictionary *)configuration;
- (NSDictionary *)dictionaryRepresentation;

@end


#pragma mark - MPConsumerInfo
@interface MPConsumerInfo : NSObject <NSCoding>

@property (nonatomic, unsafe_unretained) int64_t consumerInfoId;
@property (nonatomic, strong) NSArray *cookies;
@property (nonatomic, strong) NSNumber *mpId;
@property (nonatomic, strong) NSString *uniqueIdentifier;

- (NSDictionary *)cookiesDictionaryRepresentation;
- (void)updateWithConfiguration:(NSDictionary *)configuration;

@end
