#import <XCTest/XCTest.h>
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"

@interface MPLaunchInfoTests : MPBaseTestCase

@property (nonatomic, strong) id annotation;
@property (nonatomic, strong) NSURL *url;

@end


@implementation MPLaunchInfoTests

- (void)testAnnotation {
    NSURL *url = [NSURL URLWithString:@"http://mparticle.com"];
    NSString *sourceApp = @"testApp";
    NSDate *date = [NSDate date];
    NSRange range;
    id annotation = @{@"String Key":@"String Value",
                      @"Number Key":@42,
                      @"Date Key":date,
                      @"Data Key":[@"Another string" dataUsingEncoding:NSUTF8StringEncoding]};
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNotNil(launchInfo, @"Should not have been nil.");
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSString class]]);
    XCTAssertNotNil(launchInfo.annotation);
    range = [launchInfo.annotation rangeOfString:@"String Key"];
    XCTAssertTrue(range.location != NSNotFound);
    range = [launchInfo.annotation rangeOfString:@"Number Key"];
    XCTAssertTrue(range.location != NSNotFound);
    range = [launchInfo.annotation rangeOfString:@"Date Key"];
    XCTAssertTrue(range.location != NSNotFound);
    range = [launchInfo.annotation rangeOfString:@"Data Key"];
    XCTAssertTrue(range.location == NSNotFound);
    
    annotation = @[@"String", @42, date, [@"Another string" dataUsingEncoding:NSUTF8StringEncoding]];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSString class]]);
    XCTAssertNotNil(launchInfo.annotation);
    range = [launchInfo.annotation rangeOfString:@"String"];
    XCTAssertTrue(range.location != NSNotFound);
    range = [launchInfo.annotation rangeOfString:@"42"];
    XCTAssertTrue(range.location != NSNotFound);
    range = [launchInfo.annotation rangeOfString:@"Another"];
    XCTAssertTrue(range.location == NSNotFound);
    
    annotation = @"String";
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSString class]]);
    XCTAssertEqualObjects(launchInfo.annotation, @"String", @"Should have been equal.");
    
    annotation = @42;
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertTrue([launchInfo.annotation isKindOfClass:[NSString class]], @"Should have been true.");
    XCTAssertEqualObjects(launchInfo.annotation, @"42");
    
    annotation = date;
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNotNil(launchInfo.annotation);
    NSString *dateString = [MPDateFormatter stringFromDateRFC3339:date];
    XCTAssertEqualObjects(launchInfo.annotation, dateString);

    annotation = [@"Another string" dataUsingEncoding:NSUTF8StringEncoding];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNil(launchInfo.annotation);
}

- (void)testURL {
    NSURL *url = [NSURL URLWithString:@"http://mparticle.com/al_applink_data"];
    NSString *sourceApp = @"testApp";
    id annotation = nil;
    
    MPLaunchInfo *launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertNotNil(launchInfo, @"Should not have been nil.");
    XCTAssertEqualObjects(launchInfo.sourceApplication, @"AppLink(testApp)", @"Should have been equal.");
    XCTAssertEqualObjects(launchInfo.url, url, @"Should have been equal.");
    
    url = [NSURL URLWithString:@"http://mparticle.com"];
    launchInfo = [[MPLaunchInfo alloc] initWithURL:url sourceApplication:sourceApp annotation:annotation];
    XCTAssertEqualObjects(launchInfo.sourceApplication, @"testApp", @"Should have been equal.");
    XCTAssertEqualObjects(launchInfo.url, url, @"Should have been equal.");
}

- (void)testCreation {
    MPLaunchInfo *info = nil;
    info = [[MPLaunchInfo alloc] initWithURL:[NSURL URLWithString:@"https://example.com"] sourceApplication:@"My app" annotation:@"My annotation"];
    XCTAssert(info);

    info = [[MPLaunchInfo alloc] initWithURL:[NSURL URLWithString:@"https://example.com"] options:nil];
    XCTAssert(info);
}

@end
