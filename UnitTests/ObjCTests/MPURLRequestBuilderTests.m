#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPURLRequestBuilder.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPConsumerInfo.h"
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPKitRegister.h"
#import "MPKitContainer.h"
#import "MPKitTestClass.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPBaseTestCase.h"
#import "MPKitConfiguration.h"
#import "MPExtensionProtocol.h"
#import "MPURL.h"
#import "MPUpload.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;


@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;
@property (nonatomic, strong) MParticleWebViewPRIVATE *webView;

@end

#pragma mark - MPURLRequestBuilder category
@interface MPURLRequestBuilder(Tests)

- (NSString *)hmacSha256Encode:(NSString *const)message key:(NSString *const)key;
- (NSString *)userAgent;
- (void)setUserAgent:(NSString *const)userAgent;
- (NSString *)fallbackUserAgent;
- (NSString *)stringByStrippingPathComponent:(NSString *)path;
- (NSString *)signatureRelativePath:(NSString *)relativePath url:(NSURL *)url;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer_PRIVATE(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;

@end

#pragma mark - MPURLRequestBuilderTests
@interface MPURLRequestBuilderTests : MPBaseTestCase {
    MPKitContainer_PRIVATE *kitContainer;
}

@end

@implementation MPURLRequestBuilderTests

- (void)setUp {
    [super setUp];
    
    [MPPersistenceController_PRIVATE setMpid:@12];

    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";

    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    kitContainer = [MParticle sharedInstance].kitContainer_PRIVATE;

    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer_PRIVATE registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];

        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];

        kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
        [MPKitContainer_PRIVATE registerKit:kitRegister];

        NSDictionary *configuration = @{
                                        @"id":@42,
                                        @"as":@{
                                                @"appId":@"MyAppId"
                                                }
                                        };

        MPKitConfiguration *kitConfiguration = [[MPKitConfiguration alloc] initWithDictionary:configuration];
        [kitContainer startKit:@42 configuration:kitConfiguration];
    }
}

- (void)tearDown {
    kitContainer = nil;
    [super tearDown];
}

- (void)testCustomUserAgent {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"testKey" secret:@"testSecret"];
    options.customUserAgent = @"Test User Agent";
    [[MParticle sharedInstance] startWithOptions:options];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"User-Agent"];
    
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:nil messageType:@"e" messageInfo:@{@"key":@"value"} uploadStatus:MPUploadStatusBatch UUID:[[NSUUID UUID] UUIDString] timestamp:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId] dataPlanId:@"test" dataPlanVersion:@(1)];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURLForUpload:upload]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    
    dispatch_async([MParticle messageQueue], ^{
        NSString *userAgent = [urlRequestBuilder userAgent];
        XCTAssertNotNil(userAgent, @"Should not have been nil.");
        XCTAssertTrue([userAgent isEqualToString:@"Test User Agent"], @"User Agent has an invalid value: %@", userAgent);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testDisableCollectUserAgent {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"testKey" secret:@"testSecret"];
    options.customUserAgent = nil;
    options.collectUserAgent = NO;
    [[MParticle sharedInstance] startWithOptions:options];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"User-Agent"];
    
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:nil messageType:@"e" messageInfo:@{@"key":@"value"} uploadStatus:MPUploadStatusBatch UUID:[[NSUUID UUID] UUIDString] timestamp:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId] dataPlanId:@"test" dataPlanVersion:@(1)];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURLForUpload:upload]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    
    dispatch_async([MParticle messageQueue], ^{
        NSString *userAgent = [urlRequestBuilder userAgent];
        XCTAssertNotNil(userAgent, @"Should not have been nil.");
        
        NSString *defaultUserAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
        XCTAssertTrue([userAgent isEqualToString:defaultUserAgent], @"User Agent has an invalid value: %@", userAgent);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:DEFAULT_TIMEOUT handler:nil];
}

- (void)testHMACSha256Encode {
    NSURL *baseURL = [NSURL URLWithString:@"http://mparticle.com"];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL]];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *message = @"The Quick Brown Fox Jumps Over The Lazy Dog.";
    NSString *referenceEncodedMessage = @"ceefdfeab2fe404a7cbb75f6f6a01443286fab507eb85c213fce3d812e8b615c";
    NSString *encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    
    XCTAssertEqualObjects(encodedMessage, referenceEncodedMessage, @"HMAC Sha 256 is failing to encode correctly.");
}

- (void)testInvalidHMACSha256Encode {
    NSURL *baseURL = [NSURL URLWithString:@"http://mparticle.com"];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL]];
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *message = nil;
    NSString *encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    XCTAssertNil(encodedMessage, @"Should not have tried to encode a nil message.");
    
    message = @"";
    encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    XCTAssertNotNil(encodedMessage, @"Encoded message should not have been nil.");
    
    message = @"The Quick Brown Fox Jumps Over The Lazy Dog.";
    encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:nil];
    XCTAssertNil(encodedMessage, @"Should not have tried to encode with a nil key.");
}

- (void)testURLRequestComposition {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];

    NSMutableArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-env", @"x-mp-kits"].mutableCopy;
    
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        } else if ([header isEqualToString:@"Content-Type"]) {
            BOOL validContentType = [headerValue isEqualToString:@"application/x-www-form-urlencoded"];
            
            XCTAssertTrue(validContentType, @"%@ http header is invalid: %@", header, headerValue);
        } else if ([header isEqualToString:@"secondsFromGMT"] || [header isEqualToString:@"x-mp-signature"]) {
            XCTAssert([headerValue length] > 0, @"%@ has invalid length", header);
        } else if ([header isEqualToString:@"x-mp-env"]) {
            BOOL validEnvironment = [headerValue isEqualToString:[@(MPEnvironmentDevelopment) stringValue]] ||
            [headerValue isEqualToString:[@(MPEnvironmentProduction) stringValue]];
            
            XCTAssertTrue(validEnvironment, @"Invalid environment value: %@", headerValue);
        } else if ([header isEqualToString:@"x-mp-kits"]) {
            NSRange kitRange = [headerValue rangeOfString:@"42"];
            XCTAssertTrue(kitRange.location != NSNotFound);
            
            kitRange = [headerValue rangeOfString:@"314"];
            XCTAssertTrue(kitRange.location != NSNotFound);
        } else if ([header isEqualToString:@"User-Agent"]) {
            NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
            XCTAssertEqualObjects(headerValue, defaultAgent);
        }
    }
}

- (void)testEtag {
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
    
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *responseConfiguration = @{kMPRemoteConfigKitsKey:kitConfigs,
                                            kMPRemoteConfigRampKey:@100,
                                            kMPRemoteConfigExceptionHandlingModeKey:kMPRemoteConfigExceptionHandlingModeForce,
                                            kMPRemoteConfigSessionTimeoutKey:@112};
    
    NSTimeInterval requestTimestamp = [[NSDate date] timeIntervalSince1970];
    [MPUserDefaultsConnector.userDefaults setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:0 maxAge:nil];

    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];

    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSArray *headers = @[@"If-None-Match", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-env", @"x-mp-kits"];
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        } else if ([header isEqualToString:@"Content-Type"]) {
            BOOL validContentType = [headerValue isEqualToString:@"application/x-www-form-urlencoded"];
            
            XCTAssertTrue(validContentType, @"%@ http header is invalid: %@", header, headerValue);
        } else if ([header isEqualToString:@"secondsFromGMT"] || [header isEqualToString:@"x-mp-signature"]) {
            XCTAssert([headerValue length] > 0, @"%@ has invalid length", header);
        } else if ([header isEqualToString:@"x-mp-env"]) {
            BOOL validEnvironment = [headerValue isEqualToString:[@(MPEnvironmentDevelopment) stringValue]] ||
            [headerValue isEqualToString:[@(MPEnvironmentProduction) stringValue]];
            
            XCTAssertTrue(validEnvironment, @"Invalid environment value: %@", headerValue);
        } else if ([header isEqualToString:@"x-mp-kits"]) {
            NSRange kitRange = [headerValue rangeOfString:@"42"];
            XCTAssertTrue(kitRange.location != NSNotFound);
            
            kitRange = [headerValue rangeOfString:@"314"];
            XCTAssertTrue(kitRange.location != NSNotFound);
        } else if ([header isEqualToString:@"If-None-Match"]) {
            XCTAssertEqualObjects(headerValue, @"1.618-2.718-3.141-42");
        }
    }
}

- (void)testComposingWithHeaderData {
    NSURL *baseURL = [NSURL URLWithString:@"http://mparticle.com"];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL]];
    
    NSString *userAgent = [NSString stringWithFormat:@"UnitTests/1.0 (iPhone; CPU iPhone OS like Mac OS X) (KHTML, like Gecko) mParticle/%@", kMParticleSDKVersion];
    
    NSDictionary *headersDictionary = @{@"User-Agent":userAgent,
                                        @"Accept-Encoding":@"gzip",
                                        @"Content-Encoding":@"gzip"};
    
    NSError *error = nil;
    NSData *headerData = [NSJSONSerialization dataWithJSONObject:headersDictionary options:0 error:&error];
    
    XCTAssertNil(error, @"Error serializing http header.");
    
    [urlRequestBuilder withHeaderData:headerData];
    
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding"];
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"User-Agent"]) {
            XCTAssertEqualObjects(headerValue, userAgent, @"User-Agent is not being set correctly.");
        } else if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        }
    }
}

- (void)testPOSTURLRequest {
    NSURL *baseURL = [NSURL URLWithString:@"http://mparticle.com"];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL]];
    
    [urlRequestBuilder withHttpMethod:@"POST"];
    
    NSDictionary *postDictionary = @{@"key1":@"value1",
                                     @"arrayKey":@[@"item1", @"item2"],
                                     @"key2":@2,
                                     @"key3":@{@"nestedKey":@"nestedValue"}
                                     };
    
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postDictionary options:0 error:&error];
    
    XCTAssertNil(error, @"Error serializing POST data.");
    
    [urlRequestBuilder withPostData:postData];
    
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    XCTAssertEqualObjects([asyncURLRequest HTTPMethod], @"POST", @"HTTP method is not being set to POST.");
    
    XCTAssertEqualObjects(postData, [asyncURLRequest HTTPBody], @"HTTP body is not being set as the post data.");
}

- (void)testInvalidURLs {
    NSURL *baseURL = nil;
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL]];
    
    XCTAssertNil(urlRequestBuilder, @"Retuning a request builder from an invalid URL.");
    
    urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL] message:nil httpMethod:@"GET"];
    
    XCTAssertNil(urlRequestBuilder, @"Retuning a request builder from an invalid URL.");
    
    baseURL = [NSURL URLWithString:@"http://mparticle.com"];
    urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[[MPURL alloc] initWithURL:baseURL defaultURL:baseURL]];
    
    XCTAssertEqualObjects(urlRequestBuilder.httpMethod, @"GET", @"HTTP method is assuming GET as default.");
}

- (void)testEventRequest {
    MParticle *sharedInstance = [MParticle sharedInstance];
    MParticleWebViewPRIVATE *webview = sharedInstance.webView;
    NSString *agent = @"Example resolved agent";
    
    id mockWebView = OCMPartialMock(webview);
    [[[mockWebView stub] andReturn:agent] userAgent];
    
    id mockKitContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    NSNumber *mockKitId = @42;
    [[[mockKitContainer stub] andReturn:@[mockKitId]] configuredKitsRegistry];
    
    id mockMParticle = OCMPartialMock(sharedInstance);
    [[[mockMParticle stub] andReturn:mockWebView] webView];
    [[[mockMParticle stub] andReturn:mockKitContainer] kitContainer_PRIVATE];
    
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appKey":@"unique key"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1];
    [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:nil];
    [[MParticle sharedInstance].kitContainer_PRIVATE configureKits:kitConfigs];
    
    XCTAssertEqual([MPURLRequestBuilder requestTimeout], 10, @"Should have been equal.");
    
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:nil messageType:@"e" messageInfo:@{@"key":@"value"} uploadStatus:MPUploadStatusBatch UUID:[[NSUUID UUID] UUIDString] timestamp:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController_PRIVATE mpId] dataPlanId:@"test" dataPlanVersion:@(1)];
    MPUpload *upload = [[MPUpload alloc] initWithSessionId:nil uploadDictionary:@{} dataPlanId:@"test" dataPlanVersion:@(1) uploadSettings:[MPUploadSettings currentUploadSettingsWithStateMachine:[MParticle sharedInstance].stateMachine networkOptions:[MParticle sharedInstance].networkOptions]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURLForUpload:upload]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];
    NSMutableArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-kits"].mutableCopy;
#if TARGET_OS_IOS != 1
    [headers removeObject:@"User-Agent"];
#endif
    NSString *headerValue;
    
    for (NSString *header in headers) {
        XCTAssertTrue([keys containsObject:header], @"HTTP header %@ is missing", header);
        
        headerValue = headersDictionary[header];
        
        if ([header isEqualToString:@"Accept-Encoding"] || [header isEqualToString:@"Content-Encoding"]) {
            XCTAssertTrue([headerValue isEqualToString:@"gzip"], @"%@ has an invalid value: %@", header, headerValue);
        } else if ([header isEqualToString:@"Content-Type"]) {
            BOOL validContentType = [headerValue isEqualToString:@"application/json"];
            
            XCTAssertTrue(validContentType, @"%@ http header is invalid: %@", header, headerValue);
        } else if ([header isEqualToString:@"secondsFromGMT"] || [header isEqualToString:@"x-mp-signature"]) {
            XCTAssert([headerValue length] > 0, @"%@ has invalid length", header);
        } else if ([header isEqualToString:@"x-mp-kits"]) {
            XCTAssertEqualObjects(headerValue, @"42");
        }
    }
}

- (void)testBuildReturnsNilWhenURLPropertyIsNil {
    NSURL *validURL = [NSURL URLWithString:@"https://config2.mparticle.com/v4/key/config?av=1.0&sv=1.0"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:validURL defaultURL:validURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"GET"];
    XCTAssertNotNil(builder);

    mpURL.url = (NSURL * _Nonnull)nil;

    NSMutableURLRequest *request;
    XCTAssertNoThrow(request = [builder build], @"build should not throw when URL is nil");
    XCTAssertNil(request, @"build should return nil when URL is nil");
}

- (void)testBuildReturnsNilWhenDefaultURLIsNil {
    NSURL *validURL = [NSURL URLWithString:@"https://config2.mparticle.com/v4/key/config?av=1.0&sv=1.0"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:validURL defaultURL:validURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"GET"];
    XCTAssertNotNil(builder);

    mpURL.defaultURL = (NSURL * _Nonnull)nil;

    NSMutableURLRequest *request;
    XCTAssertNoThrow(request = [builder build], @"build should not throw when defaultURL is nil");
    XCTAssertNil(request, @"build should return nil when defaultURL is nil");
}

- (void)testBuildConfigRequestWithQuerylessURL {
    NSURL *noQueryURL = [NSURL URLWithString:@"https://config2.mparticle.com/v4/key/config"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:noQueryURL defaultURL:noQueryURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"GET"];
    XCTAssertNotNil(builder);

    NSMutableURLRequest *request;
    XCTAssertNoThrow(request = [builder build], @"build should not throw for a URL without query parameters");
    XCTAssertNotNil(request);

    NSString *signature = request.allHTTPHeaderFields[@"x-mp-signature"];
    XCTAssertNotNil(signature, @"Signature should still be generated for queryless URL");
    XCTAssertTrue(signature.length > 0);
}

- (void)testDateHeaderIsValidRFC1123 {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *request = [builder build];
    XCTAssertNotNil(request);

    NSString *dateHeader = request.allHTTPHeaderFields[@"Date"];
    XCTAssertNotNil(dateHeader, @"Date header should be present");
    XCTAssertTrue(dateHeader.length > 0, @"Date header should not be empty");

    NSDate *parsedDate = [MPDateFormatter dateFromStringRFC1123:dateHeader];
    XCTAssertNotNil(parsedDate, @"Date header should be parseable as RFC1123 by MPDateFormatter");
}

- (void)testConfigSignatureOmitsQuestionMarkForQuerylessURL {
    NSURL *noQueryURL = [NSURL URLWithString:@"https://config2.mparticle.com/v4/key/config"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:noQueryURL defaultURL:noQueryURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"GET"];
    XCTAssertNotNil(builder);

    __block NSString *capturedSignature = nil;
    id partialMock = OCMPartialMock(builder);
    OCMStub([partialMock hmacSha256Encode:[OCMArg any] key:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSString *sig;
        [invocation getArgument:&sig atIndex:2];
        capturedSignature = sig;
    });

    [builder build];

    XCTAssertNotNil(capturedSignature, @"Signature message should have been captured");
    XCTAssertTrue([capturedSignature rangeOfString:@"(null)"].location == NSNotFound,
                  @"Signature should not contain (null): %@", capturedSignature);
    XCTAssertFalse([capturedSignature hasSuffix:@"?"],
                   @"Signature should not end with a trailing ? for queryless URL: %@", capturedSignature);
}

- (void)testAudienceSignatureOmitsQuestionMarkForQuerylessURL {
    NSURL *audienceURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com/v2/audience"];
    audienceURL.accessibilityHint = @"audience";
    MPURL *mpURL = [[MPURL alloc] initWithURL:audienceURL defaultURL:audienceURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"GET"];
    XCTAssertNotNil(builder);

    __block NSString *capturedSignature = nil;
    id partialMock = OCMPartialMock(builder);
    OCMStub([partialMock hmacSha256Encode:[OCMArg any] key:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        __unsafe_unretained NSString *sig;
        [invocation getArgument:&sig atIndex:2];
        capturedSignature = sig;
    });

    [builder build];

    XCTAssertNotNil(capturedSignature, @"Signature message should have been captured");
    XCTAssertTrue([capturedSignature rangeOfString:@"(null)"].location == NSNotFound,
                  @"Signature should not contain (null): %@", capturedSignature);
    XCTAssertFalse([capturedSignature hasSuffix:@"?"],
                   @"Signature should not end with a trailing ? for queryless URL: %@", capturedSignature);
}

- (void)testBuildReturnsNilForIdentityRequestWithNilPostData {
    NSURL *identityURL = [NSURL URLWithString:@"https://identity.mparticle.com/v1/identify"];
    identityURL.accessibilityHint = @"identity";
    MPURL *mpURL = [[MPURL alloc] initWithURL:identityURL defaultURL:identityURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"POST"];
    XCTAssertNotNil(builder);

    NSMutableURLRequest *request;
    XCTAssertNoThrow(request = [builder build], @"build should not throw for identity request with nil post data");
    XCTAssertNil(request, @"build should return nil for identity request with nil post data");
}

- (void)testSecondsFromGMTHeaderIsValidSignedInteger {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *request = [builder build];
    XCTAssertNotNil(request);

    NSString *secondsHeader = request.allHTTPHeaderFields[@"secondsFromGMT"];
    XCTAssertNotNil(secondsHeader, @"secondsFromGMT header should be present");
    XCTAssertTrue(secondsHeader.length > 0, @"secondsFromGMT header should not be empty");

    NSInteger parsedValue = [secondsHeader integerValue];
    NSString *reformatted = [NSString stringWithFormat:@"%ld", (long)parsedValue];
    XCTAssertEqualObjects(secondsHeader, reformatted,
                          @"secondsFromGMT should be a valid signed integer, got: %@", secondsHeader);

    XCTAssertTrue(parsedValue >= -43200 && parsedValue <= 50400,
                  @"secondsFromGMT should be within valid UTC offset range (-43200 to 50400), got: %ld", (long)parsedValue);
}

- (void)testBuildWithNilSecretProducesRequestWithoutSignature {
    NSURL *validURL = [NSURL URLWithString:@"https://config2.mparticle.com/v4/key/config?av=1.0&sv=1.0"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:validURL defaultURL:validURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:@"GET"];
    XCTAssertNotNil(builder);

    NSString *originalSecret = [MParticle sharedInstance].stateMachine.secret;
    [MParticle sharedInstance].stateMachine.secret = nil;

    NSMutableURLRequest *request;
    XCTAssertNoThrow(request = [builder build], @"build should not throw when secret is nil");
    XCTAssertNotNil(request, @"build should still return a request when secret is nil");

    NSString *signature = request.allHTTPHeaderFields[@"x-mp-signature"];
    XCTAssertNil(signature, @"x-mp-signature should be absent when secret is nil");

    [MParticle sharedInstance].stateMachine.secret = originalSecret;
}

- (void)testSignatureRelativePath {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];
    MPNetworkOptions *networkOptions = [[MPNetworkOptions alloc] init];
    MParticle *sharedInstance = [MParticle sharedInstance];
    id mockMParticle = OCMPartialMock(sharedInstance);
    [[[mockMParticle stub] andReturn:networkOptions] networkOptions];
    
    networkOptions.identityHost = @"identity.mp.example.com";
    networkOptions.overridesIdentitySubdirectory = NO;
    MPURL *baseURL = [networkCommunication modifyURL];
    MPURLRequestBuilder *builder = [MPURLRequestBuilder newBuilderWithURL:baseURL];
    
    NSString *result = builder.url.defaultURL.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.us1.mparticle.com/v1/12/modify");
    result = builder.url.url.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.mp.example.com/v1/12/modify");
    
    networkOptions.identityHost = @"https://example.com";
    networkOptions.overridesIdentitySubdirectory = YES;
    baseURL = [networkCommunication modifyURL];
    builder = [MPURLRequestBuilder newBuilderWithURL:baseURL];
    
    result = builder.url.defaultURL.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.us1.mparticle.com/v1/12/modify");
    result = builder.url.url.absoluteString;
    XCTAssertTrue([result isEqualToString:@"https://https://example.com/12/modify"] || [result isEqualToString:@"https://https//example.com/12/modify"]);
    
    networkOptions.identityHost = (id _Nonnull)nil;
    baseURL = [networkCommunication modifyURL];
    builder = [MPURLRequestBuilder newBuilderWithURL:baseURL];
    
    result = builder.url.defaultURL.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.us1.mparticle.com/v1/12/modify");
    result = builder.url.url.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.us1.mparticle.com/12/modify");
    
    networkOptions = nil;
    baseURL = [networkCommunication modifyURL];
    builder = [MPURLRequestBuilder newBuilderWithURL:baseURL];
    
    result = builder.url.defaultURL.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.us1.mparticle.com/v1/12/modify");
    result = builder.url.url.absoluteString;
    XCTAssertEqualObjects(result, @"https://identity.us1.mparticle.com/12/modify");
}

@end
