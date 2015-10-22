//
//  MPPersistenceController.h
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

#import "MParticleUserNotification.h"

@class MPSegment;
@class MPCommand;
@class MPMessage;
@class MPProductBag;
@class MPSession;
@class MPUpload;
@class MPStandaloneCommand;
@class MPStandaloneMessage;
@class MPStandaloneUpload;
@class MPCookie;
@class MPConsumerInfo;
@class MPForwardRecord;

typedef NS_ENUM(NSUInteger, MPPersistenceOperation) {
    MPPersistenceOperationDelete = 0,
    MPPersistenceOperationFlag
};

@interface MPPersistenceController : NSObject

@property (nonatomic, readonly, getter = isDatabaseOpen) BOOL databaseOpen;

+ (instancetype)sharedInstance;
- (void)archiveSession:(MPSession *)session completionHandler:(void (^)(MPSession *archivedSession))completionHandler;
- (BOOL)closeDatabase;
- (NSUInteger)countMesssagesForUploadInSession:(MPSession *)session;
- (NSUInteger)countStandaloneMessages;
- (void)deleteCommand:(MPCommand *)command;
- (void)deleteConsumerInfo;
- (void)deleteCookie:(MPCookie *)cookie;
- (void)deleteExpiredUserNotifications;
- (void)deleteForwardRecodsIds:(NSArray *)forwardRecordsIds;
- (void)deleteMessagesWithNoSession;
- (void)deleteNetworkPerformanceMessages;
- (void)deletePreviousSession;
- (void)deleteProductBag:(MPProductBag *)productBag;
- (void)deleteAllProductBags;
- (void)deleteRecordsOlderThan:(NSTimeInterval)timestamp;
- (void)deleteSegments;
- (void)deleteSession:(MPSession *)session;
- (void)deleteUpload:(MPUpload *)upload;
- (void)deleteUploadId:(int64_t)uploadId;
- (void)deleteUserNotification:(MParticleUserNotification *)userNotification;
- (void)deleteStandaloneCommand:(MPStandaloneCommand *)standaloneCommand;
- (void)deleteStandaloneMessage:(MPStandaloneMessage *)standaloneMessage;
- (void)deleteStandaloneMessageIds:(NSArray *)standaloneMessageIds;
- (void)deleteStandaloneUpload:(MPStandaloneUpload *)standaloneUpload;
- (void)deleteStandaloneUploadId:(int64_t)standaloneUploadId;
- (NSArray *)fetchBreadcrumbs;
- (void)fetchCommandsInSession:(MPSession *)session completionHandler:(void (^)(NSArray *commands))completionHandler;
- (MPConsumerInfo *)fetchConsumerInfo;
- (NSArray *)fetchCookies;
- (NSArray *)fetchDisplayedLocalUserNotifications;
- (NSArray *)fetchDisplayedRemoteUserNotifications;
- (NSArray *)fetchDisplayedLocalUserNotificationsSince:(NSTimeInterval)referenceDate;
- (NSArray *)fetchDisplayedRemoteUserNotificationsSince:(NSTimeInterval)referenceDate;
- (NSArray *)fetchForwardRecords;
- (NSArray *)fetchMessagesInSession:(MPSession *)session;
- (void)fetchMessagesForUploadingInSession:(MPSession *)session completionHandler:(void (^)(NSArray *messages))completionHandler;
- (NSArray *)fetchPossibleSessionsFromCrash;
- (void)fetchPreviousSession:(void (^)(MPSession *previousSession))completionHandler;
- (MPProductBag *)fetchProductBag:(NSString *)bagName;
- (NSArray *)fetchProductBags;
- (NSArray *)fetchSegments;
- (MPMessage *)fetchSessionEndMessageInSession:(MPSession *)session;
- (MPSession *)fetchSessionFromCrash;
- (void)fetchSessions:(void (^)(NSMutableArray *sessions))completionHandler;
- (void)fetchUploadedMessagesInSession:(MPSession *)session excludeNetworkPerformanceMessages:(BOOL)excludeNetworkPerformance completionHandler:(void (^)(NSArray *messages))completionHandler;
- (void)fetchUploadsInSession:(MPSession *)session completionHandler:(void (^)(NSArray *uploads))completionHandler;
- (void)fetchUserNotificationCampaignHistory:(void (^)(NSArray *userNotificationCampaignHistory))completionHandler;
- (NSArray *)fetchUserNotifications;
- (NSArray *)fetchStandaloneCommands;
- (NSArray *)fetchStandaloneMessages;
- (NSArray *)fetchStandaloneMessagesForUploading;
- (NSArray *)fetchStandaloneUploads;
- (void)purgeMemory;
- (BOOL)openDatabase;
- (void)saveBreadcrumb:(MPMessage *)message session:(MPSession *)session;
- (void)saveCommand:(MPCommand *)command;
- (void)saveConsumerInfo:(MPConsumerInfo *)consumerInfo;
- (void)saveForwardRecord:(MPForwardRecord *)forwardRecord;
- (void)saveMessage:(MPMessage *)message;
- (void)saveProductBag:(MPProductBag *)productBag;
- (void)saveSegment:(MPSegment *)segment;
- (void)saveSession:(MPSession *)session;
- (void)saveUpload:(MPUpload *)upload messageIds:(NSArray *)messageIds operation:(MPPersistenceOperation)operation;
- (void)saveUserNotification:(MParticleUserNotification *)userNotification;
- (void)saveStandaloneCommand:(MPStandaloneCommand *)standaloneCommand;
- (void)saveStandaloneMessage:(MPStandaloneMessage *)standaloneMessage;
- (void)saveStandaloneUpload:(MPStandaloneUpload *)standaloneUpload;
- (void)updateConsumerInfo:(MPConsumerInfo *)consumerInfo;
- (void)updateSession:(MPSession *)session;
- (void)updateUserNotification:(MParticleUserNotification *)userNotification;

@end
