#import <XCTest/XCTest.h>
#import "MParticleWebView.h"
#import "mParticle.h"
#import "OCMock.h"
#import "MPApplication.h"
#import <UIKit/UIKit.h>

@interface MPApplication ()
+ (void)setMockApplication:(id)mockApplication;
@end

@interface MParticleWebView ()

- (void)evaluateAgent;
- (BOOL)canAndShouldCollect;

@property (nonatomic) NSDate *initializedDate;
@property (nonatomic) NSString *resolvedAgent;
@property (nonatomic, assign) BOOL isCollecting;
@property (nonatomic, assign) int retryCount;

#if TARGET_OS_IOS == 1
@property (nonatomic) WKWebView *webView;
#endif

@end

@interface MParticleWebViewTests : XCTestCase

@property (nonatomic, strong) MParticleWebView *webView;

@end

@implementation MParticleWebViewTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _webView = [[MParticleWebView alloc] init];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    _webView = nil;
}

- (void)testInit {
    XCTAssertNotNil(_webView);
}

- (void)testUserAgentCustom {
    [_webView startWithCustomUserAgent:@"Test User Agent" shouldCollect:NO defaultAgentOverride:nil];
    XCTAssertEqualObjects(_webView.userAgent, @"Test User Agent");
}

- (void)testUserAgentDisabled {
    [_webView startWithCustomUserAgent:nil shouldCollect:NO defaultAgentOverride:nil];
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
    XCTAssertEqualObjects(_webView.userAgent, defaultAgent);
}

- (void)testUserAgentDefaultOverride {
    [_webView startWithCustomUserAgent:nil shouldCollect:NO defaultAgentOverride:@"Test User Agent"];
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
    XCTAssertNotEqualObjects(_webView.userAgent, defaultAgent);
    XCTAssertEqualObjects(_webView.userAgent, @"Test User Agent");
}

- (void)testUserAgentCapture {
    MParticleWebView *mockWebView = OCMPartialMock(_webView);
#if TARGET_OS_IOS == 1
    [[(id)mockWebView expect] evaluateAgent];
#else
    [[(id)mockWebView reject] evaluateAgent];
#endif
    [mockWebView startWithCustomUserAgent:nil shouldCollect:YES defaultAgentOverride:nil];
    [(id)mockWebView verify];
}

- (void)testShouldCollectResolved {
    _webView.resolvedAgent = @"Test User Agent";
    XCTAssertFalse([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectPending {
    _webView.resolvedAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = [NSDate date];
    XCTAssertTrue([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectNoDate {
    _webView.resolvedAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = nil;
    XCTAssertFalse([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectTooLong {
    _webView.resolvedAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = [NSDate dateWithTimeIntervalSinceNow:-6];
    XCTAssertFalse([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectTimeLeft {
    _webView.resolvedAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = [NSDate dateWithTimeIntervalSinceNow:-4];
    XCTAssertTrue([_webView shouldDelayUpload:5]);
}

- (void)testOriginalDefaultAgent {
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", MParticle.sharedInstance.version];
    XCTAssertEqualObjects(_webView.originalDefaultAgent, defaultAgent);
}

- (void)testBackgroundCollection {
    id mockApplication = OCMClassMock([UIApplication class]);
    OCMStub([mockApplication applicationState]).andReturn(UIApplicationStateBackground);
    [MPApplication setMockApplication:mockApplication];
    MParticleWebView *mockWebView = OCMPartialMock(_webView);
#if TARGET_OS_IOS == 1
    [[(id)mockWebView expect] evaluateAgent];
#else
    [[(id)mockWebView reject] evaluateAgent];
#endif
    [mockWebView startWithCustomUserAgent:nil shouldCollect:YES defaultAgentOverride:nil];
    [(id)mockWebView verify];
}

@end
