#import <XCTest/XCTest.h>
#import "MPConnector.h"
#import "MPBaseTestCase.h"
#if TARGET_OS_IOS == 1
#import "OCMock.h"
#import "MPIConstants.h"
#import "MPURL.h"
#import "MPURLRequestBuilder.h"

@interface MPConnector ()

@property (nonatomic) NSURLSession *urlSession;

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error;
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error;

@end

@interface MPConnectorTests  : MPBaseTestCase

@end

@implementation MPConnectorTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSessionIsInvalidatedWithError {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    connector.urlSession = mockSession;
    NSURLSessionTask *mockTask = OCMClassMock([NSURLSessionTask class]);
    NSError *error = [NSError new];
    
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
    NSError *error = [NSError new];
    
    [connector URLSession:mockSession didBecomeInvalidWithError:error];
    
    OCMVerifyAll((id)mockSession);
}

- (void)testSemaphoreWaitTimeout {
    XCTAssertLessThan(NETWORK_REQUEST_MAX_WAIT_SECONDS+1, DISPATCH_TIME_FOREVER);
}

- (void)testURLSession {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURLSession *mockSession = OCMClassMock([NSURLSession class]);
    OCMReject(ClassMethod([(id)mockSession sessionWithConfiguration:[OCMArg any] delegate:[OCMArg any] delegateQueue:[OCMArg  isNotNil]])).andReturn(@"Test string");
    NSURLSession *resultSession = connector.urlSession;
    XCTAssertNotNil(resultSession);
    OCMVerifyAll((id)mockSession);
}

- (void)testResponseFromGetRequestToURL {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURL *customURL = [NSURL URLWithString:@"https://192.168.1"];
    NSURL *defaultURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:customURL defaultURL:defaultURL];

    MPURLRequestBuilder *mockRequestBuilder = OCMClassMock([MPURLRequestBuilder class]);
    OCMVerify([[mockRequestBuilder class] newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodGet]);
    
    NSObject<MPConnectorResponseProtocol> *connectorResponse = [connector responseFromGetRequestToURL:mpURL];
    XCTAssertNotNil(connectorResponse);
    OCMVerifyAll((id)mockRequestBuilder);
}

- (void)testResponseFromPostRequestToURL {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURL *customURL = [NSURL URLWithString:@"https://192.168.1"];
    NSURL *defaultURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:customURL defaultURL:defaultURL];

    MPURLRequestBuilder *mockRequestBuilder = OCMClassMock([MPURLRequestBuilder class]);
    OCMVerify([[mockRequestBuilder class] newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodGet]);
    
    NSObject<MPConnectorResponseProtocol> *connectorResponse = [connector responseFromPostRequestToURL:mpURL message:nil serializedParams:nil];
    XCTAssertNotNil(connectorResponse);
    OCMVerifyAll((id)mockRequestBuilder);
}

@end

#endif
