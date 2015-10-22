//
//  MPKitFilter.h
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

@class MPCommerceEvent;
@class MPEvent;

@interface MPKitFilter : NSObject

@property (nonatomic, strong, readonly) NSArray *appliedProjections;
@property (nonatomic, strong, readonly) NSDictionary *filteredAttributes;
@property (nonatomic, strong, readonly) MPCommerceEvent *forwardCommerceEvent;
@property (nonatomic, strong, readonly) MPEvent *forwardEvent;
@property (nonatomic, readonly) BOOL shouldFilter;

- (instancetype)initWithFilter:(BOOL)shouldFilter;
- (instancetype)initWithFilter:(BOOL)shouldFilter filteredAttributes:(NSDictionary *)filteredAttributes;
- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter;
- (instancetype)initWithEvent:(MPEvent *)event shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray *)appliedProjections;
- (instancetype)initWithCommerceEvent:(MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter;
- (instancetype)initWithCommerceEvent:(MPCommerceEvent *)commerceEvent shouldFilter:(BOOL)shouldFilter appliedProjections:(NSArray *)appliedProjections;

@end
