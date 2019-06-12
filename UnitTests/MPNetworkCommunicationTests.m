#import <XCTest/XCTest.h>
#import <Foundation/Foundation.h>
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPApplication.h"
#import "OCMock.h"
#import "MPUpload.h"
#import "MPZip.h"
#import "MPConnector.h"
#import "MPIUserDefaults.h"
#import "MPBaseTestCase.h"

@interface MPNetworkCommunication ()

- (NSNumber *)maxAgeForCache:(nonnull NSString *)cache;

@end

@interface MPNetworkCommunicationTests : MPBaseTestCase

@end

Method originalMethod = nil; Method swizzleMethod = nil;

@implementation MPNetworkCommunicationTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {    
    [super tearDown];
}

- (void) swizzleInstanceMethodForInstancesOfClass:(Class)targetClass selector:(SEL)selector
{
    originalMethod = class_getInstanceMethod(targetClass, selector);
    swizzleMethod = class_getInstanceMethod([self class], selector);
    method_exchangeImplementations(originalMethod, swizzleMethod);
}

- (void) deswizzle
{
    method_exchangeImplementations(swizzleMethod, originalMethod);
    swizzleMethod = nil;
    originalMethod = nil;
}

- (NSDictionary *)infoDictionary {
    return @{@"CFBundleShortVersionString":@"1.2.3.4.5678 (bd12345ff)"};
}

- (void)testConfigURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    [self deswizzle];
    
    XCTAssert([configURL.absoluteString rangeOfString:@"/config?av=1.2.3.4.5678%20(bd12345ff)"].location != NSNotFound);
}

- (void)testEmptyUploadsArray {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSArray *uploads = @[];
    __block BOOL handlerCalled = NO;
    [networkCommunication upload:uploads completionHandler:^{
        handlerCalled = YES;
    }];
    XCTAssertTrue(handlerCalled, @"Callbacks are expected in the case where uploads array is empty");
}

- (void)testUploadsArrayZipFail {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{}];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip class]);
    OCMStub([mockZip compressedDataFromData:OCMOCK_ANY]).andReturn(nil);
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestConfigWithDefaultMaxAge {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSNumber *configProvisioned = userDefaults[kMPConfigProvisionedTimestampKey];
    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeKey];
    
    XCTAssertEqualObjects(configProvisioned, nil);
    XCTAssertEqualObjects(maxAge, nil);
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);
    
    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    
    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:OCMOCK_ANY];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];
    
    configProvisioned = userDefaults[kMPConfigProvisionedTimestampKey];
    maxAge = userDefaults[kMPConfigMaxAgeKey];
    
    XCTAssertNotNil(configProvisioned);
    XCTAssertNil(maxAge);
    
    [mockConnector stopMocking];
}

- (void)testRequestConfigWithManualMaxAge {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPConfigProvisionedTimestampKey] = @5555;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];

    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);
    
    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"max-age=43200"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    
    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:OCMOCK_ANY];

    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];
    
    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeKey];

    XCTAssertEqualObjects(maxAge, @43200);

    [mockConnector stopMocking];
}

- (void)testRequestConfigWithManualMaxAgeAndInitialAge {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);
    
    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"age": @"4000",
                                                          kMPMessageTypeKey:kMPMessageTypeConfig,
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"max-age=43200"
                                                          };
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];

    
    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:OCMOCK_ANY];
    
    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];
    
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    
    NSNumber *provisionedInterval = userDefaults[kMPConfigProvisionedTimestampKey];
    int approximateAge = ([[NSDate date] timeIntervalSince1970] - [provisionedInterval integerValue]);
    
    XCTAssertLessThanOrEqual(4000, approximateAge);
    XCTAssertLessThan(approximateAge, 4200);

    [mockConnector stopMocking];
}

- (void)testRequestConfigWithManualMaxAgeOverMaxAllowed {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPConfigProvisionedTimestampKey] = @5555;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);
    
    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPMessageTypeKey:kMPMessageTypeConfig,
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"max-age=172800"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    
    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:OCMOCK_ANY];
    
    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];
    
    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeKey];
    NSNumber *maxExpiration = @(60*60*24.0);
    
    XCTAssertEqualObjects(maxAge, maxExpiration);
    
    [mockConnector stopMocking];
}

- (void)testRequestConfigWithComplexCacheControlHeader {
    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    userDefaults[kMPConfigProvisionedTimestampKey] = @5555;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    MPConnector *connector = [[MPConnector alloc] init];
    id mockConnector = OCMPartialMock(connector);
    
    NSDictionary<NSString *, NSString *> *httpHeaders = @{@"Age": @"0",
                                                          kMPMessageTypeKey:kMPMessageTypeConfig,
                                                          kMPHTTPETagHeaderKey: @"242f22f24c224",
                                                          kMPHTTPCacheControlHeaderKey: @"min-fresh=0, max-age=43200, no-transform"
                                                          };
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appId":@"cool app key"
                                             }
                                     };
    
    NSDictionary *configuration2 = @{
                                     @"id":@312,
                                     @"as":@{
                                             @"appId":@"cool app key 2"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1, configuration2];
    
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPMessageTypeKey:kMPMessageTypeConfig,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    NSError *error;
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:configURL statusCode:HTTPStatusCodeSuccess HTTPVersion:@"" headerFields:httpHeaders];
    response.httpResponse = httpResponse;
    response.data = [NSJSONSerialization dataWithJSONObject:responseConfiguration
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    
    [[[mockConnector stub] andReturn:response] responseFromGetRequestToURL:OCMOCK_ANY];
    
    [networkCommunication requestConfig:mockConnector withCompletionHandler:^(BOOL success) {
        XCTAssert(success);
    }];
    
    NSNumber *maxAge = userDefaults[kMPConfigMaxAgeKey];
    
    XCTAssertEqualObjects(maxAge, @43200);
    
    [mockConnector stopMocking];
}

- (void)testMaxAgeForCacheEmptyString {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];

    NSString *test1 = @"";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test1], nil);
}

- (void)testMaxAgeForCacheSimple {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    NSString *test2 = @"max-age=12";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test2], @12);
}

- (void)testMaxAgeForCacheMultiValue1 {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    NSString *test3 = @"max-age=13, max-stale=7";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test3], @13);
}

- (void)testMaxAgeForCacheMultiValue2 {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    NSString *test4 = @"max-stale=34, max-age=14";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test4], @14);
}

- (void)testMaxAgeForCacheMultiValue3 {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    NSString *test4 = @"max-stale=33434344, max-age=15, min-fresh=3553553";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test4], @15);
}

- (void)testMaxAgeForCacheCapitalization {
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    NSString *test5 = @"max-stale=34, MAX-age=16, min-fresh=3553553";
    XCTAssertEqualObjects([networkCommunication maxAgeForCache:test5], @16);
}

@end
