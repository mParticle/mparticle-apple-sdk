#import <XCTest/XCTest.h>
#import "MPResponseEvents.h"
#import "MPStateMachine.h"
#import "MPConsumerInfo.h"
#import "MPPersistenceController.h"

@interface MPResponseEventsTest : XCTestCase
//- (BOOL)areEqual:(NSDictionary *)cookies1 cookies2: (NSArray<MPCookie *> *)cookies2;
@end

@implementation MPResponseEventsTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testParseConfiguration {
    MPStateMachine *stateMachine = [MPStateMachine sharedInstance];
//    XCTAssertNil(stateMachine.consumerInfo.mpId);
    
    NSNumber *originalMpId = @10;
    NSString *originalDas = @"aaaaaaaaa";
//    NSString *originalCookies = @"{\"uid\":{\"c\":\"u=-1983370217984460071&cr=4211576&lbri=11111111-2222-3333-4444-5555555555&g=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeee&ls=4211576&lbe=4211576\",\"e\":\"2100-01-01T1:0:00.000000Z\"},\"rpl\":{\"c\":\"-1111111111=2222222\",\"e\":\"2100-01-01T1:00:00.000000Z\"}}"
    NSString *cookie1Name = @"uid";
    NSDictionary *cookie1Body = @{ @"c":@"u=-0000000000000000000&cr=4211576&lbri=11111111-2222-3333-4444-5555555555&g=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeee&ls=4211576&lbe=4211576",
                              @"e":@"2100-01-01T01:00:00.000000Z"};
    NSString *cookie2Name = @"rpl";
    NSDictionary *cookie2Body = @{@"c": @"-1111111111=2222222",
                                @"e": @"2100-01-01T1:00:00.000000Z"};
    NSString *cookie3Name = @"cookie3";
    NSDictionary *cookie3Body = @{@"c": @"abcdefghijklmnopqrstuvwxyz",
                                @"e": @"2300-01-01T1:00:00.000000Z"
                                };
    
    MPCookie *cookie1 = [[MPCookie alloc] initWithName:cookie1Name configuration:cookie1Body];
    MPCookie *cookie2 = [[MPCookie alloc] initWithName:cookie2Name configuration:cookie2Body];
    MPCookie *cookie3 = [[MPCookie alloc] initWithName:cookie3Name configuration:cookie3Body];
    
    NSArray<MPCookie *> *originalCookies = @[cookie1, cookie2];
    NSArray<MPCookie *> *newCookies = @[cookie2, cookie3];
    
    NSNumber *newMpId = @99999;
    NSString *newDas = @"abcd1234";

    stateMachine.consumerInfo.uniqueIdentifier = originalDas;
    [MPPersistenceController setMpid:originalMpId];
    stateMachine.consumerInfo.cookies = originalCookies;
    
    XCTAssertEqualObjects([MPPersistenceController mpId], originalMpId);
    XCTAssertEqualObjects(stateMachine.consumerInfo.uniqueIdentifier, originalDas);
    XCTAssertTrue(areEqual(stateMachine.consumerInfo.cookiesDictionaryRepresentation, originalCookies));
    
    NSDictionary *response = @{kMPRemoteConfigConsumerInfoKey:@{
                                       kMPRemoteConfigMPIDKey: newMpId,
                                       kMPRemoteConfigCookiesKey: newCookies,
                                       kMPRemoteConfigUniqueIdentifierKey: newDas
                                       }};
    
    [MPResponseEvents parseConfiguration:response];
    XCTAssertEqualObjects([MPPersistenceController mpId], originalMpId);
    XCTAssertEqualObjects(stateMachine.consumerInfo.uniqueIdentifier, originalDas);
    XCTAssertTrue(areEqual(stateMachine.consumerInfo.cookiesDictionaryRepresentation, originalCookies));
}

BOOL areEqual(NSDictionary *cookies1, NSArray<MPCookie *> *cookies2) {
    if ([cookies1.allKeys count] != [cookies2 count]) {
        return false;
    }
    for (MPCookie *cookie in cookies2) {
        MPCookie *matchingCookie = cookies1[cookie.name];
        if (!matchingCookie) {
            return false;
        }
    }
    return true;
}
@end
