#import <XCTest/XCTest.h>

@interface mParticleExampleUITests : XCTestCase

@property (nonatomic, strong) XCUIApplication *app;

@end

@implementation mParticleExampleUITests

- (void)setUp {
    [super setUp];
    self.continueAfterFailure = NO;
    self.app = [[XCUIApplication alloc] init];
    [self addUIInterruptionMonitorWithDescription:@"Permission request" handler:^BOOL(XCUIElement *alert) {
        XCUIElement *denyButton = alert.buttons[@"Don’t Allow"];
        if (!denyButton.exists) {
            denyButton = alert.buttons[@"Don't Allow"];
        }
        if (denyButton.exists) {
            [denyButton tap];
            return YES;
        }
        return NO;
    }];
    [self.app launch];
}

- (void)testLaunchDisplaysExampleTable {
    XCTAssertTrue([self.app waitForState:XCUIApplicationStateRunningForeground timeout:10]);
    XCTAssertTrue([self.app.tables.firstMatch waitForExistenceWithTimeout:10]);
    [self.app tap];
    XCTAssertTrue(self.app.tables.firstMatch.hittable);
}

- (void)tearDown {
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationPortrait;
    [super tearDown];
}

- (void)testExampleTableRemainsVisibleAfterRotation {
    XCTAssertTrue([self.app.tables.firstMatch waitForExistenceWithTimeout:10]);
    [self.app tap];
    [XCUIDevice sharedDevice].orientation = UIDeviceOrientationLandscapeLeft;
    XCTAssertTrue(self.app.tables.firstMatch.hittable);
    CGRect frame = self.app.frame;
    XCTAssertGreaterThan(CGRectGetWidth(frame), CGRectGetHeight(frame));
}

- (void)testExampleTableRemainsVisibleAfterBackgrounding {
    XCTAssertTrue([self.app.tables.firstMatch waitForExistenceWithTimeout:10]);
    [self.app tap];
    [[XCUIDevice sharedDevice] pressButton:XCUIDeviceButtonHome];
    XCTAssertTrue([self.app waitForState:XCUIApplicationStateRunningBackground timeout:10]);
    [self.app activate];
    XCTAssertTrue([self.app waitForState:XCUIApplicationStateRunningForeground timeout:10]);
    XCTAssertTrue([self.app.tables.firstMatch waitForExistenceWithTimeout:10]);
    XCTAssertTrue(self.app.tables.firstMatch.hittable);
}

@end
