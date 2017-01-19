//
//  MPAttributeValidator.m
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

#import "MPAttributeValidator.h"
#import "MPIConstants.h"
#import "MPILogger.h"

@implementation MPAttributeValidator

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value error:(out NSError *__autoreleasing *)error {
    return [MPAttributeValidator checkAttribute:attributesDictionary key:key value:value maxValueLength:LIMIT_ATTR_LENGTH error:error];
}

+ (BOOL)checkAttribute:(NSDictionary *)attributesDictionary key:(NSString *)key value:(id)value maxValueLength:(NSUInteger)maxValueLength error:(out NSError *__autoreleasing *)error {
    static NSString *attributeValidationErrorDomain = @"Attribute Validation";
    NSString *errorMessage = nil;
    Class NSStringClass = [NSString class];
    
    if (!value) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidValue userInfo:nil];
        }
        
        errorMessage = @"The 'value' parameter is invalid.";
    }
    
    if ([value isKindOfClass:NSStringClass]) {
        if ([value isEqualToString:@""]) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kEmptyValueAttribute userInfo:nil];
            }
            
            errorMessage = @"The 'value' parameter is an empty string.";
        }
        
        if (((NSString *)value).length > maxValueLength) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
            }
            
            errorMessage = [NSString stringWithFormat:@"The parameter: %@ is longer than the maximum allowed.", value];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *values = (NSArray *)value;
        if (values.count > MAX_USER_ATTR_LIST_SIZE) {
            if (error != NULL) {
                *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
            }
            
            errorMessage = @"The 'values' parameter contains more entries than the maximum allowed.";
        }
        
        if (!errorMessage) {
            for (id entryValue in values) {
                if (![entryValue isKindOfClass:NSStringClass]) {
                    if (error != NULL) {
                        *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidDataType userInfo:nil];
                    }
                    
                    errorMessage = [NSString stringWithFormat:@"All user attribute entries in the array must be of type string. Error entry: %@", entryValue];
                    
                    break;
                } else if (((NSString *)entryValue).length > maxValueLength) {
                    if (error != NULL) {
                        *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededAttributeMaximumLength userInfo:nil];
                    }
                    
                    errorMessage = [NSString stringWithFormat:@"The values entry: %@ is longer than the maximum allowed.", entryValue];
                    
                    break;
                }
            }
        }
    }
    
    if (attributesDictionary.count >= LIMIT_ATTR_COUNT) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededNumberOfAttributesLimit userInfo:nil];
        }
        
        errorMessage = @"There are more attributes than the maximum number allowed.";
    }
    
    if (MPIsNull(key)) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kInvalidValue userInfo:nil];
        }
        
        errorMessage = @"The 'key' parameter cannot be nil.";
    } else if (key.length > LIMIT_NAME) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:attributeValidationErrorDomain code:kExceededKeyMaximumLength userInfo:nil];
        }
        
        errorMessage = @"The 'key' parameter is longer than the maximum allowed length.";
    }
    
    if (errorMessage == nil) {
        return YES;
    } else {
        MPILogError(@"%@", errorMessage);
        return NO;
    }
}

@end

const NSTimeInterval kMPRemainingBackgroundTimeMinimumThreshold = 1000;
const NSInteger kInvalidValue = 101;
const NSInteger kEmptyValueAttribute = 102;
const NSInteger kExceededNumberOfAttributesLimit = 103;
const NSInteger kExceededAttributeMaximumLength = 104;
const NSInteger kExceededKeyMaximumLength = 105;
const NSInteger kInvalidDataType = 106;
