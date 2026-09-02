#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonDigest.h>
#import "MPBaseTestCase.h"
@import mParticle_Apple_SDK_Swift;
#if TARGET_OS_IOS == 1
#import <OCMock/OCMock.h>
#import "MPIConstants.h"

@interface MPConnectorTests  : MPBaseTestCase

@end

@implementation MPConnectorTests

- (void)testGeneratedSwiftInterfacePreservesRuntimeContracts {
    MPConnector *connector = [[MPConnector alloc] init];
    MPConnectorResponse *response = [[MPConnectorResponse alloc] init];

    XCTAssertEqualObjects(NSStringFromClass([MPConnector class]), @"MPConnector");
    XCTAssertEqualObjects(NSStringFromClass([MPConnectorResponse class]), @"MPConnectorResponse");
    XCTAssertTrue([connector conformsToProtocol:@protocol(MPConnectorProtocol)]);
    XCTAssertTrue([response conformsToProtocol:@protocol(MPConnectorResponseProtocol)]);
    XCTAssertEqual(HTTPStatusCodeSuccess, 200);
    XCTAssertEqual(HTTPStatusCodeNetworkAuthenticationRequired, 511);
}

- (NSString *)sha256FingerprintForData:(NSData *)data {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *fingerprint = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (NSUInteger index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [fingerprint appendFormat:@"%02X", digest[index]];
    }
    return fingerprint;
}

- (void)testDefaultPinnedCertificatesContainGoDaddyTLSRootR1 {
    NSString *expectedFingerprint = @"25CF3DA8E9B97ADDBF92543C2B82527C8A4E2CFF2062A6483040D4B64ACE719F";
    BOOL containsCertificate = NO;

    for (NSString *encodedCertificate in [MPConnector defaultPinnedCertificates]) {
        NSData *certificateData = [[NSData alloc] initWithBase64EncodedString:encodedCertificate options:0];
        XCTAssertNotNil(certificateData);
        if ([[self sha256FingerprintForData:certificateData] isEqualToString:expectedFingerprint]) {
            containsCertificate = YES;
        }
    }

    XCTAssertTrue(containsCertificate);
}

- (void)testSessionIsInvalidatedWithError {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    connector.urlSession = mockSession;
    NSURLSessionTask *mockTask = OCMClassMock([NSURLSessionTask class]);
    NSError *error = [NSError errorWithDomain:@"MPConnectorTests" code:1 userInfo:nil];
    
    [connector URLSession:mockSession task:mockTask didCompleteWithError:error];
    OCMVerify([mockSession finishTasksAndInvalidate]);
}

- (void)testSessionIsInvalidatedNoError {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    connector.urlSession = mockSession;
    NSURLSessionTask *mockTask = OCMClassMock([NSURLSessionTask class]);
    
    [connector URLSession:mockSession task:mockTask didCompleteWithError:nil];
    OCMVerify([mockSession finishTasksAndInvalidate]);
}

- (void)testSessionIsNotInvalidatedUnnecessarily {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    OCMReject([mockSession finishTasksAndInvalidate]);
    
    connector.urlSession = mockSession;
    NSError *error = [NSError errorWithDomain:@"MPConnectorTests" code:1 userInfo:nil];
    
    [connector URLSession:mockSession didBecomeInvalidWithError:error];
    
    OCMVerifyAll((id)mockSession);
}

- (void)testSemaphoreWaitTimeout {
    XCTAssertLessThan(NETWORK_REQUEST_MAX_WAIT_SECONDS+1, DISPATCH_TIME_FOREVER);
}

- (void)testURLSession {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    OCMReject(ClassMethod([(id)mockSession sessionWithConfiguration:[OCMArg any] delegate:[OCMArg any] delegateQueue:[OCMArg  isNotNil]]));
    NSURLSession *resultSession = connector.urlSession;
    XCTAssertNotNil(resultSession);
    OCMVerifyAll((id)mockSession);
}

- (void)testURLRequestForGetRequest {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURL *customURL = [NSURL URLWithString:@"https://192.168.1"];
    NSURL *defaultURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:customURL defaultURL:defaultURL];

    NSMutableURLRequest *request = [connector urlRequestForURL:mpURL
                                                       message:nil
                                                    httpMethod:kMPHTTPMethodGet
                                                      postData:nil
                                                        secret:nil];

    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.URL, customURL);
    XCTAssertEqualObjects(request.HTTPMethod, kMPHTTPMethodGet);
}

- (void)testURLRequestForPostRequest {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURL *customURL = [NSURL URLWithString:@"https://192.168.1"];
    NSURL *defaultURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:customURL defaultURL:defaultURL];

    NSData *body = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [connector urlRequestForURL:mpURL
                                                       message:@"{}"
                                                    httpMethod:kMPHTTPMethodPost
                                                      postData:body
                                                        secret:nil];

    XCTAssertNotNil(request);
    XCTAssertEqualObjects(request.URL, customURL);
    XCTAssertEqualObjects(request.HTTPMethod, kMPHTTPMethodPost);
    XCTAssertEqualObjects(request.HTTPBody, body);
}

@end

#endif
