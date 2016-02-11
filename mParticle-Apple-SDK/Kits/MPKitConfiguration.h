//
//  MPKitConfiguration.h
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

#import <Foundation/Foundation.h>

@class MPEventProjection;

@interface MPKitConfiguration : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong, readonly, nonnull) NSNumber *configurationHash;
@property (nonatomic, strong, nonnull) NSDictionary *configuration;
@property (nonatomic, strong, nullable) NSDictionary *filters;
@property (nonatomic, strong, readonly, nullable) NSDictionary *bracketConfiguration;
@property (nonatomic, strong, readonly, nullable) NSArray<NSNumber *> *configuredMessageTypeProjections;
@property (nonatomic, strong, readonly, nullable) NSArray<MPEventProjection *> *defaultProjections;
@property (nonatomic, strong, readonly, nullable) NSArray<MPEventProjection *> *projections;
@property (nonatomic, strong, readonly, nullable) NSNumber *kitCode;

@property (nonatomic, assign) BOOL attributeValueFilteringIsActive;
@property (nonatomic, assign) BOOL attributeValueFilteringShouldIncludeMatches;
@property (nonatomic, strong, nullable) NSString *attributeValueFilteringHashedAttribute;
@property (nonatomic, strong, nullable) NSString *attributeValueFilteringHashedValue;

@property (nonatomic, weak, readonly) NSDictionary *eventTypeFilters;
@property (nonatomic, weak, readonly) NSDictionary *eventNameFilters;
@property (nonatomic, weak, readonly) NSDictionary *eventAttributeFilters;
@property (nonatomic, weak, readonly) NSDictionary *messageTypeFilters;
@property (nonatomic, weak, readonly) NSDictionary *screenNameFilters;
@property (nonatomic, weak, readonly) NSDictionary *screenAttributeFilters;
@property (nonatomic, weak, readonly) NSDictionary *userIdentityFilters;
@property (nonatomic, weak, readonly) NSDictionary *userAttributeFilters;
@property (nonatomic, weak, readonly) NSDictionary *commerceEventAttributeFilters;
@property (nonatomic, weak, readonly) NSDictionary *commerceEventEntityTypeFilters;
@property (nonatomic, weak, readonly) NSDictionary *commerceEventAppFamilyAttributeFilters;

- (nonnull instancetype)initWithDictionary:(nonnull NSDictionary *)configurationDictionary;
- (void)updateConfiguration:(nonnull NSDictionary *)configurationDictionary;

@end
