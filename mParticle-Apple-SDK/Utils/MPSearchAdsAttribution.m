//
//  MPSearchAdsAttribution.m
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

#import "MPSearchAdsAttribution.h"
#if TARGET_OS_IOS == 1
    #import <iAd/ADClient.h>
#endif

@interface MPSearchAdsAttribution ()

@property (nonatomic) NSDictionary *dictionary;

@end

@implementation MPSearchAdsAttribution

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dictionary = nil;
    }
    return self;
}

- (void)requestAttributionDetailsWithBlock:(void (^ _Nonnull)(void))completionHandler {
#if TARGET_OS_IOS == 1 && __IPHONE_OS_VERSION_MAX_ALLOWED > __IPHONE_9_3
    Class MPClientClass = NSClassFromString(@"ADClient");
    if (!MPClientClass) {
        return;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL sharedClientSelector = NSSelectorFromString(@"sharedClient");
    if (![MPClientClass respondsToSelector:sharedClientSelector]) {
        return;
    }
    
    id MPClientSharedInstance = [MPClientClass performSelector:sharedClientSelector];
    if (!MPClientSharedInstance) {
        return;
    }
    
    SEL requestDetailsSelector = NSSelectorFromString(@"requestAttributionDetailsWithBlock:");
    if (![MPClientSharedInstance respondsToSelector:requestDetailsSelector]) {
        return;
    }
    
    __block BOOL called = NO;
    void(^onceCompletionBlock)(void) = ^(){
        if (!called) {
            called = YES;
            completionHandler();
        }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        onceCompletionBlock();
    });
    
    __weak MPSearchAdsAttribution *weakSelf = self;
    int numRequests = 4;
    __block int numRequestsCompleted = 0;
    
    void (^requestBlock)(void) = ^{
        if (!called) {
            [MPClientSharedInstance performSelector:requestDetailsSelector withObject:^(NSDictionary *attributionDetails, NSError *error) {
                ++numRequestsCompleted;
                
                __strong MPSearchAdsAttribution *strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }

                if (attributionDetails && !error) {
                    strongSelf.dictionary = attributionDetails;
                    onceCompletionBlock();
                }
                else if (error.code == 1 /* ADClientErrorLimitAdTracking */) {
                    onceCompletionBlock();
                }
                else if (numRequestsCompleted >= numRequests) {
                    onceCompletionBlock();
                }
            }];
        }
    };
    
    // Per Apple docs, "Handle any errors you receive and re-poll for data, if required"
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(9 * NSEC_PER_SEC)), dispatch_get_main_queue(), requestBlock);
    
#pragma clang diagnostic pop
#else
    completionHandler();
#endif
}

- (nullable NSDictionary *)dictionaryRepresentation {
    return self.dictionary;
}

@end
