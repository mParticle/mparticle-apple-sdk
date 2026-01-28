@import XCTest;
#if TARGET_OS_IOS == 1
@import WebKit;
#endif
@import mParticle_Apple_SDK_Swift;

@interface MParticleWebViewPRIVATE ()
@property (nonatomic) NSDate *initializedDate;
@property (nonatomic) NSString *resolvedUserAgent;
@property (nonatomic, assign) BOOL isCollecting;
#if TARGET_OS_IOS == 1
@property (nonatomic) WKWebView *webView;
#endif
@end

@interface MParticleWebViewTests : XCTestCase
@property (nonatomic, strong) MParticleWebViewPRIVATE *webView;
@end

@implementation MParticleWebViewTests

- (void)setUp {
    dispatch_queue_t messageQueue = dispatch_queue_create("com.mparticle.messageQueue", DISPATCH_QUEUE_SERIAL);
    MPLog* logger = [[MPLog alloc] initWithLogLevel:MPILogLevelSwiftDebug];
    _webView = [[MParticleWebViewPRIVATE alloc] initWithMessageQueue:messageQueue logger:logger skdVersion:@"sdk version"];
}

- (void)tearDown {
    _webView = nil;
}

- (void)testInit {
    XCTAssertNotNil(_webView);
}

- (void)testUserAgentCustom {
    [_webView startWithCustomUserAgent:@"Test User Agent" shouldCollect:NO defaultUserAgentOverride:nil];
    XCTAssertEqualObjects(_webView.userAgent, @"Test User Agent");
}

- (void)testUserAgentDisabled {
    [_webView startWithCustomUserAgent:nil shouldCollect:NO defaultUserAgentOverride:nil];
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", @"sdk version"];
    XCTAssertEqualObjects(_webView.userAgent, defaultAgent);
}

- (void)testUserAgentDefaultOverride {
    [_webView startWithCustomUserAgent:nil shouldCollect:NO defaultUserAgentOverride:@"Test User Agent"];
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", @"sdk version"];
    XCTAssertNotEqualObjects(_webView.userAgent, defaultAgent);
    XCTAssertEqualObjects(_webView.userAgent, @"Test User Agent");
}

- (void)testShouldCollectResolved {
    _webView.resolvedUserAgent = @"Test User Agent";
    XCTAssertFalse([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectPending {
    _webView.resolvedUserAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = [NSDate date];
    XCTAssertTrue([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectNoDate {
    _webView.resolvedUserAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = nil;
    XCTAssertFalse([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectTooLong {
    _webView.resolvedUserAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = [NSDate dateWithTimeIntervalSinceNow:-6];
    XCTAssertFalse([_webView shouldDelayUpload:5]);
}

- (void)testShouldCollectTimeLeft {
    _webView.resolvedUserAgent = nil;
    _webView.isCollecting = YES;
    _webView.initializedDate = [NSDate dateWithTimeIntervalSinceNow:-4];
    XCTAssertTrue([_webView shouldDelayUpload:5]);
}

- (void)testOriginalDefaultAgent {
    NSString *defaultAgent = [NSString stringWithFormat:@"mParticle Apple SDK/%@", @"sdk version"];
    XCTAssertEqualObjects(_webView.originalDefaultUserAgent, defaultAgent);
}

@end
