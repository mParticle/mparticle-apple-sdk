#import <XCTest/XCTest.h>
#import "MPConnector.h"
#import "MPBaseTestCase.h"
#if TARGET_OS_IOS == 1
#import "OCMock.h"
#import "MPIConstants.h"

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

@end

#endif
