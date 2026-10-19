#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <mParticle_Apple_SDK_ObjC/mParticle.h>
#import "../mParticleExample/SceneDelegate.h"

// UIKit constructs these read-only connection objects; doubles supply only URL delivery data.
@interface ExampleURLContext : NSObject
@property (nonatomic, strong) NSURL *URL;
@end

@implementation ExampleURLContext
@end

@interface ExampleConnectionOptions : NSObject
@property (nonatomic, copy) NSSet<UIOpenURLContext *> *URLContexts;
@end

@implementation ExampleConnectionOptions
@end

@interface mParticleExampleTests : XCTestCase
@property (nonatomic, strong) SceneDelegate *sceneDelegate;
@property (nonatomic, strong) NSMutableArray<NSURL *> *receivedURLs;
@property (nonatomic, assign) IMP originalURLCallback;
@property (nonatomic, assign) IMP URLCallbackSpy;
@end

@implementation mParticleExampleTests

- (void)setUp {
    [super setUp];
    self.sceneDelegate = [[SceneDelegate alloc] init];
    self.receivedURLs = [NSMutableArray array];
    NSMutableArray<NSURL *> *receivedURLs = self.receivedURLs;
    self.URLCallbackSpy = imp_implementationWithBlock(^BOOL(MPRokt *rokt, NSURL *URL) {
        [receivedURLs addObject:URL];
        return NO;
    });
    Method method = class_getInstanceMethod([MPRokt class], @selector(handleURLCallback:));
    self.originalURLCallback = method_setImplementation(method, self.URLCallbackSpy);
}

- (void)tearDown {
    Method method = class_getInstanceMethod([MPRokt class], @selector(handleURLCallback:));
    method_setImplementation(method, self.originalURLCallback);
    imp_removeBlock(self.URLCallbackSpy);
    [super tearDown];
}

- (NSSet<UIOpenURLContext *> *)contextsWithURLs:(NSArray<NSURL *> *)URLs {
    NSMutableSet<UIOpenURLContext *> *contexts = [NSMutableSet set];
    for (NSURL *URL in URLs) {
        ExampleURLContext *context = [[ExampleURLContext alloc] init];
        context.URL = URL;
        [contexts addObject:(UIOpenURLContext *)context];
    }
    return contexts;
}

- (void)connectWithContexts:(NSSet<UIOpenURLContext *> *)contexts {
    ExampleConnectionOptions *options = [[ExampleConnectionOptions alloc] init];
    options.URLContexts = contexts;
    UIScene *scene = [UIApplication sharedApplication].connectedScenes.anyObject;
    [self.sceneDelegate scene:scene willConnectToSession:scene.session options:(UISceneConnectionOptions *)options];
}

- (void)testWarmLaunchForwardsPaymentURL {
    NSURL *URL = [NSURL URLWithString:@"example://payment/return"];
    UIScene *scene = [UIApplication sharedApplication].connectedScenes.anyObject;
    [self.sceneDelegate scene:scene openURLContexts:[self contextsWithURLs:@[URL]]];
    XCTAssertEqualObjects(self.receivedURLs, (@[URL]));
}

- (void)testWarmLaunchForwardsEveryURLWhenCallbacksReturnNO {
    NSArray<NSURL *> *URLs = @[
        [NSURL URLWithString:@"example://payment/first"],
        [NSURL URLWithString:@"example://payment/second"]
    ];
    UIScene *scene = [UIApplication sharedApplication].connectedScenes.anyObject;
    [self.sceneDelegate scene:scene openURLContexts:[self contextsWithURLs:URLs]];
    XCTAssertEqual(self.receivedURLs.count, 2);
    XCTAssertEqualObjects([NSSet setWithArray:self.receivedURLs], [NSSet setWithArray:URLs]);
}

- (void)testColdLaunchForwardsPaymentURL {
    NSURL *URL = [NSURL URLWithString:@"example://payment/return"];
    [self connectWithContexts:[self contextsWithURLs:@[URL]]];
    XCTAssertEqualObjects(self.receivedURLs, (@[URL]));
}

- (void)testColdLaunchForwardsEveryURL {
    NSArray<NSURL *> *URLs = @[
        [NSURL URLWithString:@"example://payment/first"],
        [NSURL URLWithString:@"example://payment/second"]
    ];
    [self connectWithContexts:[self contextsWithURLs:URLs]];
    XCTAssertEqual(self.receivedURLs.count, 2);
    XCTAssertEqualObjects([NSSet setWithArray:self.receivedURLs], [NSSet setWithArray:URLs]);
}

- (void)testWarmLaunchWithoutURLsDoesNotForwardCallbacks {
    UIScene *scene = [UIApplication sharedApplication].connectedScenes.anyObject;
    [self.sceneDelegate scene:scene openURLContexts:[NSSet set]];
    XCTAssertEqual(self.receivedURLs.count, 0);
}

- (void)testColdLaunchWithoutURLsDoesNotForwardCallbacks {
    [self connectWithContexts:[NSSet set]];
    XCTAssertEqual(self.receivedURLs.count, 0);
}

@end
