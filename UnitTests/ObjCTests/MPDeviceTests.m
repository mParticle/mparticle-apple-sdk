#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPIConstants.h"
#import "MParticleSwift.h"
@import mParticle_Apple_SDK_Swift;
#if TARGET_OS_IOS == 1
    #import <CoreTelephony/CTTelephonyNetworkInfo.h>
    #import <CoreTelephony/CTCarrier.h>
#endif
@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPDeviceTests : XCTestCase

@end

@implementation MPDeviceTests

- (void)testDictionaryDescription {
    MParticle *mparticle = [MParticle sharedInstance];
    MPUserDefaults *userDefaults = [MPUserDefaults
            standardUserDefaultsWithStateMachine: mparticle.stateMachine
                               backendController: mparticle.backendController
                                        identity: mparticle.identity];
    NSData *testDeviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
    userDefaults[kMPDeviceTokenKey] = testDeviceToken;
    
    NSString *testCountry = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];

    MPLog* logger = [[MPLog alloc] initWithLogLevel:MPILogLevelSwiftDebug];

    MPDevice *device = [[MPDevice alloc] initWithStateMachine:(id<MPStateMachineMPDeviceProtocol>)mparticle.stateMachine
                                                 userDefaults:(id<MPIdentityApiMPUserDefaultsProtocol>)userDefaults
                                                     identity:(id<MPIdentityApiMPDeviceProtocol>)mparticle.identity
                                                       logger:logger];

    NSDictionary *testDictionary = device.dictionaryRepresentation;
    XCTAssertEqualObjects(testDictionary[@"dll"], @"en");
    XCTAssertEqualObjects(testDictionary[@"dlc"], testCountry);
    XCTAssertEqualObjects(testDictionary[@"dma"], @"Apple");
}

@end
