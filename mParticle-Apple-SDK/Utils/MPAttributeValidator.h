//
//  MPAttributeValidator.h
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

#import <Foundation/Foundation.h>

extern const NSTimeInterval kMPRemainingBackgroundTimeMinimumThreshold;
extern const NSInteger kInvalidValue;
extern const NSInteger kEmptyValueAttribute;
extern const NSInteger kExceededNumberOfAttributesLimit;
extern const NSInteger kExceededAttributeMaximumLength;
extern const NSInteger kExceededKeyMaximumLength;
extern const NSInteger kInvalidDataType;


@interface MPAttributeValidator : NSObject

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error;
+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error;

@end
