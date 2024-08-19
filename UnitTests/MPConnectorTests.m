#import <XCTest/XCTest.h>
#import "MPConnector.h"
#import "MPBaseTestCase.h"
#if TARGET_OS_IOS == 1
#import <OCMock/OCMock.h>
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
    OCMReject(ClassMethod([(id)mockSession sessionWithConfiguration:[OCMArg any] delegate:[OCMArg any] delegateQueue:[OCMArg  isNotNil]]));
    NSURLSession *resultSession = connector.urlSession;
    XCTAssertNotNil(resultSession);
    OCMVerifyAll((id)mockSession);
}

- (void)testResponseFromGetRequestToURL {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURL *customURL = [NSURL URLWithString:@"https://192.168.1"];
    NSURL *defaultURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:customURL defaultURL:defaultURL];

    id mockRequestBuilder = OCMClassMock([MPURLRequestBuilder class]);
    NSObject<MPConnectorResponseProtocol> *connectorResponse = [connector responseFromGetRequestToURL:mpURL];
    
    OCMVerify([mockRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodGet]);
    XCTAssertNotNil(connectorResponse);
    OCMVerifyAll((id)mockRequestBuilder);
}

- (void)testResponseFromPostRequestToURL {
    MPConnector *connector = [[MPConnector alloc] init];
    NSURL *customURL = [NSURL URLWithString:@"https://192.168.1"];
    NSURL *defaultURL = [NSURL URLWithString:@"https://nativesdks.mparticle.com"];
    MPURL *mpURL = [[MPURL alloc] initWithURL:customURL defaultURL:defaultURL];

    id mockRequestBuilder = OCMClassMock([MPURLRequestBuilder class]);
    NSObject<MPConnectorResponseProtocol> *connectorResponse = [connector responseFromPostRequestToURL:mpURL message:nil serializedParams:nil secret:nil];
    
    OCMVerify([mockRequestBuilder newBuilderWithURL:mpURL message:nil httpMethod:kMPHTTPMethodPost]);
    XCTAssertNotNil(connectorResponse);
    OCMVerifyAll((id)mockRequestBuilder);
}

@end

#endif
