#import <XCTest/XCTest.h>
#import "MPConsentKitFilter.h"
#import "MPBaseTestCase.h"

@interface MPConsentKitFilterTests : MPBaseTestCase

@end

@implementation MPConsentKitFilterTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testProperties {
    MPConsentKitFilter *filter = [[MPConsentKitFilter alloc] init];
    
    XCTAssertFalse(filter.shouldIncludeOnMatch);
    XCTAssertNil(filter.filterItems);
    
    filter.shouldIncludeOnMatch = YES;
    XCTAssertTrue(filter.shouldIncludeOnMatch);
    
    filter.shouldIncludeOnMatch = NO;
    XCTAssertFalse(filter.shouldIncludeOnMatch);
    
    MPConsentKitFilterItem *item = [[MPConsentKitFilterItem alloc] init];
    
    filter.filterItems = [NSMutableArray arrayWithObject:item];
    
    NSArray *items = filter.filterItems;
    XCTAssertEqual(items.count, 1);
    
    MPConsentKitFilterItem *returnedItem = items[0];
    XCTAssertEqual(returnedItem, item);
    XCTAssertFalse(returnedItem.consented);
    
}

@end
