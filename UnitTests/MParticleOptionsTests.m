#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPIConstants.h"

@interface MParticleOptionsTests : MPBaseTestCase

@property (nonatomic) MParticleOptions *options;

@end

@implementation MParticleOptionsTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    _options = nil;
    [super tearDown];
}

- (void)testNoArgInit {
    _options = [[MParticleOptions alloc] init];
    XCTAssertNotNil(_options, @"Expected no-arg init to produce a non-nil options object");
}

- (void)testKeySecretInit {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    
    XCTAssertNotNil(_options, @"Expected optionsWithKey to produce a non-nil options object");
    
    XCTAssertEqualObjects(_options.apiKey, @"unit_test_app_key", @"Expected key to match the one passed in");
    XCTAssertEqualObjects(_options.apiSecret, @"unit_test_secret", @"Expected secret to match the one passed in");
}

- (void)testDisableProxyAppDelegate {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertTrue(_options.proxyAppDelegate, @"Expected proxy AppDelegate to default to YES");
    
    _options.proxyAppDelegate = NO;
    XCTAssertFalse(_options.proxyAppDelegate, @"Expected proxy AppDelegate to be NO after setting to NO");
}

- (void)testDisableAutoSessionTracking {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertTrue(_options.automaticSessionTracking, @"Expected auto session tracking to default to YES");
    
    _options.automaticSessionTracking = NO;
    XCTAssertFalse(_options.automaticSessionTracking, @"Expected auto session tracking to be NO after setting to NO");
}

- (void)testLogLevel {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    
    XCTAssertEqual(_options.logLevel, MPILogLevelNone, @"Default Debug Level was incorrect");
}

- (void)testSetLogLevel {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    _options.logLevel = MPILogLevelDebug;
    
    XCTAssertEqual(_options.logLevel, MPILogLevelDebug, @"Debug Level was was not set correctly");
}

- (void)testSetSearchAdsAttributionDefault {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    
    XCTAssertFalse(_options.collectSearchAdsAttribution, @"Search ads attribution shouldn't be collected by default");
}

- (void)testSetSearchAdsAttributionSet {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    _options.collectSearchAdsAttribution = YES;
    
    XCTAssertTrue(_options.collectSearchAdsAttribution, @"Search ads attribution was not set correctly");
}

- (void)testSetSearchAdsAttributionReset {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    _options.collectSearchAdsAttribution = NO;
    
    _options.collectSearchAdsAttribution = YES;
    XCTAssertTrue(_options.collectSearchAdsAttribution, @"Search ads attribution was not set correctly");
}

- (void)testSessionTimeout {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertEqual(_options.sessionTimeout, DEFAULT_SESSION_TIMEOUT, @"Session Timeout Interval default correct");
    
    _options.sessionTimeout = 100.0;
    XCTAssertEqual(_options.sessionTimeout, 100.0, @"Session Timeout Interval set correctly");
}

- (void)testDataBlockOptions {
    _options = [MParticleOptions optionsWithKey:@"unit_test_app_key" secret:@"unit_test_secret"];
    XCTAssertNil(_options.dataPlanOptions.dataPlan);
    XCTAssertFalse(_options.dataPlanOptions.blockEvents);
    XCTAssertFalse(_options.dataPlanOptions.blockEventAttributes);
    XCTAssertFalse(_options.dataPlanOptions.blockUserAttributes);
    XCTAssertFalse(_options.dataPlanOptions.blockUserIdentities);
    
    _options.dataPlanOptions = [[MPDataPlanOptions alloc] init];
    _options.dataPlanOptions.dataPlan = @{};
    _options.dataPlanOptions.blockEvents = YES;
    _options.dataPlanOptions.blockEventAttributes = YES;
    _options.dataPlanOptions.blockUserAttributes = YES;
    _options.dataPlanOptions.blockUserIdentities = YES;
    XCTAssertNotNil(_options.dataPlanOptions.dataPlan);
    XCTAssertTrue(_options.dataPlanOptions.blockEvents);
    XCTAssertTrue(_options.dataPlanOptions.blockEventAttributes);
    XCTAssertTrue(_options.dataPlanOptions.blockUserAttributes);
    XCTAssertTrue(_options.dataPlanOptions.blockUserIdentities);
}

@end
