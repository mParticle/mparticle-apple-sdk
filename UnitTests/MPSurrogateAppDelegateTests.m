#import <XCTest/XCTest.h>
#import "MPSurrogateAppDelegate.h"

@interface MPSurrogateAppDelegateTests : XCTestCase

@end

@implementation MPSurrogateAppDelegateTests

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
#if TARGET_OS_IOS == 1
    XCTAssert([surrogate implementsSelector:@selector(application:openURL:sourceApplication:annotation:)]);
    XCTAssert([surrogate implementsSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]);
    XCTAssert([surrogate implementsSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)]);
#endif
}

- (void)testSelectorArray {
    NSMutableArray *selectorArray = @[].mutableCopy;
    [selectorArray addObject:[NSValue valueWithPointer:@selector(application:openURL:options:)]];
    [selectorArray addObject:[NSValue valueWithPointer:@selector(application:openURL:sourceApplication:annotation:)]];
    
    XCTAssertFalse([selectorArray containsObject:[NSValue valueWithPointer:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]]);
    XCTAssert([selectorArray containsObject:[NSValue valueWithPointer:@selector(application:openURL:options:)]]);
}

@end
