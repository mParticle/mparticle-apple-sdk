#import <XCTest/XCTest.h>
#import "MPSurrogateAppDelegate.h"

@interface MPSurrogateAppDelegateTests : XCTestCase

@end

@implementation MPSurrogateAppDelegateTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testNonImplementedMethods {
    MPSurrogateAppDelegate *surrogate = [[MPSurrogateAppDelegate alloc] init];
    XCTAssertFalse([surrogate implementsSelector:@selector(isKindOfClass:)]);
    XCTAssertFalse([surrogate implementsSelector:@selector(isMemberOfClass:)]);
    XCTAssertFalse([surrogate implementsSelector:@selector(setValue:forKey:)]);
    XCTAssertFalse([surrogate implementsSelector:@selector(valueForKey:)]);
    XCTAssertFalse([surrogate implementsSelector:@selector(conformsToProtocol:)]);
}

- (void)testImplementedMethods {
    MPSurrogateAppDelegate *surrogate = [[MPSurrogateAppDelegate alloc] init];
    XCTAssert([surrogate implementsSelector:@selector(application:openURL:options:)]);
    XCTAssert([surrogate implementsSelector:@selector(application:openURL:sourceApplication:annotation:)]);
    XCTAssert([surrogate implementsSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]);
    XCTAssert([surrogate implementsSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]);
}

- (void)testSelectorArray {
    NSMutableArray *selectorArray = @[].mutableCopy;
    [selectorArray addObject:[NSValue valueWithPointer:@selector(application:openURL:options:)]];
    [selectorArray addObject:[NSValue valueWithPointer:@selector(application:openURL:sourceApplication:annotation:)]];
    
    XCTAssertFalse([selectorArray containsObject:[NSValue valueWithPointer:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]]);
    XCTAssert([selectorArray containsObject:[NSValue valueWithPointer:@selector(application:openURL:options:)]]);
}

@end
