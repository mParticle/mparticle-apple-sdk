#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPBaseTestCase.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPAppNotificationHandler.h"
#import "MPConnector.h"
#import "MPNetworkCommunication.h"
#import "MPConnectorProtocol.h"
#import "MPConnectorFactoryProtocol.h"
#import "MPIConstants.h"

@interface MParticle (Tests)
@property (nonatomic, strong) MPPersistenceController_PRIVATE *persistenceController;
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
    if (!instance.persistenceController) {
        // Ensure we have a persistence controller to reset the db etc
        instance.persistenceController = [[MPPersistenceController_PRIVATE alloc] init];
    }
    
    [instance reset:^{
        MPNetworkCommunication_PRIVATE.connectorFactory = [[MPTestConnectorFactory alloc] init];
        completion(nil);
    }];
}

- (void)tearDown {
    MPNetworkCommunication_PRIVATE.connectorFactory = nil;
    [super tearDown];
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

@end
