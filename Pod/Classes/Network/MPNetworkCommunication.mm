//
//  MPNetworkCommunication.m
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

#import "MPNetworkCommunication.h"
#import "MPMessage.h"
#import "MPSession.h"
#import "UIKit/UIKit.h"
#import "MPConnector.h"
#import "MPStateMachine.h"
#import "MPCommand.h"
#import "MPUpload.h"
#import "MPDevice.h"
#import "MPApplication.h"
#import "MPSegment.h"
#import "MPConstants.h"
#import "MPStandaloneCommand.h"
#import "MPStandaloneUpload.h"
#import "Zip.h"
#import "MPURLRequestBuilder.h"
#import "MParticleReachability.h"
#import "MPLogger.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"
#import "MPDataModelAbstract.h"
#import "NSUserDefaults+mParticle.h"
#import "MPSessionHistory.h"

using namespace mParticle;
using namespace std;

NSString *const urlFormat = @"%@://%@%@/%@%@"; // Scheme, URL Host, API Version, API key, path
NSString *const kMPConfigVersion = @"/v3";
NSString *const kMPConfigURL = @"/config";
NSString *const kMPEventsVersion = @"/v1";
NSString *const kMPEventsURL = @"/events";
NSString *const kMPSegmentVersion = @"/v1";
NSString *const kMPSegmentURL = @"/audience";

NSString *const kMPURLScheme = @"https";
NSString *const kMPURLHost = @"nativesdks.mparticle.com";
NSString *const kMPURLHostConfig = @"config2.mparticle.com";

@interface MPNetworkCommunication() {
    BOOL retrievingConfig;
    BOOL retrievingSegments;
    BOOL sendingCommands;
    BOOL sendingStandaloneCommands;
    BOOL standaloneUploading;
    BOOL uploading;
    BOOL uploadingSessionHistory;
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
    if (!self) {
        return nil;
    }
    
    retrievingConfig = NO;
    retrievingSegments = NO;
    sendingCommands = NO;
    sendingStandaloneCommands = NO;
    standaloneUploading = NO;
    uploading = NO;
    uploadingSessionHistory = NO;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(handleReachabilityChanged:)
                               name:kMPReachabilityChangedNotification
                             object:nil];
    
    return self;
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:kMPReachabilityChangedNotification object:nil];
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
- (void)processNetworkResponseAction:(MPNetworkResponseAction)responseAction batchObject:(MPDataModelAbstract *)batchObject {
    switch (responseAction) {
        case MPNetworkResponseActionDeleteBatch:
            if (!batchObject) {
                return;
            }
            
            if ([batchObject isMemberOfClass:[MPUpload class]]) {
                [[MPPersistenceController sharedInstance] deleteUpload:(MPUpload *)batchObject];
            } else if ([batchObject isMemberOfClass:[MPStandaloneUpload class]]) {
                [[MPPersistenceController sharedInstance] deleteStandaloneUpload:(MPStandaloneUpload *)batchObject];
            }
            
            break;
            
        case MPNetworkResponseActionThrottle: {
            NSDate *now = [NSDate date];
            if ([[MPStateMachine sharedInstance].minUploadDate compare:now] == NSOrderedAscending) {
                [MPStateMachine sharedInstance].minUploadDate = [now dateByAddingTimeInterval:7200]; // 2 hours
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
    retrievingConfig = retrievingSegments = sendingCommands = sendingStandaloneCommands = standaloneUploading = uploading = uploadingSessionHistory = NO;
}

#pragma mark Public accessors
- (BOOL)inUse {
    return retrievingConfig || retrievingSegments || sendingCommands || sendingStandaloneCommands || standaloneUploading || uploading || uploadingSessionHistory;
}

- (BOOL)retrievingSegments {
    return retrievingSegments;
}

#pragma mark Public methods
- (void)requestConfig:(void(^)(BOOL success, NSDictionary *configurationDictionary))completionHandler {
    if (retrievingConfig) {
        return;
    }
    
    retrievingConfig = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    MPLogVerbose(@"Starting config request");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->retrievingConfig = NO;
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPConnector *connector = [[MPConnector alloc] init];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    connector.connectionId = connectionId;
    
    [connector asyncGetDataFromURL:self.configURL
                 completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                     __strong MPNetworkCommunication *strongSelf = weakSelf;
                     if (!strongSelf) {
                         completionHandler(NO, nil);
                         return;
                     }
                     
                     if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                         [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                         backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                     }
                     
                     NSInteger responseCode = [httpResponse statusCode];
                     MPLogVerbose(@"Config Response Code: %ld, Execution Time: %.2fms", (long)responseCode, ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                     
                     if (responseCode == HTTPStatusCodeNotModified) {
                         completionHandler(YES, nil);
                         strongSelf->retrievingConfig = NO;
                         return;
                     }
                     
                     NSDictionary *configurationDictionary = nil;
                     MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                     
                     BOOL success = NO;
                     
                     if (!data) {
                         completionHandler(NO, nil);
                         strongSelf->retrievingConfig = NO;
                         MPLogWarning(@"Failed config request");
                         return;
                     }
                     
                     NSDictionary *headersDictionary = [httpResponse allHeaderFields];
                     NSString *eTag = headersDictionary[kMPHTTPETagHeaderKey];
                     success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                     
                     if (!MPIsNull(eTag) && success) {
                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                         userDefaults[kMPHTTPETagHeaderKey] = eTag;
                     }
                     
                     if (success) {
                         @try {
                             NSError *serializationError = nil;
                             configurationDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                             success = serializationError == nil && [configurationDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeConfig];
                         } @catch (NSException *exception) {
                             success = NO;
                             responseCode = HTTPStatusCodeNoContent;
                         }
                     } else {
                         if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                             responseAction = MPNetworkResponseActionThrottle;
                         }
                     }
                     
                     [strongSelf processNetworkResponseAction:responseAction batchObject:nil];
                     
                     completionHandler(success, configurationDictionary);
                     strongSelf->retrievingConfig = NO;
                 }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPLogWarning(@"Failed config request");
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
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPConnector *connector = [[MPConnector alloc] init];
    
    __weak MPNetworkCommunication *weakSelf = self;
    NSDate *fetchSegmentsStartTime = [NSDate date];
    
    [connector asyncGetDataFromURL:self.segmentURL
                 completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                     __strong MPNetworkCommunication *strongSelf = weakSelf;
                     
                     if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                         [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                         backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                     }
                     
                     NSMutableArray<MPSegment *> *segments = nil;
                     NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:fetchSegmentsStartTime];
                     BOOL success = NO;
                     
                     if (!data) {
                         completionHandler(success, segments, elapsedTime, nil);
                         return;
                     }
                     
                     strongSelf->retrievingSegments = NO;
                     
                     NSArray *segmentsList = nil;
                     NSInteger responseCode = [httpResponse statusCode];
                     success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                     
                     if (success) {
                         NSError *serializationError = nil;
                         NSDictionary *segmentsDictionary = nil;
                         
                         @try {
                             @try {
                                 segmentsDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                                 success = serializationError == nil;
                             } @catch (NSException *exception) {
                                 segmentsDictionary = nil;
                                 success = NO;
                                 MPLogError(@"Segments Error: %@", [exception reason]);
                             }
                         } @catch (NSException *exception) {
                             segmentsDictionary = nil;
                             success = NO;
                             MPLogError(@"Segments Error: %@", [exception reason]);
                         }
                         
                         if (success) {
                             segmentsList = segmentsDictionary[kMPSegmentListKey];
                         }
                         
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
                         
                         MPLogVerbose(@"Segments Response Code: %ld", (long)responseCode);
                     } else {
                         MPLogWarning(@"Segments Error - Response Code: %ld", (long)responseCode);
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
                     
                     if (elapsedTime < timeout) {
                         completionHandler(success, (NSArray *)segments, elapsedTime, segmentError);
                     } else {
                         segmentError = [NSError errorWithDomain:@"mParticle Segments"
                                                            code:MPNetworkErrorDelayedSegemnts
                                                        userInfo:@{@"message":@"It took too long to retrieve segments."}];
                         
                         completionHandler(success, (NSArray *)segments, elapsedTime, segmentError);
                     }
                 }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        
        if (!strongSelf->retrievingSegments) {
            return;
        }
        
        NSError *error = [NSError errorWithDomain:@"mParticle Segments"
                                             code:MPNetworkErrorTimeout
                                         userInfo:@{@"message":@"Segment request timeout."}];
        
        completionHandler(YES, nil, timeout, error);
        strongSelf->retrievingSegments = NO;
    });
}

- (void)sendCommands:(NSArray<MPCommand *> *)commands index:(NSUInteger)index completionHandler:(MPCommandsCompletionHandler)completionHandler {
    if (sendingCommands) {
        return;
    }
    
    sendingCommands = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            strongSelf->sendingCommands = NO;
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPCommand *command = commands[index];
    NSURLRequest *urlRequest = [[[[[MPURLRequestBuilder newBuilderWithURL:command.url]
                                   withHttpMethod:command.httpMethod]
                                  withHeaderData:command.headerData]
                                 withPostData:command.postData]
                                build];
    
    if (urlRequest) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   __strong MPNetworkCommunication *strongSelf = weakSelf;
                                   if (!strongSelf) {
                                       return;
                                   }
                                   
                                   if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                                       [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                                       backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                                   }
                                   
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   NSInteger responseCode = [httpResponse statusCode];
                                   MPLogVerbose(@"Command Response Code: %ld", (long)responseCode);
                                   
                                   BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
                                   BOOL finished = index == commands.count - 1;
                                   
                                   completionHandler(success, command, finished);
                                   
                                   strongSelf->sendingCommands = NO;
                                   if (!finished) {
                                       [strongSelf sendCommands:commands index:(index + 1) completionHandler:completionHandler];
                                   }
                               }];
#pragma clang diagnostic pop
    } else {
        sendingCommands = NO;
        completionHandler(NO, command, YES);
    }
}

- (void)sendStandaloneCommands:(NSArray *)standaloneCommands index:(NSUInteger)index completionHandler:(MPStandaloneCommandsCompletionHandler)completionHandler {
    if (sendingStandaloneCommands) {
        return;
    }
    
    sendingStandaloneCommands = YES;
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    __weak MPNetworkCommunication *weakSelf = self;
    
    MPStandaloneCommand *standaloneCommand = standaloneCommands[index];
    NSURLRequest *urlRequest = [[[[[MPURLRequestBuilder newBuilderWithURL:standaloneCommand.url]
                                   withHttpMethod:standaloneCommand.httpMethod]
                                  withHeaderData:standaloneCommand.headerData]
                                 withPostData:standaloneCommand.postData]
                                build];
    
    if (urlRequest) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   __strong MPNetworkCommunication *strongSelf = weakSelf;
                                   
                                   if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                                       [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                                       backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                                   }
                                   
                                   NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                                   NSInteger responseCode = [httpResponse statusCode];
                                   MPLogVerbose(@"Stand-alone Command Response Code: %ld", (long)responseCode);
                                   
                                   BOOL success = responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted;
                                   BOOL finished = index == standaloneCommands.count - 1;
                                   
                                   completionHandler(success, standaloneCommand, finished);
                                   
                                   strongSelf->sendingStandaloneCommands = NO;
                                   if (!finished) {
                                       [strongSelf sendStandaloneCommands:standaloneCommands index:(index + 1) completionHandler:completionHandler];
                                   }
                               }];
#pragma clang diagnostic pop
    } else {
        sendingStandaloneCommands = NO;
        completionHandler(NO, standaloneCommand, YES);
    }
}

- (void)standaloneUploads:(NSArray<MPStandaloneUpload *> *)standaloneUploads index:(NSUInteger)index completionHandler:(MPStandaloneUploadsCompletionHandler)completionHandler {
    if (standaloneUploading) {
        return;
    }
    
    standaloneUploading = YES;
    
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPStandaloneUpload *standaloneUpload = standaloneUploads[index];
    NSString *uploadString = [standaloneUpload serializedString];
    MPConnector *connector = [[MPConnector alloc] init];
    __weak MPNetworkCommunication *weakSelf = self;
    
    NSData *zipUploadData = nil;
    tuple<unsigned char *, unsigned int> zipData = Zip::compress((const unsigned char *)[standaloneUpload.uploadData bytes], (unsigned int)[standaloneUpload.uploadData length]);
    if (get<0>(zipData) != nullptr) {
        zipUploadData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        [self processNetworkResponseAction:MPNetworkResponseActionDeleteBatch batchObject:standaloneUpload];
        completionHandler(NO, standaloneUpload, nil, YES);
        standaloneUploading = NO;
        return;
    }
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:uploadString
                   serializedParams:zipUploadData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      
                      if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                          [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                          backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                      }
                      
                      NSDictionary *responseDictionary = nil;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      BOOL finished = index == standaloneUploads.count - 1;
                      BOOL success = NO;
                      
                      if (!data) {
                          completionHandler(success, standaloneUpload, responseDictionary, finished);
                          
                          strongSelf->standaloneUploading = NO;
                          if (!finished) {
                              [strongSelf standaloneUploads:standaloneUploads index:(index + 1) completionHandler:completionHandler];
                          }
                          
                          return;
                      }
                      
                      NSInteger responseCode = [httpResponse statusCode];
                      success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                      
                      if (success) {
                          NSError *serializationError = nil;
                          
                          @try {
                              responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                              success = serializationError == nil;
                              MPLogVerbose(@"Stand-alone Uploaded Message: %@\n", uploadString);
                              MPLogVerbose(@"Stand-alone Upload Response Code: %ld", (long)responseCode);
                          } @catch (NSException *exception) {
                              responseDictionary = nil;
                              success = NO;
                              MPLogError(@"Stand-alone Upload Error: %@", [exception reason]);
                          }
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPLogWarning(@"Stand-alone Uploads Error - Response Code: %ld", (long)responseCode);
                      }
                      
                      [strongSelf processNetworkResponseAction:responseAction batchObject:standaloneUpload];
                      
                      completionHandler(success, standaloneUpload, responseDictionary, finished);
                      
                      strongSelf->standaloneUploading = NO;
                      if (!finished) {
                          [strongSelf standaloneUploads:standaloneUploads index:(index + 1) completionHandler:completionHandler];
                      }
                  }];
}

- (void)upload:(NSArray<MPUpload *> *)uploads index:(NSUInteger)index completionHandler:(MPUploadsCompletionHandler)completionHandler {
    if (uploading) {
        return;
    }
    
    uploading = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->uploading = NO;
            }
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    MPUpload *upload = uploads[index];
    NSString *uploadString = [upload serializedString];
    MPConnector *connector = [[MPConnector alloc] init];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    connector.connectionId = connectionId;
    
    MPLogVerbose(@"Source Batch Id: %@", upload.uuid);
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    NSData *zipUploadData = nil;
    tuple<unsigned char *, unsigned int> zipData = Zip::compress((const unsigned char *)[upload.uploadData bytes], (unsigned int)[upload.uploadData length]);
    if (get<0>(zipData) != nullptr) {
        zipUploadData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        [self processNetworkResponseAction:MPNetworkResponseActionDeleteBatch batchObject:upload];
        completionHandler(NO, upload, nil, YES);
        uploading = NO;
        return;
    }
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:uploadString
                   serializedParams:zipUploadData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      
                      if (!strongSelf) {
                          completionHandler(NO, upload, nil, YES);
                          return;
                      }
                      
                      if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                          [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                          backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                      }
                      
                      NSDictionary *responseDictionary = nil;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      BOOL finished = index == uploads.count - 1;
                      BOOL success = NO;
                      
                      if (!data) {
                          completionHandler(success, upload, responseDictionary, finished);
                          strongSelf->uploading = NO;
                          return;
                      }
                      
                      NSInteger responseCode = [httpResponse statusCode];
                      success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                      
                      if (success) {
                          NSError *serializationError = nil;
                          
                          @try {
                              responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&serializationError];
                              success = serializationError == nil && [responseDictionary[kMPMessageTypeKey] isEqualToString:kMPMessageTypeResponseHeader];
                              MPLogVerbose(@"Uploaded Message: %@\n", uploadString);
                              MPLogVerbose(@"Upload Response Code: %ld", (long)responseCode);
                          } @catch (NSException *exception) {
                              responseDictionary = nil;
                              success = NO;
                              MPLogError(@"Uploads Error: %@", [exception reason]);
                          }
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPLogWarning(@"Uploads Error - Response Code: %ld", (long)responseCode);
                      }
                      
                      MPLogVerbose(@"Upload Execution Time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                      
                      [strongSelf processNetworkResponseAction:responseAction batchObject:upload];
                      
                      completionHandler(success, upload, responseDictionary, finished);
                      
                      strongSelf->uploading = NO;
                      if (!finished) {
                          [strongSelf upload:uploads index:(index + 1) completionHandler:completionHandler];
                      }
                  }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPLogWarning(@"Failed Uploading Source Batch Id: %@", upload.uuid);
            completionHandler(NO, upload, nil, YES);
        }
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        strongSelf->uploading = NO;
        [connector cancelRequest];
    });
}

- (void)uploadSessionHistory:(MPSessionHistory *)sessionHistory completionHandler:(void(^)(BOOL success))completionHandler {
    if (uploadingSessionHistory) {
        return;
    }
    
    if (!sessionHistory) {
        completionHandler(NO);
        return;
    }
    
    uploadingSessionHistory = YES;
    __weak MPNetworkCommunication *weakSelf = self;
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    
    MPLogVerbose(@"Source Batch Id: %@", sessionHistory.session.uuid);
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    
    backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
            __strong MPNetworkCommunication *strongSelf = weakSelf;
            strongSelf->uploadingSessionHistory = NO;
            
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
    }];
    
    NSData *sessionHistoryData = [NSJSONSerialization dataWithJSONObject:[sessionHistory dictionaryRepresentation] options:0 error:nil];
    
    NSData *zipSessionData = nil;
    tuple<unsigned char *, unsigned int> zipData = Zip::compress((const unsigned char *)[sessionHistoryData bytes], (unsigned int)[sessionHistoryData length]);
    if (get<0>(zipData) != nullptr) {
        zipSessionData = [[NSData alloc] initWithBytes:get<0>(zipData) length:get<1>(zipData)];
        delete [] get<0>(zipData);
    } else {
        completionHandler(NO);
        uploadingSessionHistory = NO;
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:sessionHistoryData encoding:NSUTF8StringEncoding];
    MPConnector *connector = [[MPConnector alloc] init];
    NSString *const connectionId = [[NSUUID UUID] UUIDString];
    connector.connectionId = connectionId;
    
    [connector asyncPostDataFromURL:self.eventURL
                            message:jsonString
                   serializedParams:zipSessionData
                  completionHandler:^(NSData *data, NSError *error, NSTimeInterval downloadTime, NSHTTPURLResponse *httpResponse) {
                      __strong MPNetworkCommunication *strongSelf = weakSelf;
                      if (!strongSelf) {
                          completionHandler(NO);
                          return;
                      }
                      
                      NSInteger responseCode = [httpResponse statusCode];
                      BOOL success = (responseCode == HTTPStatusCodeSuccess || responseCode == HTTPStatusCodeAccepted) && [data length] > 0;
                      MPNetworkResponseAction responseAction = MPNetworkResponseActionNone;
                      
                      if (success) {
                          MPLogVerbose(@"Session History: %@\n", jsonString);
                          MPLogVerbose(@"Session History Response Code: %ld", (long)responseCode);
                      } else {
                          if (responseCode == HTTPStatusCodeBadRequest) {
                              responseAction = MPNetworkResponseActionDeleteBatch;
                          } else if (responseCode == HTTPStatusCodeServiceUnavailable || responseCode == HTTPStatusCodeTooManyRequests) {
                              responseAction = MPNetworkResponseActionThrottle;
                          }
                          
                          MPLogWarning(@"Session History Error - Response Code: %ld", (long)responseCode);
                      }
                      
                      MPLogVerbose(@"Session History Execution Time: %.2fms", ([[NSDate date] timeIntervalSince1970] - start) * 1000.0);
                      
                      [strongSelf processNetworkResponseAction:responseAction batchObject:nil];
                      
                      completionHandler(success);
                      
                      if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
                          [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
                          backgroundTaskIdentifier = UIBackgroundTaskInvalid;
                      }
                      
                      strongSelf->uploadingSessionHistory = NO;
                  }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([MPURLRequestBuilder requestTimeout] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!connector || ![connector.connectionId isEqualToString:connectionId]) {
            return;
        }
        
        if (connector.active) {
            MPLogWarning(@"Failed Uploading Source Batch Id: %@", sessionHistory.session.uuid);
            completionHandler(NO);
        }
        
        __strong MPNetworkCommunication *strongSelf = weakSelf;
        strongSelf->uploadingSessionHistory = NO;
        [connector cancelRequest];
    });
}

@end
