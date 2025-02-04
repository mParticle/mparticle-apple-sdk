#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "MPDevice.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MParticleSwift.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPDeviceTests : XCTestCase

@end

@implementation MPDeviceTests

- (void)testTelephonyRadioAccessTechnology {
#if TARGET_OS_IOS == 1
    CTTelephonyNetworkInfo *mockTelephonyNetworkInfo = OCMPartialMock([[CTTelephonyNetworkInfo alloc] init]);
    [[[(id)mockTelephonyNetworkInfo stub] andReturn:@"foo"] currentRadioAccessTechnology];
    MPDevice *device = [[MPDevice alloc] init];
    [device setValue:mockTelephonyNetworkInfo forKey:@"telephonyNetworkInfo"];
    NSString *technology = device.radioAccessTechnology;
    XCTAssertEqualObjects(technology, @"None");
#endif
}

- (void)testDictionaryDescription {
#if TARGET_OS_IOS == 1
    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSData *testDeviceToken = [@"<000000000000000000000000000000>" dataUsingEncoding:NSUTF8StringEncoding];
    userDefaults[kMPDeviceTokenKey] = testDeviceToken;

    MPDevice *device = [[MPDevice alloc] init];
    NSDictionary *testDictionary = device.dictionaryRepresentation;
    XCTAssertEqualObjects(testDictionary[@"dll"], @"en");
    XCTAssertEqualObjects(testDictionary[@"dlc"], @"US");
    XCTAssertEqualObjects(testDictionary[@"dma"], @"Apple");
    XCTAssertEqualObjects(testDictionary[kMPDeviceTokenKey], @"3c3030303030303030303030303030303030303030303030303030303030303e");
#endif
}

@end
