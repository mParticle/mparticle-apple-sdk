//
//  MPNetworkCommunication.m
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

#import "MPNetworkCommunication.h"
#import "MPApplication.h"
#import "MParticleReachability.h"
#import "MPConnector.h"
#import "MPConsumerInfo.h"
#import "MPDateFormatter.h"
#import "MPDevice.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPMessage.h"
#import "MPPersistenceController.h"
#import "MPSession.h"
#import "MPSessionHistory.h"
#import "MPStateMachine.h"
#import "MPUpload.h"
#import "MPSegment.h"
#import "MPURLRequestBuilder.h"
#import "MPZip.h"
#import "NSUserDefaults+mParticle.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, MPNetworkUploadType) {
    MPNetworkUploadTypeBatch = 0,
    MPNetworkUploadTypeSessionHistory
};

NSString *const urlFormat = @"%@://%@%@/%@%@"; // Scheme, URL Host, API Version, API key, path
NSString *const kMPConfigVersion = @"/v4";
NSString *const kMPConfigURL = @"/config";
NSString *const kMPEventsVersion = @"/v1";
NSString *const kMPEventsURL = @"/events";
NSString *const kMPSegmentVersion = @"/v1";
NSString *const kMPSegmentURL = @"/audience";

NSString *const kMPURLScheme = @"https";
NSString *const kMPURLHost = @"nativesdks.mparticle.com";
NSString *const kMPURLHostConfig = @"config2.mparticle.com";

@interface MPNetworkCommunication() {
    UIBackgroundTaskIdentifier backgroundTaskIdentifier;
    BOOL retrievingConfig;
    BOOL retrievingSegments;
    BOOL uploading;
}

@property (nonatomic, strong, readonly) NSURL *segmentURL;
@property (nonatomic, strong, readonly) NSURL *configURL;
@property (nonatomic, strong, readonly) NSURL *eventURL;

@end

@implementation MPNetworkCommunication

@synthesize configURL = _configURL;
@synthesize eventURL = _eventURL;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        retrievingConfig = NO;
        retrievingSegments = NO;
        uploading = NO;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter addObserver:self
                               selector:@selector(handleReachabilityChanged:)
                                   name:MParticleReachabilityChangedNotification
                                 object:nil];
    }
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:MParticleReachabilityChangedNotification object:nil];
    
    [self endBackgroundTask];
}

#pragma mark Private accessors
- (NSURL *)configURL {
    if (_configURL) {
        return _configURL;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    MPApplication *application = [[MPApplication alloc] init];
    NSString *configURLFormat = [urlFormat stringByAppendingString:@"?av=%@&sv=%@"];
    NSString *urlString = [NSString stringWithFormat:configURLFormat, kMPURLScheme, kMPURLHostConfig, kMPConfigVersion, stateMachine.apiKey, kMPConfigURL, application.version, kMParticleSDKVersion];
    _configURL = [NSURL URLWithString:urlString];
    
    return _configURL;
}

- (NSURL *)eventURL {
    if (_eventURL) {
        return _eventURL;
    }
    
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    NSString *urlString = [NSString stringWithFormat:urlFormat, kMPURLScheme, kMPURLHost, kMPEventsVersion, stateMachine.apiKey, kMPEventsURL];
    _eventURL = [NSURL URLWithString:urlString];
    
    return _eventURL;
}

- (NSURL *)segmentURL {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
    
    NSString *segmentURLFormat = [urlFormat stringByAppendingString:@"?mpID=%@"];
    NSString *urlString = [NSString stringWithFormat:segmentURLFormat, kMPURLScheme, kMPURLHost, kMPSegmentVersion, stateMachine.apiKey, kMPSegmentURL, stateMachine.consumerInfo.mpId];
    
    NSURL *segmentURL = [NSURL URLWithString:urlString];
    
    return segmentURL;
}

#pragma mark Private methods
- (void)beginBackgroundTask {
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        return;
    }
    
    __weak MPNetworkCommunication *weakSelf = self;
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }

            strongSelf->retrievingConfig = NO;
            strongSelf->retrievingSegments = NO;
            strongSelf->uploading = NO;
            [[UIApplication sharedApplication] endBackgroundTask:strongSelf->backgroundTaskIdentifier];
            strongSelf->backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
}

- (void)endBackgroundTask {
    if (backgroundTaskIdentifier == UIBackgroundTaskInvalid) {
        return;
    }
    
    [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    backgroundTaskIdentifier = UIBackgroundTaskInvalid;
}

- (void)uploadData:(NSData *)data batchId:(NSString *)batchId uploadType:(MPNetworkUploadType)uploadType completionHandler:(void(^ _Nonnull)(BOOL success, NSDictionary *responseDictionary, MPNetworkResponseAction responseAction, NSHTTPURLResponse *httpResponse))completionHandler {
    if (uploading) {
        return;
    }
    
    if (!data || data.length == 0) {
        completionHandler(NO, nil, MPNetworkResponseActionNone, nil);
    }
    
    uploading = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    
    [self beginBackgroundTask];
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    MPConnector *connector = [[MPConnector alloc] initWithConnectionId:connectionId];
    
    MPILogVerbose(@"Source Batch Id: %@", batchId);
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSData *zipUploadData = nil;
    std::tuple<unsigned char *, unsigned int> zipData = mParticle::Zip::compress((const unsigned char *)[data bytes], (unsigned int)[data length]);
    if (get<0>(zipData) != nullptr) {
        zipUploadData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        completionHandler(NO, nil, MPNetworkResponseActionDeleteBatch, nil);
        uploading = NO;
        return;
    }
    
    NSString *uploadTypeString = uploadType == MPNetworkUploadTypeBatch ? @"Upload" : @"Session History";
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:jsonString
                   serializedParams:zipUploadData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      
                      if (!strongSelf) {
                          completionHandler(NO, nil, MPNetworkResponseActionNone, nil);
                          return;
                      }
                      
                      [strongSelf endBackgroundTask];
                      
                      NSDictionary *responseDictionary = nil;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      NSInteger responseCode = [httpResponse statusCode];
                      BOOL success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                      
                      if (success) {
                          @try {
                              NSError *serializationError = nil;
                              responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                              success = serializationError == nil && [responseDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeResponseHeader];
                              MPILogVerbose(@"%@ Batch: %@\n", uploadTypeString, jsonString);
                              MPILogVerbose(@"%@ Batch Response Code: %ld", uploadTypeString, (long)responseCode);
                          } @catch (NSException *exception) {
                              responseDictionary = nil;
                              success = NO;
                              MPILogError(@"%@ Error: %@", uploadTypeString, [exception reason]);
                          }
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPILogWarning(@"%@ Error - Response Code: %ld", uploadTypeString, (long)responseCode);
                      }
                      
                      MPILogVerbose(@"%@ Batch Execution Time: %.2fms", uploadTypeString, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                      
                      completionHandler(success, responseDictionary, responseAction, httpResponse);
                      
                      strongSelf->uploading = NO;
                  }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPILogWarning(@"Failed Uploading Source Batch Id: %@", batchId);
            completionHandler(NO, nil, MPNetworkResponseActionNone, nil);
        }
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf->uploading = NO;
        }
        
        [connector cancelRequest];
    });
}

- (void)processNetworkResponseAction:(MPNetworkResponseAction)responseAction uploadInstance:(MPUpload *)upload httpResponse:(NSHTTPURLResponse *)httpResponse {
    switch (responseAction) {
        case MPNetworkResponseActionDeleteBatch:
            if (upload) {
                [[MPPersistenceController sharedInstance] deleteUpload:upload];
            }
            
            break;
            
        case MPNetworkResponseActionThrottle: {
            NSDate *now = [NSDate date];
            NSDictionary *httpHeaders = [httpResponse allHeaderFields];
            NSTimeInterval retryAfter = 7200; // Default of 2 hours
            NSTimeInterval maxRetryAfter = 86400; // Maximum of 24 hours
            id suggestedRetryAfter = httpHeaders[@"Retry-After"];
            
            if (!MPIsNull(suggestedRetryAfter)) {
                if ([suggestedRetryAfter isKindOfClass:[NSString class]]) {
                    if ([suggestedRetryAfter containsString:@":"]) { // Date
                        NSDate *retryAfterDate = [MPDateFormatter dateFromStringRFC1123:(NSString *)suggestedRetryAfter];
                        if (retryAfterDate) {
                            retryAfter = MIN(([retryAfterDate timeIntervalSince1970] - [now timeIntervalSince1970]), maxRetryAfter);
                            retryAfter = retryAfter > 0 ? retryAfter : 7200;
                        } else {
                            MPILogError(@"Invalid 'Retry-After' date: %@", suggestedRetryAfter);
                        }
                    } else { // Number of seconds
                        @try {
                            retryAfter = MIN([(NSString *)suggestedRetryAfter doubleValue], maxRetryAfter);
                        } @catch (NSException *exception) {
                            retryAfter = 7200;
                            MPILogError(@"Invalid 'Retry-After' value: %@", suggestedRetryAfter);
                        }
                    }
                } else if ([suggestedRetryAfter isKindOfClass:[NSNumber class]]) {
                    retryAfter = MIN([(NSNumber *)suggestedRetryAfter doubleValue], maxRetryAfter);
                }
            }
            
            if ([[MPStateMachine sharedInstance].minUploadDate compare:now] == NSOrderedAscending) {
                [MPStateMachine sharedInstance].minUploadDate = [now dateByAddingTimeInterval:retryAfter];
                MPILogDebug(@"Throttling network for %.0f seconds", retryAfter);
            }
        }
            break;
            
        default:
            [MPStateMachine sharedInstance].minUploadDate = [NSDate distantPast];
            break;
    }
}

#pragma mark Notification handlers
- (void)handleReachabilityChanged:(NSNotification *)notification {
    retrievingConfig = retrievingSegments = uploading = NO;
}

#pragma mark Public accessors
- (BOOL)inUse {
    return retrievingConfig || retrievingSegments || uploading;
}

- (BOOL)retrievingSegments {
    return retrievingSegments;
}

#pragma mark Public methods
- (void)requestConfig:(void(^)(BOOL success, NSDictionary *configurationDictionary))completionHandler {
    if (retrievingConfig || [MPStateMachine sharedInstance].networkStatus == MParticleNetworkStatusNotReachable) {
        return;
    }
    
    retrievingConfig = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    
    MPILogVerbose(@"Starting config request");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];

    [self beginBackgroundTask];
    
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    MPConnector *connector = [[MPConnector alloc] initWithConnectionId:connectionId];
    
    [connector asyncGetDataFromURL:self.configURL
                 completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                     __strong MPNetworkCommunication *strongSelf = weakSelf;
                     if (!strongSelf) {
                         completionHandler(NO, nil);
                         return;
                     }
                     
                     [strongSelf endBackgroundTask];
                     
                     NSInteger responseCode = [httpResponse statusCode];
                     MPILogVerbose(@"Config Response Code: %ld, Execution Time: %.2fms", (long)responseCode, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                     
                     if (responseCode == HTTPStatusCodeNotModified) {
                         completionHandler(YES, nil);
                         strongSelf->retrievingConfig = NO;
                         return;
                     }
                     
                     NSDictionary *configurationDictionary = nil;
                     MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                     BOOL success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;

                     if (success) {
                         NSDictionary *headersDictionary = [httpResponse allHeaderFields];
                         NSString *eTag = headersDictionary[kMPHTTPETagHeaderKey];
                         
                         if (!MPIsNull(eTag)) {
                             NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                             userDefaults[kMPHTTPETagHeaderKey] = eTag;
                         }
                         
                         @try {
                             NSError *serializationError = nil;
                             configurationDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                             success = serializationError == nil && [configurationDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeConfig];
                         } @catch (NSException *exception) {
                             success = NO;
                             configurationDictionary = nil;
                         }
                     } else {
                         if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                             responseAction = MPNetworkResponseActionThrottle;
                         }
                         
                         MPILogWarning(@"Failed config request");
                     }
                     
                     [strongSelf processNetworkResponseAction:responseAction uploadInstance:nil httpResponse:httpResponse];
                     
                     completionHandler(success, configurationDictionary);
                     
                     strongSelf->retrievingConfig = NO;
                 }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPILogWarning(@"Failed config request");
            completionHandler(NO, nil);
        }
        
        [connector cancelRequest];
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf->retrievingConfig = NO;
        }
    });
}

- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler {
    if (retrievingSegments) {
        return;
    }
    
    retrievingSegments = YES;
    
    [self beginBackgroundTask];
    
    MPConnector *connector = [[MPConnector alloc] init];
    
    __weak MPNetworkCommunication *weakSelf = self;
    NSDate *fetchSegmentsStartTime = [NSDate date];
    
    [connector asyncGetDataFromURL:self.segmentURL
                 completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                     NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:fetchSegmentsStartTime];
                     __strong MPNetworkCommunication *strongSelf = weakSelf;
                     if (!strongSelf) {
                         completionHandler(NO, nil, elapsedTime, nil);
                         return;
                     }
                     
                     strongSelf->retrievingSegments = NO;
                     
                     [strongSelf endBackgroundTask];
                     
                     if ([data length] == 0) {
                         completionHandler(NO, nil, elapsedTime, nil);
                         return;
                     }
                     
                     NSMutableArray<MPSegment *> *segments = nil;
                     NSInteger responseCode = [httpResponse statusCode];
                     BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
                     
                     if (success) {
                         NSDictionary *segmentsDictionary = nil;
                         
                         @try {
                             NSError *serializationError = nil;
                             segmentsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                             success = serializationError == nil;
                         } @catch (NSException *exception) {
                             segmentsDictionary = nil;
                             success = NO;
                             MPILogError(@"Segments Error: %@", [exception reason]);
                         }
                         
                         NSArray *segmentsList = success ? segmentsDictionary[kMPSegmentListKey] : nil;
                         if (segmentsList.count > 0) {
                             segments = [[NSMutableArray alloc] initWithCapacity:segmentsList.count];
                             MPSegment *segment;
                             
                             for (NSDictionary *segmentDictionary in segmentsList) {
                                 segment = [[MPSegment alloc] initWithDictionary:segmentDictionary];
                                 
                                 if (segment) {
                                     [segments addObject:segment];
                                 }
                             }
                         }
                         
                         MPILogVerbose(@"Segments Response Code: %ld", (long)responseCode);
                     } else {
                         MPILogWarning(@"Segments Error - Response Code: %ld", (long)responseCode);
                     }
                     
                     if (segments.count == 0) {
                         segments = nil;
                     }
                     
                     NSError *segmentError = nil;
                     if (responseCode == HTTPStatusCodeForbidden) {
                         segmentError = [NSError errorWithDomain:@"mParticle Segments"
                                                            code:responseCode
                                                        userInfo:@{@"message":@"Segments not enabled for this org."}];
                     }
                     
                     if (elapsedTime > timeout) {
                         segmentError = [NSError errorWithDomain:@"mParticle Segments"
                                                            code:MPNetworkErrorDelayedSegemnts
                                                        userInfo:@{@"message":@"It took too long to retrieve segments."}];
                     }
                     
                     completionHandler(success, (NSArray *)segments, elapsedTime, segmentError);
                 }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        
        if (strongSelf && !strongSelf->retrievingSegments) {
            return;
        }
        
        NSError *error = [NSError errorWithDomain:@"mParticle Segments"
                                             code:MPNetworkErrorTimeout
                                         userInfo:@{@"message":@"Segment request timeout."}];
        
        completionHandler(YES, nil, timeout, error);
        
        if (strongSelf) {
            strongSelf->retrievingSegments = NO;
        }
    });
}

- (void)upload:(NSArray<MPUpload *> *)uploads index:(NSUInteger)index completionHandler:(MPUploadsCompletionHandler)completionHandler {
    MPUpload *upload = uploads[index];
    __weak MPNetworkCommunication *weakSelf = self;
    
    [self uploadData:upload.uploadData
             batchId:upload.uuid
          uploadType:MPNetworkUploadTypeBatch
   completionHandler:^(BOOL success, NSDictionary *responseDictionary, MPNetworkResponseAction responseAction, NSHTTPURLResponse *httpResponse) {
       __strong MPNetworkCommunication *strongSelf = weakSelf;
       
       [strongSelf processNetworkResponseAction:responseAction uploadInstance:upload httpResponse:httpResponse];
       
       BOOL finished = index == uploads.count - 1;
       completionHandler(success, upload, responseDictionary, finished);
       
       strongSelf->uploading = NO;
       if (!finished) {
           [strongSelf upload:uploads index:(index + 1) completionHandler:completionHandler];
       }
   }];
}

- (void)uploadSessionHistory:(MPSessionHistory *)sessionHistory completionHandler:(void(^)(BOOL success))completionHandler {
    if (!sessionHistory) {
        completionHandler(NO);
        return;
    }

    NSError *error = nil;
    NSData *sessionHistoryData = nil;
    
    @try {
        sessionHistoryData = [NSJSONSerialization dataWithJSONObject:[sessionHistory dictionaryRepresentation] options:0 error:&error];
        
        if (sessionHistoryData == nil && error != nil) {
            completionHandler(NO);
            return;
        }
    } @catch (NSException *exception) {
        completionHandler(NO);
        return;
    }
    
    __weak MPNetworkCommunication *weakSelf = self;
    
    [self uploadData:sessionHistoryData
             batchId:sessionHistory.session.uuid
          uploadType:MPNetworkUploadTypeSessionHistory
   completionHandler:^(BOOL success, NSDictionary *responseDictionary, MPNetworkResponseAction responseAction, NSHTTPURLResponse *httpResponse) {
       __strong MPNetworkCommunication *strongSelf = weakSelf;
       
       if (strongSelf) {
           [strongSelf processNetworkResponseAction:responseAction uploadInstance:nil httpResponse:httpResponse];
           
           completionHandler(success);
       } else {
           completionHandler(NO);
       }
   }];
}

@end
