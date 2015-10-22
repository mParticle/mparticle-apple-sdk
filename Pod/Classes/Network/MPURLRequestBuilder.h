//
//  MPURLRequestBuilder.h
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

@interface MPURLRequestBuilder : NSObject

@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSData *postData;
@property (nonatomic, strong) NSURL *url;

+ (MPURLRequestBuilder *)newBuilderWithURL:(NSURL *)url;
+ (MPURLRequestBuilder *)newBuilderWithURL:(NSURL *)url message:(NSString *)message httpMethod:(NSString *)httpMethod;
+ (NSTimeInterval)requestTimeout;
- (instancetype)initWithURL:(NSURL *)url __attribute__((objc_designated_initializer));
- (MPURLRequestBuilder *)withHeaderData:(NSData *)headerData;
- (MPURLRequestBuilder *)withHttpMethod:(NSString *)httpMethod;
- (MPURLRequestBuilder *)withPostData:(NSData *)postData;
- (NSMutableURLRequest *)build;

@end
