//
//  MPStandaloneCommand.h
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

#import "MPDataModelAbstract.h"

@interface MPStandaloneCommand : MPDataModelAbstract <NSCopying, NSCoding>

@property (nonatomic, strong, nonnull) NSURL *url;
@property (nonatomic, strong, nonnull) NSString *httpMethod;
@property (nonatomic, strong, nullable) NSData *headerData;
@property (nonatomic, strong, nullable) NSData *postData;
@property (nonatomic, unsafe_unretained) NSTimeInterval timestamp;
@property (nonatomic, unsafe_unretained) int64_t commandId;

- (nonnull instancetype)initWithCommandDictionary:(nonnull NSDictionary *)commandDictionary;
- (nonnull instancetype)initWithCommandId:(int64_t)commandId UUID:(nonnull NSString *)uuid url:(nonnull NSURL *)url httpMethod:(nonnull NSString *)httpMethod headerData:(nullable NSData *)headerData postData:(nullable NSData *)postData timestamp:(NSTimeInterval)timestamp;

@end
