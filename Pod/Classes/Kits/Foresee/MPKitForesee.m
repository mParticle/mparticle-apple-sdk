//
//  MPKitForesee.m
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

#import "MPKitForesee.h"
#import "MPDateFormatter.h"

NSString *const kMPForeseeBaseURLKey = @"rootUrl";
NSString *const kMPForeseeClientIdKey = @"clientId";
NSString *const kMPForeseeSurveyIdKey = @"surveyId";
NSString *const kMPForeseeSendAppVersionKey = @"sendAppVersion";

@interface MPKitForesee() {
    NSString *baseURL;
    NSString *clientId;
    NSString *surveyId;
    BOOL sendAppVersion;
}

@end

@implementation MPKitForesee

- (void)setConfiguration:(NSDictionary *)configuration {
    if (!started || ![self isValidConfiguration:configuration]) {
        return;
    }
    
    [super setConfiguration:configuration];
    [self setupWithConfiguration:configuration];
}

#pragma mark Private methods
- (BOOL)isValidConfiguration:(NSDictionary *)configuration {
    BOOL validConfiguration = configuration[kMPForeseeClientIdKey] && configuration[kMPForeseeSurveyIdKey];
    
    return validConfiguration;
}

- (void)setupWithConfiguration:(NSDictionary *)configuration {
    baseURL = configuration[kMPForeseeBaseURLKey] ? configuration[kMPForeseeBaseURLKey] : @"http://survey.foreseeresults.com/survey/display";
    clientId = configuration[kMPForeseeClientIdKey];
    surveyId = configuration[kMPForeseeSurveyIdKey];
    sendAppVersion = [[configuration[kMPForeseeSendAppVersionKey] lowercaseString] isEqualToString:@"true"];
}

#pragma mark MPKitInstanceProtocol methods
- (instancetype)initWithConfiguration:(NSDictionary *)configuration {
    self = [super initWithConfiguration:configuration];
    if (!self || ![self isValidConfiguration:configuration]) {
        return nil;
    }
    
    frameworkAvailable = YES;
    started = YES;
    self.forwardedEvents = YES;
    self.active = YES;

    [self setupWithConfiguration:configuration];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:@(MPKitInstanceForesee),
                                   mParticleEmbeddedSDKInstanceKey:@(MPKitInstanceForesee)};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleEmbeddedSDKDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });

    return self;
}

- (NSString *)surveyURLWithUserAttributes:(NSDictionary *)userAttributes {
    NSString * (^encodeString)(NSString *) = ^ (NSString *originalString) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        NSString *encodedString = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                                        (__bridge CFStringRef)originalString,
                                                                                                        NULL,
                                                                                                        (__bridge CFStringRef)@";/?@&+{}<>,=",
                                                                                                        kCFStringEncodingUTF8);
#pragma clang diagnostic pop
        
        return encodedString;
    };

    NSMutableString *surveyURL = [[NSMutableString alloc] initWithString:baseURL];
    
    // Client, Survey, and Respondent Ids
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    NSString *respondentId = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    CFRelease(UUIDRef);

    [surveyURL appendFormat:@"?cid=%@&sid=%@&rid=%@", encodeString(clientId), encodeString(surveyId), respondentId];
    
    BOOL cppsIncluded = NO;
    
    // App Version
    if (sendAppVersion) {
        NSDictionary *bundleInfoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = bundleInfoDictionary[@"CFBundleShortVersionString"];
        
        if (appVersion) {
            [surveyURL appendFormat:@"&cpps=cpp%@app_version%@%@%@", encodeString(@"["), encodeString(@"]"), encodeString(@"="), appVersion];
            cppsIncluded = YES;
        }
    }
    
    // User attributes
    if (userAttributes) {
        NSEnumerator *attributeEnumerator = [userAttributes keyEnumerator];
        NSString *key;
        id value;
        Class NSDateClass = [NSDate class];
        Class NSStringClass = [NSString class];
        
        while ((key = [attributeEnumerator nextObject])) {
            value = userAttributes[key];
            
            if ([value isKindOfClass:NSDateClass]) {
                value = [MPDateFormatter stringFromDateRFC3339:value];
            } else if (![value isKindOfClass:NSStringClass]) {
                value = [value stringValue];
            }
            
            if (cppsIncluded) {
                [surveyURL appendString:@"&"];
            } else {
                [surveyURL appendString:@"&cpps="];
                cppsIncluded = YES;
            }
            
            [surveyURL appendFormat:@"cpp%@%@%@%@%@", encodeString(@"["), encodeString(key), encodeString(@"]"), encodeString(@"="), encodeString(value)];
        }
    }
    
    return surveyURL;
}

@end
