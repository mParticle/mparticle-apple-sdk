#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPIConstants.h"

@interface MParticleOptionsTests : MPBaseTestCase

@end

@implementation MParticleOptionsTests


- (void)testNoArgInit {
    MParticleOptions *options = [[MParticleOptions alloc] init];
    XCTAssertNotNil(options, @"Expected no-arg init to produce a non-nil options object");
}

- (void)testKeySecretInit {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    
    XCTAssertNotNil(options, @"Expected optionsWithKey to produce a non-nil options object");
    
    XCTAssertEqualObjects(options.apiKey, @"unit_test_app_key", @"Expected key to match the one passed in");
    XCTAssertEqualObjects(options.apiSecret, @"unit_test_secret", @"Expected secret to match the one passed in");
}

- (void)testDisableProxyAppDelegate {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertTrue(options.proxyAppDelegate, @"Expected proxy AppDelegate to default to YES");
    
    options.proxyAppDelegate = NO;
    XCTAssertFalse(options.proxyAppDelegate, @"Expected proxy AppDelegate to be NO after setting to NO");
}

- (void)testDisableAutoSessionTracking {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertTrue(options.automaticSessionTracking, @"Expected auto session tracking to default to YES");
    
    options.automaticSessionTracking = NO;
    XCTAssertFalse(options.automaticSessionTracking, @"Expected auto session tracking to be NO after setting to NO");
}

- (void)testLogLevel {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    
    XCTAssertEqual(options.logLevel, MPILogLevelNone, @"Default Debug Level was incorrect");
}

- (void)testSetLogLevel {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    options.logLevel = MPILogLevelDebug;
    
    XCTAssertEqual(options.logLevel, MPILogLevelDebug, @"Debug Level was was not set correctly");
}

- (void)testSetSearchAdsAttributionDefault {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    
    XCTAssertFalse(options.collectSearchAdsAttribution, @"Search ads attribution shouldn't be collected by default");
}

- (void)testSetSearchAdsAttributionSet {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    options.collectSearchAdsAttribution = YES;
    
    XCTAssertTrue(options.collectSearchAdsAttribution, @"Search ads attribution was not set correctly");
}

- (void)testSetSearchAdsAttributionReset {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    options.collectSearchAdsAttribution = NO;
    
    options.collectSearchAdsAttribution = YES;
    XCTAssertTrue(options.collectSearchAdsAttribution, @"Search ads attribution was not set correctly");
}

- (void)testSessionTimeout {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertEqual(options.sessionTimeout, DEFAULT_SESSION_TIMEOUT, @"Session Timeout Interval default correct");
    
    options.sessionTimeout = 100.0;
    XCTAssertEqual(options.sessionTimeout, 100.0, @"Session Timeout Interval set correctly");
}

- (void)testDataBlockOptions {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertNil(options.dataPlanOptions.dataPlan);
    XCTAssertFalse(options.dataPlanOptions.blockEvents);
    XCTAssertFalse(options.dataPlanOptions.blockEventAttributes);
    XCTAssertFalse(options.dataPlanOptions.blockUserAttributes);
    XCTAssertFalse(options.dataPlanOptions.blockUserIdentities);
    
    options.dataPlanOptions = [[MPDataPlanOptions alloc] init];
    options.dataPlanOptions.dataPlan = @{};
    options.dataPlanOptions.blockEvents = YES;
    options.dataPlanOptions.blockEventAttributes = YES;
    options.dataPlanOptions.blockUserAttributes = YES;
    options.dataPlanOptions.blockUserIdentities = YES;
    XCTAssertNotNil(options.dataPlanOptions.dataPlan);
    XCTAssertTrue(options.dataPlanOptions.blockEvents);
    XCTAssertTrue(options.dataPlanOptions.blockEventAttributes);
    XCTAssertTrue(options.dataPlanOptions.blockUserAttributes);
    XCTAssertTrue(options.dataPlanOptions.blockUserIdentities);
}

@end
