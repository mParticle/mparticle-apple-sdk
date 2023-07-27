//
//  MParticleKit.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MParticleKit.h"
#import "MPEnums.h"
#import "MPIConstants.h"
#import "MPKitContainer.h"
#import "MPDataPlanFilter.h"
#import "MPNetworkCommunication.h"
#import "MParticleWebView.h"
#import "MPMessage.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPUploadBuilder.h"
#import "MPBackendController.h"

const NSInteger kMParticleKitCode = 999999999;

@interface MParticle()
@property (nonatomic, strong, nullable) NSArray<NSDictionary *> *deferredKitConfiguration;
@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;
@property (nonatomic, strong) MParticleWebView *webView;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
@property (nonatomic, strong, nonnull) MPBackendController *backendController;
+ (dispatch_queue_t)messageQueue;
+ (void)executeOnMessage:(void(^)(void))block;
@end

@interface MPBackendController()
@property (nonatomic, strong) NSMutableSet<NSString *> *deletedUserAttributes;
- (void)requestConfig:(void(^ _Nullable)(BOOL uploadBatch))completionHandler;
@end

@interface MParticleKit() {
    BOOL _skipNextUpload;
}
@end

@implementation MParticleKit

#pragma mark - MPKitProtocol

+ (NSNumber *)kitCode { return @(kMParticleKitCode); }
- (BOOL)started { return YES; }
- (id)providerKitInstance { return self; }
- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration {
    return [[MPKitExecStatus alloc] initWithSDKCode:[self.class kitCode] returnCode:MPKitReturnCodeSuccess];
}

#pragma mark - Implementation

- (void)skipNextUpload {
    _skipNextUpload = YES;
}

- (instancetype)init {
    if (self = [super init]) {
        _networkCommunication = [[MPNetworkCommunication alloc] init];
        _mpInstance = [MParticle sharedInstance];
    }
    return self;
}

- (NSArray *)batchMessageArraysFromMessageArray:(NSArray *)messages maxBatchMessages:(NSInteger)maxBatchMessages maxBatchBytes:(NSInteger)maxBatchBytes maxMessageBytes:(NSInteger)maxMessageBytes {
    NSMutableArray *batchMessageArrays = [NSMutableArray array];
    int batchMessageCount = 0;
    int batchByteCount = 0;
    
    NSMutableArray *batchMessages = [NSMutableArray array];
    
    for (int i = 0; i < messages.count; i += 1) {
        MPMessage *message = messages[i];
        
        NSInteger iterationMaxBatchBytes = maxBatchBytes;
        NSInteger iterationMaxMessageBytes = maxMessageBytes;
        bool isCrashReport = [message.messageType isEqualToString:kMPMessageTypeStringCrashReport];
        if (isCrashReport) {
            iterationMaxBatchBytes = MAX_BYTES_PER_BATCH_CRASH;
            iterationMaxMessageBytes = MAX_BYTES_PER_EVENT_CRASH;
        }
        
        if (message.messageData.length > iterationMaxMessageBytes) continue;
        
        if (batchMessageCount + 1 > maxBatchMessages || batchByteCount + message.messageData.length > iterationMaxBatchBytes) {
            
            [batchMessageArrays addObject:[batchMessages copy]];
            
            batchMessages = [NSMutableArray array];
            batchMessageCount = 0;
            batchByteCount = 0;
            
        }
        [batchMessages addObject:message];
        batchMessageCount += 1;
        batchByteCount += message.messageData.length;
    }
    
    if (batchMessages.count > 0) {
        [batchMessageArrays addObject:[batchMessages copy]];
    }
    return [batchMessageArrays copy];
}

- (void)uploadBatchesWithCompletionHandler:(void(^)(BOOL success))completionHandler {
    const void (^completionHandlerCopy)(BOOL) = [completionHandler copy];
    __weak MParticleKit *weakSelf = self;
    MPPersistenceController *persistence = [MParticle sharedInstance].persistenceController;
    
    //Fetch all stored messages (1)
    NSDictionary *mpidMessages = [persistence fetchMessagesForUploading];
    if (mpidMessages && mpidMessages.count != 0) {
        [mpidMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull mpid, NSMutableDictionary *  _Nonnull sessionMessages, BOOL * _Nonnull stop) {
            [sessionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull sessionId, NSMutableDictionary *  _Nonnull dataPlanMessages, BOOL * _Nonnull stop) {
                [dataPlanMessages enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull dataPlanId, NSMutableDictionary *  _Nonnull versionMessages, BOOL * _Nonnull stop) {
                    [versionMessages enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull dataPlanVersion, NSArray *  _Nonnull messages, BOOL * _Nonnull stop) {
                        //In batches broken up by mpid and then sessionID create the Uploads (2)
                        __strong MParticleKit *strongSelf = weakSelf;
                        NSNumber *nullableSessionID = (sessionId.integerValue == -1) ? nil : sessionId;
                        NSString *nullableDataPlanId = [dataPlanId isEqualToString:@"0"] ? nil : dataPlanId;
                        NSNumber *nullableDataPlanVersion = (dataPlanVersion.integerValue == 0) ? nil : dataPlanVersion;
                        
                        //Within a session, within a data plan ID, within a version, we also break up based on limits for messages per batch and (approximately) bytes per batch
                        NSArray *batchMessageArrays = [self batchMessageArraysFromMessageArray:messages maxBatchMessages:MAX_EVENTS_PER_BATCH maxBatchBytes:MAX_BYTES_PER_BATCH maxMessageBytes:MAX_BYTES_PER_EVENT];
                        
                        for (int i = 0; i < batchMessageArrays.count; i += 1) {
                            NSArray *limitedMessages = batchMessageArrays[i];
                            MPUploadBuilder *uploadBuilder = [MPUploadBuilder newBuilderWithMpid: mpid sessionId:nullableSessionID messages:limitedMessages sessionTimeout:_mpInstance.backendController.sessionTimeout uploadInterval:_mpInstance.backendController.uploadInterval dataPlanId:nullableDataPlanId dataPlanVersion:nullableDataPlanVersion];
                            
                            if (!uploadBuilder || !strongSelf) {
                                completionHandlerCopy(YES);
                                return;
                            }
                            
                            [uploadBuilder withUserAttributes:[_mpInstance.backendController userAttributesForUserId:mpid] deletedUserAttributes:_mpInstance.backendController.deletedUserAttributes];
                            [uploadBuilder withUserIdentities:[_mpInstance.backendController userIdentitiesForUserId:mpid]];
                            [uploadBuilder build:^(MPUpload *upload) {
                                //Save the Upload to the Database (3)
                                [persistence saveUpload:upload];
                            }];
                        }
                        
                        //Delete all messages associated with the batches (4)
                        [persistence deleteMessages:messages];
                        
                        _mpInstance.backendController.deletedUserAttributes = nil;
                    }];
                }];
            }];
        }];
    }
    
    //Fetch all sessions and delete them if inactive (5)
    [persistence deleteAllSessionsExcept:[MParticle sharedInstance].stateMachine.currentSession];
    
    if (_skipNextUpload) {
        _skipNextUpload = NO;
        completionHandler(YES);
        return;
    }
    
    // Fetch all Uploads (6)
    NSArray<MPUpload *> *uploads = [persistence fetchUploads];
    
    if (!uploads || uploads.count == 0) {
        completionHandlerCopy(YES);
        return;
    }
    
    if ([MParticle sharedInstance].stateMachine.dataRamped) {
        for (MPUpload *upload in uploads) {
            [persistence deleteUpload:upload];
        }
        
        [persistence deleteNetworkPerformanceMessages];
        return;
    }
    
    //Send all Uploads to the backend (7)
    __strong MParticleKit *strongSelf = weakSelf;
    [strongSelf.networkCommunication upload:uploads completionHandler:^{
        completionHandlerCopy(YES);
    }];
}

@end
