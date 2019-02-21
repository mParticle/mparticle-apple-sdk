#import <XCTest/XCTest.h>
#import "MPNetworkCommunication.h"
#import "MPNetworkCommunication+Tests.h"
#import "MPApplication.h"
#import "OCMock.h"
#import "MPUpload.h"
#import "MPZip.h"

@interface MPNetworkCommunicationTests : XCTestCase

@end

Method originalMethod = nil; Method swizzleMethod = nil;

@implementation MPNetworkCommunicationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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

@end
