//#import <XCTest/XCTest.h>
//#import "mParticle.h"
//#import "MPIConstants.h"
//#import "MPStateMachine.h"
//#import "MPBaseTestCase.h"
//#import "MPUserDefaultsConnector.h"
//@import mParticle_Apple_SDK_Swift;
//
//@interface MParticle ()
//
//+ (dispatch_queue_t)messageQueue;
//@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
//@property (nonatomic, strong, nonnull) MParticleOptions *options;
//@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;
//
//@end
//
//@interface MPResponseConfigTests : MPBaseTestCase
//
//@end
//
//@implementation MPResponseConfigTests
//
//- (void)setUp {
//    [super setUp];
//    
//    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
//    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
//    
//    [MParticle sharedInstance].backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)[MParticle sharedInstance]];
//}
//- (void)testInstance {
//    NSDictionary *configuration = @{kMPRemoteConfigKitsKey:[NSNull null],
//                                    kMPRemoteConfigCustomModuleSettingsKey:[NSNull null],
//                                    kMPRemoteConfigRampKey:@100,
//                                    kMPRemoteConfigTriggerKey:[NSNull null],
//                                    kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeIgnore,
//                                    kMPRemoteConfigSessionTimeoutKey:@112};
//    
//    id<MPUserDefaultsConnectorProtocol> connector = (id<MPUserDefaultsConnectorProtocol>)[[MPUserDefaultsConnector alloc] init];
//    MPResponseConfig *responseConfig = [[MPResponseConfig alloc] initWithConfiguration:configuration connector:connector];
//
//    XCTAssertNotNil(responseConfig, @"Should not have been nil.");
//}
//
//
//@end
