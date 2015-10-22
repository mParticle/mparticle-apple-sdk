//
//  MPNetworkCommunication.h
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

@class MPCommand;
@class MPSession;
@class MPUpload;
@class MPStandaloneCommand;
@class MPStandaloneUpload;
@class MPSessionHistory;

extern NSString *const kMPURLScheme;
extern NSString *const kMPURLHost;
extern NSString *const kMPURLHostConfig;

typedef NS_ENUM(NSInteger, MPNetworkResponseAction) {
    MPNetworkResponseActionNone = 0,
    MPNetworkResponseActionDeleteBatch,
    MPNetworkResponseActionThrottle
};

typedef NS_ENUM(NSInteger, MPNetworkError) {
    MPNetworkErrorTimeout = 1,
    MPNetworkErrorDelayedSegemnts
};

typedef void(^MPCommandsCompletionHandler)(BOOL success, MPCommand *command, BOOL finished);
typedef void(^MPSegmentResponseHandler)(BOOL success, NSArray *segments, NSTimeInterval elapsedTime, NSError *error);
typedef void(^MPUploadsCompletionHandler)(BOOL success, MPUpload *upload, NSDictionary *responseDictionary, BOOL finished);
typedef void(^MPStandaloneCommandsCompletionHandler)(BOOL success, MPStandaloneCommand *standaloneCommand, BOOL finished);
typedef void(^MPStandaloneUploadsCompletionHandler)(BOOL success, MPStandaloneUpload *standaloneUpload, NSDictionary *responseDictionary, BOOL finished);

@interface MPNetworkCommunication : NSObject

@property (nonatomic, unsafe_unretained, readonly) BOOL inUse;
@property (nonatomic, unsafe_unretained, readonly) BOOL retrievingSegments;

- (void)requestConfig:(void(^)(BOOL success, NSDictionary *configurationDictionary))completionHandler;
- (void)requestSegmentsWithTimeout:(NSTimeInterval)timeout completionHandler:(MPSegmentResponseHandler)completionHandler;
- (void)sendCommands:(NSArray *)standaloneCommands index:(NSUInteger)index completionHandler:(MPCommandsCompletionHandler)completionHandler;
- (void)sendStandaloneCommands:(NSArray *)commands index:(NSUInteger)index completionHandler:(MPStandaloneCommandsCompletionHandler)completionHandler;
- (void)standaloneUploads:(NSArray *)standaloneUploads index:(NSUInteger)index completionHandler:(MPStandaloneUploadsCompletionHandler)completionHandler;
- (void)upload:(NSArray *)uploads index:(NSUInteger)index completionHandler:(MPUploadsCompletionHandler)completionHandler;
- (void)uploadSessionHistory:(MPSessionHistory *)sessionHistory completionHandler:(void(^)(BOOL success))completionHandler;

@end
