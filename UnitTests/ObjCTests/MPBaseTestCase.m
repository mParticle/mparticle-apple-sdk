#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPBaseTestCase.h"
#import "mParticle.h"
#import "MPPersistenceUtilities.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPAppNotificationHandler.h"
#import "MPNetworkCommunication.h"
#import "MPConnectorFactoryProtocol.h"
#import "MPIConstants.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle (Tests)
+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPPersistenceStorePRIVATE *persistenceStore;
@property (nonatomic, strong, nullable) NSString *dataPlanId;
@property (nonatomic, strong, nullable) NSNumber *dataPlanVersion;
- (MPLog *)getLogger;
- (void)initializePersistence;
@end

@interface MPTestConnectorFactory : NSObject <MPConnectorFactoryProtocol>

@property (nonatomic) NSMutableArray *mockConnectors;

@end

@implementation MPTestConnectorFactory

- (NSObject<MPConnectorProtocol> *)createConnector {
    @synchronized ([self class]) {
         return OCMClassMock([MPConnector class]);
    }
}

@end

@implementation MPBaseTestCase

- (void)setUpWithCompletionHandler:(void (^)(NSError * _Nullable))completion {
    [super setUp];
    MParticle *instance = [MParticle sharedInstance];
    [instance initializePersistence];
    
    [instance reset:^{
        MPNetworkCommunication_PRIVATE.connectorFactory = [[MPTestConnectorFactory alloc] init];
        completion(nil);
    }];
}

- (void)tearDown {
    MPNetworkCommunication_PRIVATE.connectorFactory = nil;
    [super tearDown];
}

- (MPMessageBuilderContext *)messageBuilderContext {
    MParticle *mparticle = [MParticle sharedInstance];
    return [[MPMessageBuilderContext alloc] initWithDataPlanId:mparticle.dataPlanId
                                               dataPlanVersion:mparticle.dataPlanVersion
                                                        logger:[mparticle getLogger]];
}

- (id)attemptSecureEncodingwithClass:(Class)class Object:(id)object {
    //Store Object
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *stateMachineDirectoryPath = STATE_MACHINE_DIRECTORY_PATH;
    
    if (![fileManager fileExistsAtPath:stateMachineDirectoryPath]) {
        [fileManager createDirectoryAtPath:stateMachineDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *testPath = [NSString stringWithFormat:@"%@", @"MPTest.test"];
    NSString *testFile = [stateMachineDirectoryPath stringByAppendingPathComponent:testPath];
    
    if ([fileManager fileExistsAtPath:testFile]) {
        [fileManager removeItemAtPath:testFile error:nil];
    }
    
    BOOL success = [NSKeyedArchiver archiveRootObject:object toFile:testFile];
    XCTAssertTrue(success);
    
    //Retrieve Object
    XCTAssert([fileManager fileExistsAtPath:testFile]);
    
    id returnedObject = [NSKeyedUnarchiver unarchiveObjectWithFile:testFile];
    XCTAssertNotNil(returnedObject);
        
    //Remove Object
    if ([fileManager fileExistsAtPath:testFile]) {
        [fileManager removeItemAtPath:testFile error:nil];
    }
    
    return returnedObject;
}

- (MPStateMachine_PRIVATE *)freshStateMachine {
    return [[MPStateMachine_PRIVATE alloc] initWithUserDefaults:MPUserDefaultsConnector.userDefaults
                                                      connector:(id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init]
                                                   messageQueue:[MParticle messageQueue]
                                                     sdkVersion:kMParticleSDKVersion
                                               deploymentTarget:__IPHONE_OS_VERSION_MIN_REQUIRED
                                                       buildSDK:__IPHONE_OS_VERSION_MAX_ALLOWED];
}

@end
