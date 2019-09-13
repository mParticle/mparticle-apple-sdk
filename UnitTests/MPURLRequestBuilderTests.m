#import <XCTest/XCTest.h>
#import "MPURLRequestBuilder.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPConsumerInfo.h"
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPKitRegister.h"
#import "MPKitContainer.h"
#import "MPKitTestClass.h"
#import "MPIUserDefaults.h"
#import "MPPersistenceController.h"
#import "MPMessage.h"
#import "MPBaseTestCase.h"
#import "MPKitConfiguration.h"

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine *stateMachine;
@property (nonatomic, strong) MPKitContainer *kitContainer;

@end

#pragma mark - MPURLRequestBuilder category
@interface MPURLRequestBuilder(Tests)

- (NSString *)hmacSha256Encode:(NSString *const)message key:(NSString *const)key;
- (NSString *)userAgent;
- (void)setUserAgent:(NSString *const)userAgent;
- (NSString *)fallbackUserAgent;

@end

#pragma mark - MPKitContainer category for unit tests
@interface MPKitContainer(Tests)

- (id<MPKitProtocol>)startKit:(NSNumber *)integrationId configuration:(MPKitConfiguration *)kitConfiguration;

@end

#pragma mark - MPURLRequestBuilderTests
@interface MPURLRequestBuilderTests : MPBaseTestCase {
    MPKitContainer *kitContainer;
}

@end

@implementation MPURLRequestBuilderTests

- (void)setUp {
    [super setUp];
    
    [MPPersistenceController setMpid:@12];

    [MParticle sharedInstance].stateMachine = [[MPStateMachine alloc] init];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.apiKey = @"unit_test_app_key";
    stateMachine.secret = @"unit_test_secret";

    [MParticle sharedInstance].kitContainer = [[MPKitContainer alloc] init];
    kitContainer = [MParticle sharedInstance].kitContainer;

    NSSet<id<MPExtensionProtocol>> *registeredKits = [MPKitContainer registeredKits];
    if (!registeredKits) {
        MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"KitTest" className:@"MPKitTestClassNoStartImmediately"];
        [MPKitContainer registerKit:kitRegister];

        kitRegister = [[MPKitRegister alloc] initWithName:@"KitSecondTest" className:@"MPKitSecondTestClass"];
        [MPKitContainer registerKit:kitRegister];

        kitRegister = [[MPKitRegister alloc] initWithName:@"AppsFlyer" className:@"MPKitAppsFlyerTest"];
        [MPKitContainer registerKit:kitRegister];

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
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:nil messageType:@"e" messageInfo:@{@"key":@"value"} uploadStatus:MPUploadStatusBatch UUID:[[NSUUID UUID] UUIDString] timestamp:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURL]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    [urlRequestBuilder setUserAgent:nil];
    
    dispatch_async([MParticle messageQueue], ^{
        NSString *userAgent = [urlRequestBuilder userAgent];
        XCTAssertNotNil(userAgent, @"Should not have been nil.");
        XCTAssertTrue([userAgent isEqualToString:@"Test User Agent"], @"User Agent has an invalid value: %@", userAgent);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)testDisableCollectUserAgent {
    MParticleOptions *options = [MParticleOptions optionsWithKey:@"testKey" secret:@"testSecret"];
    options.customUserAgent = nil;
    options.collectUserAgent = NO;
    [[MParticle sharedInstance] startWithOptions:options];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"User-Agent"];
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:nil messageType:@"e" messageInfo:@{@"key":@"value"} uploadStatus:MPUploadStatusBatch UUID:[[NSUUID UUID] UUIDString] timestamp:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURL]
                                                                            message:[message serializedString]
                                                                         httpMethod:@"POST"];
    [urlRequestBuilder setUserAgent:nil];
    
    dispatch_async([MParticle messageQueue], ^{
        NSString *userAgent = [urlRequestBuilder userAgent];
        XCTAssertNotNil(userAgent, @"Should not have been nil.");
        
        NSString *defaultUserAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
        XCTAssertTrue([userAgent isEqualToString:defaultUserAgent], @"User Agent has an invalid value: %@", userAgent);
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testHMACSha256Encode {
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:@"http://mparticle.com"]];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
    NSString *message = @"The Quick Brown Fox Jumps Over The Lazy Dog.";
    NSString *referenceEncodedMessage = @"ceefdfeab2fe404a7cbb75f6f6a01443286fab507eb85c213fce3d812e8b615c";
    NSString *encodedMessage = [urlRequestBuilder hmacSha256Encode:message key:stateMachine.apiKey];
    
    XCTAssertEqualObjects(encodedMessage, referenceEncodedMessage, @"HMAC Sha 256 is failing to encode correctly.");
}

- (void)testInvalidHMACSha256Encode {
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:@"http://mparticle.com"]];
    MPStateMachine *stateMachine = [MParticle sharedInstance].stateMachine;
    
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
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication configURL] message:nil httpMethod:@"GET"];
    NSMutableURLRequest *asyncURLRequest = [urlRequestBuilder build];
    
    NSDictionary *headersDictionary = [asyncURLRequest allHTTPHeaderFields];
    NSArray *keys = [headersDictionary allKeys];

    NSMutableArray *headers = @[@"User-Agent", @"Accept-Encoding", @"Content-Encoding", @"locale", @"Content-Type", @"timezone", @"secondsFromGMT", @"Date", @"x-mp-signature", @"x-mp-env", @"x-mp-kits"].mutableCopy;
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
    [[MPIUserDefaults standardUserDefaults] setConfiguration:responseConfiguration eTag:eTag requestTimestamp:requestTimestamp currentAge:@"0" maxAge:nil];

    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
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
    NSString *urlString = @"http://mparticle.com";
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:urlString]];
    
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
    NSString *urlString = @"http://mparticle.com";
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:urlString]];
    
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
    NSURL *url = nil;
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:url];
    
    XCTAssertNil(urlRequestBuilder, @"Retuning a request builder from an invalid URL.");
    
    urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:url message:nil httpMethod:@"GET"];
    
    XCTAssertNil(urlRequestBuilder, @"Retuning a request builder from an invalid URL.");
    
    NSString *urlString = @"http://mparticle.com";
    urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[NSURL URLWithString:urlString] message:nil httpMethod:nil];
    
    XCTAssertEqualObjects(urlRequestBuilder.httpMethod, @"GET", @"HTTP method is assuming GET as default.");
}

- (void)testEventRequest {
    NSDictionary *configuration1 = @{
                                     @"id":@42,
                                     @"as":@{
                                             @"appKey":@"unique key"
                                             }
                                     };
    
    NSArray *kitConfigs = @[configuration1];
    [[MParticle sharedInstance].kitContainer configureKits:nil];
    [[MParticle sharedInstance].kitContainer configureKits:kitConfigs];
    
    XCTAssertEqual([MPURLRequestBuilder requestTimeout], 30, @"Should have been equal.");
    
    MPNetworkCommunication *networkCommunication = [[MPNetworkCommunication alloc] init];
    
    MPMessage *message = [[MPMessage alloc] initWithSession:nil messageType:@"e" messageInfo:@{@"key":@"value"} uploadStatus:MPUploadStatusBatch UUID:[[NSUUID UUID] UUIDString] timestamp:[[NSDate date] timeIntervalSince1970] userId:[MPPersistenceController mpId]];
    
    MPURLRequestBuilder *urlRequestBuilder = [MPURLRequestBuilder newBuilderWithURL:[networkCommunication eventURL]
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

@end
