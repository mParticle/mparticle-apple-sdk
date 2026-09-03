#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPConnector.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPIConstants.h"
#import "MPURL.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

@interface MPConnector (MPURLRequestBuilderTests)

- (nullable NSMutableURLRequest *)urlRequestForURL:(nonnull MPURL *)url
                                           message:(nullable NSString *)message
                                        httpMethod:(nullable NSString *)httpMethod
                                          postData:(nullable NSData *)postData
                                            secret:(nullable NSString *)secret;

@end

@interface MPURLRequestBuilderTests : MPBaseTestCase

@property (nonatomic, strong) MPConnector *connector;

@end

@implementation MPURLRequestBuilderTests

- (void)setUp {
    [super setUp];

    [MPPersistenceController_PRIVATE setMpid:@12];
    [MParticle sharedInstance].stateMachine.apiKey = @"unit_test_app_key";
    [MParticle sharedInstance].stateMachine.secret = @"unit_test_secret";
    [MParticle sharedInstance].kitContainer_PRIVATE = [[MPKitContainer_PRIVATE alloc] init];
    self.connector = [[MPConnector alloc] init];
}

- (void)tearDown {
    self.connector = nil;
    [super tearDown];
}

- (MPURLRequestContext *)contextWithSecret:(nullable NSString *)secret {
    MPLog *logger = [[MPLog alloc] initWithLogLevel:MPILogLevelSwiftNone];
    return [[MPURLRequestContext alloc] initWithAPIKey:@"unit_test_app_key"
                                        fallbackSecret:secret
                                             userAgent:@"Unit Test Agent"
                                         supportedKits:@[@42, @314]
                                        configuredKits:@[@42]
                                                  eTag:@"etag"
                                hasStoredConfiguration:YES
                                           environment:MPEnvironmentDevelopment
                                        requestTimeout:10
                         networkPerformanceMessageType:kMPMessageTypeNetworkPerformance
                                                logger:logger];
}

- (void)testGeneratedSwiftInterfacePreservesRuntimeClassName {
    XCTAssertEqualObjects(NSStringFromClass([MPURLRequestBuilder class]), @"MPURLRequestBuilder");
    XCTAssertEqual(MPURLRequestKindCustom, 0);
    XCTAssertEqual(MPURLRequestKindConfig, 4);
}

- (void)testGeneratedSwiftInterfaceBuildsCustomRequest {
    NSURL *url = [NSURL URLWithString:@"https://example.com/custom"];
    NSData *body = [@"body" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *headers = [NSJSONSerialization dataWithJSONObject:@{@"X-Custom": @"value"}
                                                      options:0
                                                        error:nil];
    MPURLRequestBuilder *builder = [[MPURLRequestBuilder alloc] initWithURL:url
                                                                defaultURL:url
                                                                   message:nil
                                                                httpMethod:@"POST"
                                                               requestKind:MPURLRequestKindCustom
                                                                   context:[self contextWithSecret:nil]];

    NSMutableURLRequest *request = [[builder withHeaderData:headers] withPostData:body].build;

    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.URL, url);
    XCTAssertEqualObjects(request.HTTPMethod, @"POST");
    XCTAssertEqualObjects(request.HTTPBody, body);
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"X-Custom"], @"value");
    XCTAssertNil([request valueForHTTPHeaderField:@"x-mp-signature"]);
}

- (void)testGeneratedSwiftInterfaceIgnoresInvalidCustomHeaderValues {
    NSURL *url = [NSURL URLWithString:@"https://example.com/custom"];
    NSData *headers = [NSJSONSerialization dataWithJSONObject:@{
        @"X-Valid": @"value",
        @"X-Invalid": @42
    } options:0 error:nil];
    MPURLRequestBuilder *builder = [[MPURLRequestBuilder alloc] initWithURL:url
                                                                defaultURL:url
                                                                   message:nil
                                                                httpMethod:@"GET"
                                                               requestKind:MPURLRequestKindCustom
                                                                   context:[self contextWithSecret:nil]];

    NSMutableURLRequest *request;
    XCTAssertNoThrow(request = [[builder withHeaderData:headers] build]);
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"X-Valid"], @"value");
    XCTAssertNil([request valueForHTTPHeaderField:@"X-Invalid"]);
}

- (void)testConnectorBuildsConfigRequest {
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSMutableURLRequest *request = [self.connector urlRequestForURL:networkCommunication.configURL
                                                            message:nil
                                                         httpMethod:kMPHTTPMethodGet
                                                           postData:nil
                                                             secret:nil];

    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.URL, networkCommunication.configURL.url);
    XCTAssertEqualObjects(request.HTTPMethod, @"GET");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/x-www-form-urlencoded");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
    XCTAssertNotNil([request valueForHTTPHeaderField:@"Date"]);
    XCTAssertNotNil([request valueForHTTPHeaderField:@"x-mp-signature"]);
}

- (void)testConnectorReadsETagBeforeBuildingConfigRequest {
    NSString *eTag = @"1.618-2.718-3.141-42";
    NSDictionary *configuration = @{
        kMPRemoteConfigKitsKey: @[],
        kMPRemoteConfigRampKey: @100,
        kMPRemoteConfigSessionTimeoutKey: @112
    };
    [MPUserDefaultsConnector.userDefaults setConfiguration:configuration
                                                      eTag:eTag
                                          requestTimestamp:NSDate.date.timeIntervalSince1970
                                                currentAge:0
                                                    maxAge:nil];
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSMutableURLRequest *request = [self.connector urlRequestForURL:networkCommunication.configURL
                                                            message:nil
                                                         httpMethod:kMPHTTPMethodGet
                                                           postData:nil
                                                             secret:nil];

    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"If-None-Match"], eTag);
}

- (void)testConnectorBuildsAudienceRequestUsingOutgoingURL {
    NSURL *outgoingURL = [NSURL URLWithString:@"https://proxy.example.com/custom/audience?mpid=12"];
    outgoingURL.accessibilityHint = @"audience";
    NSURL *canonicalURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com/v1/key/audience?mpid=99"];
    canonicalURL.accessibilityHint = @"audience";
    MPURL *url = [[MPURL alloc] initWithURL:outgoingURL defaultURL:canonicalURL];

    NSMutableURLRequest *request = [self.connector urlRequestForURL:url
                                                            message:nil
                                                         httpMethod:kMPHTTPMethodGet
                                                           postData:nil
                                                             secret:nil];
    NSString *date = [request valueForHTTPHeaderField:@"Date"];
    NSString *signatureMessage = [MPRequestSigner signatureMessageWithHTTPMethod:@"GET"
                                                                             date:date
                                                                     relativePath:outgoingURL.relativePath
                                                                            query:outgoingURL.query];
    NSString *signature = [MPRequestSigner hmacSHA256HexForMessage:signatureMessage key:@"unit_test_secret"];

    XCTAssertEqualObjects(request.URL, outgoingURL);
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"x-mp-key"], @"unit_test_app_key");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"x-mp-signature"], signature);
}

- (void)testConnectorBuildsIdentityAndAliasRequestsUsingCanonicalPath {
    NSData *body = [@"{\"identity\":\"value\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *outgoingURL = [NSURL URLWithString:@"https://proxy.example.com/alias"];
    outgoingURL.accessibilityHint = @"identity";
    NSURL *canonicalURL = [NSURL URLWithString:@"https://identity.mparticle.com/v1/key/alias"];
    MPURL *url = [[MPURL alloc] initWithURL:outgoingURL defaultURL:canonicalURL];

    NSMutableURLRequest *request = [self.connector urlRequestForURL:url
                                                            message:@"alias"
                                                         httpMethod:kMPHTTPMethodPost
                                                           postData:body
                                                             secret:nil];

    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.URL, outgoingURL);
    XCTAssertEqualObjects(request.HTTPBody, body);
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"x-mp-key"], @"unit_test_app_key");
    XCTAssertNotNil([request valueForHTTPHeaderField:@"x-mp-signature"]);
    XCTAssertNil([request valueForHTTPHeaderField:@"Content-Encoding"]);
}

- (void)testConnectorBuildsEventRequestAndSendsProvidedBody {
    NSString *message = @"{\"dt\":\"e\"}";
    NSData *body = [NSData dataWithBytes:(unsigned char[]){0x1f, 0x8b, 0x08} length:3];
    NSURL *outgoingURL = [NSURL URLWithString:@"https://proxy.example.com/events"];
    NSURL *canonicalURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com/v2/key/events"];
    MPURL *url = [[MPURL alloc] initWithURL:outgoingURL defaultURL:canonicalURL];

    NSMutableURLRequest *request = [self.connector urlRequestForURL:url
                                                            message:message
                                                         httpMethod:kMPHTTPMethodPost
                                                           postData:body
                                                             secret:nil];

    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.HTTPBody, body);
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Type"], @"application/json");
    XCTAssertEqualObjects([request valueForHTTPHeaderField:@"Content-Encoding"], @"gzip");
    XCTAssertNotNil([request valueForHTTPHeaderField:@"x-mp-signature"]);
}

- (void)testConnectorOmitsSignatureWhenNoSecretIsAvailable {
    [MParticle sharedInstance].stateMachine.secret = nil;
    MPNetworkCommunication_PRIVATE *networkCommunication = [[MPNetworkCommunication_PRIVATE alloc] init];

    NSMutableURLRequest *request = [self.connector urlRequestForURL:networkCommunication.configURL
                                                            message:nil
                                                         httpMethod:kMPHTTPMethodGet
                                                           postData:nil
                                                             secret:nil];

    XCTAssertNotNil(request);
    XCTAssertNil([request valueForHTTPHeaderField:@"x-mp-signature"]);
}

- (void)testGeneratedSwiftInterfaceRejectsMissingURLs {
    MPURLRequestBuilder *missingOutgoing = [[MPURLRequestBuilder alloc]
        initWithURL:nil
        defaultURL:[NSURL URLWithString:@"https://example.com"]
        message:nil
        httpMethod:@"GET"
        requestKind:MPURLRequestKindCustom
        context:[self contextWithSecret:nil]];
    MPURLRequestBuilder *missingCanonical = [[MPURLRequestBuilder alloc]
        initWithURL:[NSURL URLWithString:@"https://example.com"]
        defaultURL:nil
        message:nil
        httpMethod:@"GET"
        requestKind:MPURLRequestKindCustom
        context:[self contextWithSecret:nil]];

    XCTAssertNil(missingOutgoing);
    XCTAssertNil(missingCanonical);
}

@end
