#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPIConstants.h"
#import "MParticleSwift.h"
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

- (void)testTelephonyRadioAccessTechnology {
#if TARGET_OS_IOS == 1 && !MPARTICLE_LOCATION_DISABLE
    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
    NSString *technology = device.radioAccessTechnology;
    XCTAssertEqualObjects(technology, @"None");
#endif
}

- (void)testDictionaryDescription {
#if TARGET_OS_IOS == 1 && !MPARTICLE_LOCATION_DISABLE
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSData *testDeviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
    userDefaults[kMPDeviceTokenKey] = testDeviceToken;

    MPDevice *device = [[MPDevice alloc] initWithStateMachine:[MParticle sharedInstance].stateMachine userDefaults:[MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity] identity:[MParticle sharedInstance].identity];
    NSDictionary *testDictionary = device.dictionaryRepresentation;
    XCTAssertEqualObjects(testDictionary[@"dll"], @"en");
    XCTAssertEqualObjects(testDictionary[@"dlc"], @"US");
    XCTAssertEqualObjects(testDictionary[@"dma"], @"Apple");
    XCTAssertEqualObjects(testDictionary[kMPDeviceTokenKey], @"3c3030303030303030303030303030303030303030303030303030303030303e");
#endif
}

@end
