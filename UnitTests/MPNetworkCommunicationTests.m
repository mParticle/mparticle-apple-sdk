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
#import "mParticle.h"
#import "MPPersistenceController.h"

@interface MParticle ()

@property (nonatomic, strong) MPPersistenceController *persistenceController;
@property (nonatomic, strong, readwrite) MPNetworkOptions *networkOptions;

@end

@interface MPNetworkCommunication ()

- (NSNumber *)maxAgeForCache:(nonnull NSString *)cache;
- (BOOL)performMessageUpload:(MPUpload *)upload;
- (BOOL)performAliasUpload:(MPUpload *)upload;

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
    XCTAssert(![configURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testConfigURLWithOptions {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.configHost = @"config.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    [self deswizzle];
    
    XCTAssert([configURL.absoluteString rangeOfString:@"config.mpproxy.example.com/v4/"].location != NSNotFound);
    XCTAssert(![configURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testConfigURLWithOptionsAndOverride {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.configHost = @"config.mpproxy.example.com";
    options.overridesConfigSubdirectory = true;
    [MParticle sharedInstance].networkOptions = options;
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *configURL = [networkCommunication configURL];
    
    [self deswizzle];
    
    XCTAssert([configURL.absoluteString rangeOfString:@"config.mpproxy.example.com"].location != NSNotFound);
    XCTAssert([configURL.absoluteString rangeOfString:@"v4"].location == NSNotFound);
    XCTAssert(![configURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testModifyURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *modifyURL = [networkCommunication modifyURL];
    
    [self deswizzle];
    
    XCTAssert([modifyURL.absoluteString rangeOfString:@"https://identity.mparticle.com/v1/0/modify"].location != NSNotFound);
    XCTAssert([modifyURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testModifyURLWithOptions {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.identityHost = @"identity.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *modifyURL = [networkCommunication modifyURL];
    
    [self deswizzle];
    
    XCTAssert([modifyURL.absoluteString rangeOfString:@"https://identity.mpproxy.example.com/v1/0/modify"].location != NSNotFound);
    XCTAssert([modifyURL.accessibilityHint isEqualToString:@"identity"]);
}


- (void)testAliasURL {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *aliasURL = [networkCommunication aliasURL];
    
    [self deswizzle];
    
    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://nativesdks.mparticle.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptions {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    [MParticle sharedInstance].networkOptions = options;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *aliasURL = [networkCommunication aliasURL];
    
    [self deswizzle];
    
    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://events.mpproxy.example.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndOverride {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.overridesEventsSubdirectory = true;
    [MParticle sharedInstance].networkOptions = options;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *aliasURL = [networkCommunication aliasURL];
    
    [self deswizzle];
    
    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://events.mpproxy.example.com/"].location != NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"v1"].location == NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"identity"].location == NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithEventsOnly {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *aliasURL = [networkCommunication aliasURL];
    
    [self deswizzle];
    
    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://nativesdks.mparticle.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndEventsOnly {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.aliasHost = @"alias.mpproxy.example.com";
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *aliasURL = [networkCommunication aliasURL];
    
    [self deswizzle];
    
    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://alias.mpproxy.example.com/v1/identity/"].location != NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
}

- (void)testAliasURLWithOptionsAndOverrideAndEventsOnly {
    [self swizzleInstanceMethodForInstancesOfClass:[NSBundle class] selector:@selector(infoDictionary)];
    MPNetworkOptions *options = [[MPNetworkOptions alloc] init];
    options.eventsHost = @"events.mpproxy.example.com";
    options.aliasHost = @"alias.mpproxy.example.com";
    options.overridesAliasSubdirectory = true;
    options.eventsOnly = true;
    [MParticle sharedInstance].networkOptions = options;
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    NSURL *aliasURL = [networkCommunication aliasURL];
    
    [self deswizzle];
    
    XCTAssert([aliasURL.absoluteString rangeOfString:@"https://alias.mpproxy.example.com/"].location != NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"v1"].location == NSNotFound);
    XCTAssert([aliasURL.absoluteString rangeOfString:@"identity"].location == NSNotFound);
    XCTAssert([aliasURL.accessibilityHint isEqualToString:@"identity"]);
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
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    NSArray *uploads = @[upload];
    id mockZip = OCMClassMock([MPZip class]);
    OCMStub([mockZip compressedDataFromData:OCMOCK_ANY]).andReturn(nil);
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testShouldStopEvents {
    [self shouldStopEvents:0 shouldStop:YES];
    [self shouldStopEvents:999 shouldStop:YES];
    [self shouldStopEvents:-999 shouldStop:YES];
    [self shouldStopEvents:-1 shouldStop:YES];
    [self shouldStopEvents:200 shouldStop:NO];
    [self shouldStopEvents:201 shouldStop:NO];
    [self shouldStopEvents:202 shouldStop:NO];
    [self shouldStopEvents:400 shouldStop:NO];
    [self shouldStopEvents:401 shouldStop:NO];
    [self shouldStopEvents:429 shouldStop:YES];
    [self shouldStopEvents:500 shouldStop:YES];
    [self shouldStopEvents:503 shouldStop:YES];
}

- (void)shouldStopEvents:(int)returnCode shouldStop:(BOOL)shouldStop {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(returnCode)] statusCode];
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;
    
    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];
    
    MPUpload *messageUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    
    BOOL actualShouldStop = [networkCommunication performMessageUpload:messageUpload];
    XCTAssertEqual(shouldStop, actualShouldStop, @"Return code assertion: %d", returnCode);
    [urlResponseMock stopMocking];
    [mockConnector stopMocking];
    [mockNetworkCommunication stopMocking];
}

- (void)testShouldStopAlias {
    [self shouldStopAlias:0 shouldStop:YES];
    [self shouldStopAlias:999 shouldStop:YES];
    [self shouldStopAlias:-999 shouldStop:YES];
    [self shouldStopAlias:-1 shouldStop:YES];
    [self shouldStopAlias:200 shouldStop:NO];
    [self shouldStopAlias:201 shouldStop:NO];
    [self shouldStopAlias:202 shouldStop:NO];
    [self shouldStopAlias:400 shouldStop:NO];
    [self shouldStopAlias:401 shouldStop:NO];
    [self shouldStopAlias:429 shouldStop:YES];
    [self shouldStopAlias:500 shouldStop:YES];
    [self shouldStopAlias:503 shouldStop:YES];
}
    
- (void)shouldStopAlias:(int)returnCode shouldStop:(BOOL)shouldStop {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(returnCode)] statusCode];
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;
    
    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];
    
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    aliasUpload.uploadType = MPUploadTypeAlias;
    
    BOOL actualShouldStop = [networkCommunication performAliasUpload:aliasUpload];
    XCTAssertEqual(shouldStop, actualShouldStop, @"Return code assertion: %d", returnCode);
    [urlResponseMock stopMocking];
    [mockConnector stopMocking];
    [mockNetworkCommunication stopMocking];
}

- (void)testOfflineUpload {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(0)] statusCode];
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;
    
    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];
    
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    [[mockPersistenceController reject] deleteUpload:OCMOCK_ANY];
    
    MParticle *instance = [MParticle sharedInstance];
    instance.persistenceController = mockPersistenceController;
    
    MPUpload *eventUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    aliasUpload.uploadType = MPUploadTypeAlias;
    
    NSArray *uploads = @[eventUpload, aliasUpload];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [urlResponseMock stopMocking];
    [mockConnector stopMocking];
    [mockNetworkCommunication stopMocking];
    [mockPersistenceController stopMocking];
}

- (void)testUploadSuccessDeletion {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(202)] statusCode];
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;
    
    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];
    
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    
    MPUpload *eventUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    aliasUpload.uploadType = MPUploadTypeAlias;
    
    [[mockPersistenceController expect] deleteUpload:eventUpload];
    [[mockPersistenceController expect] deleteUpload:aliasUpload];
    
    MParticle *instance = [MParticle sharedInstance];
    instance.persistenceController = mockPersistenceController;
    
    NSArray *uploads = @[eventUpload, aliasUpload];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [urlResponseMock stopMocking];
    [mockConnector stopMocking];
    [mockNetworkCommunication stopMocking];
    [mockPersistenceController stopMocking];
}

- (void)testUploadInvalidDeletion {
    id urlResponseMock = OCMClassMock([NSHTTPURLResponse class]);
    [[[urlResponseMock stub] andReturnValue:OCMOCK_VALUE(400)] statusCode];
    
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];
    response.httpResponse = urlResponseMock;
    
    id mockConnector = OCMClassMock([MPConnector class]);
    [[[mockConnector stub] andReturn:response] responseFromPostRequestToURL:OCMOCK_ANY message:OCMOCK_ANY serializedParams:OCMOCK_ANY];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    id mockNetworkCommunication = OCMPartialMock(networkCommunication);
    [[[mockNetworkCommunication stub] andReturn:mockConnector] makeConnector];
    
    id mockPersistenceController = OCMClassMock([MPPersistenceController class]);
    
    MPUpload *eventUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    MPUpload *aliasUpload = [[MPUpload alloc] initWithSessionId:@1 uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1)];
    aliasUpload.uploadType = MPUploadTypeAlias;
    
    [[mockPersistenceController expect] deleteUpload:eventUpload];
    [[mockPersistenceController expect] deleteUpload:aliasUpload];
    
    MParticle *instance = [MParticle sharedInstance];
    instance.persistenceController = mockPersistenceController;
    
    NSArray *uploads = @[eventUpload, aliasUpload];
    XCTestExpectation *expectation = [self expectationWithDescription:@"async work"];
    [networkCommunication upload:uploads completionHandler:^{
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:1 handler:nil];
    [urlResponseMock stopMocking];
    [mockConnector stopMocking];
    [mockNetworkCommunication stopMocking];
    [mockPersistenceController stopMocking];
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
