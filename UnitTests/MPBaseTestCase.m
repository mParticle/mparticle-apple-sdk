#import <XCTest/XCTest.h>
#import "MPBaseTestCase.h"
#import "mParticle.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPKitContainer.h"
#import "MPAppNotificationHandler.h"
#import "MPArchivist.h"

@implementation MPBaseTestCase

- (void)setUp {
    [super setUp];
    [[MParticle sharedInstance] reset];
}

- (void)tearDown {
    [[MParticle sharedInstance] reset];
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
    
    NSError *error = nil;
    BOOL success = [MPArchivist archiveDataWithRootObject:object toFile:testFile error:&error];
    XCTAssertTrue(success);
    XCTAssertNil(error);
    
    //Retrieve Object
    XCTAssert([fileManager fileExistsAtPath:testFile]);
    
    id returnedObject = nil;
    
    returnedObject = [MPArchivist unarchiveObjectOfClass:class withFile:testFile error:nil];
    
    //Remove Object
    if ([fileManager fileExistsAtPath:testFile]) {
        [fileManager removeItemAtPath:testFile error:nil];
    }
    
    return returnedObject;
}

@end
