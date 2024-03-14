#import <XCTest/XCTest.h>
#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPBaseTestCase.h"

#pragma mark - MPConsumerInfo(Tests)
@interface MPConsumerInfo(Tests)

- (NSNumber *)generateMpId;

@end


#pragma mark - MPConsumerInfoTests
@interface MPConsumerInfoTests : MPBaseTestCase {
    NSDictionary *responseDictionary;
    NSDictionary *consumerInfoDictionary;
}

@end


@implementation MPConsumerInfoTests

- (void)setUp {
    [super setUp];
    
    responseDictionary = @{@"ci":@{
                                   @"ck":@{
                                           @"rpl":@{
                                                   @"c":@"288160084=2832403&-515079401=2832403&1546594223=2832403&264784951=2832403&4151713=2832403&-1663781220=2832403",
                                                   @"e":@"2015-05-26T22:43:31.505262Z"
                                                   },
                                           @"uddif":@{
                                                   @"c":@"uah6978=1068490497975183452&uahist=%2524Gender%3Dm%26Tag1%3D",
                                                   @"e":@"2025-05-18T22:43:31.461026Z"
                                                   },
                                           @"uid":@{
                                                   @"c":@"u=3452189063653540060&cr=2827774&lbri=53CB5411-5BF0-402C-88E4-DFE91F921D82&g=7754fbee-1b83-4cab-9b59-34518c14ae85&ls=2832403&lbe=2832403",
                                                   @"e":@"2025-05-15T17:34:07.450231Z"
                                                   },
                                           @"uuc6978":@{
                                                   @"c":@"nu=t&et-Unknown=2832403&et-Other=2832403&et-=2832403&et-Transaction=2832198",
                                                   @"e":@"2020-05-16T17:34:07.941843Z"
                                                   }
                                           },
                                   @"das":@"7754fbee-1b83-4cab-9b59-34518c14ae85",
                                   @"mpid":@3452189063653540060
                                   },
                           @"ct":@1432248211838,
                           @"dt":@"rh",
                           @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                           @"msgs":@[]
                           };
    
    consumerInfoDictionary = responseDictionary[kMPRemoteConfigConsumerInfoKey];
}

- (void)testInstance {
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    NSData *consumerInfoData = [NSKeyedArchiver archivedDataWithRootObject:consumerInfo];
    XCTAssertNotNil(consumerInfoData, @"Should not have been nil.");
    MPConsumerInfo *deserializedConsumerInfo = [NSKeyedUnarchiver unarchiveObjectWithData:consumerInfoData];
    XCTAssertNotNil(deserializedConsumerInfo, @"Should not have been nil.");
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:@{}];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    NSDictionary *nilDictionary = nil;
    [consumerInfo updateWithConfiguration:nilDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:(NSDictionary *)[NSNull null]];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
}

- (void)testCookiesDictionary {
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    XCTAssertNotNil(cookiesDictionary, @"Cookies dictionary should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"rpl"], @"Value for key should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"uddif"], @"Value for key should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"uid"], @"Value for key should not have been nil.");
    XCTAssertNotNil(cookiesDictionary[@"uuc6978"], @"Value for key should not have been nil.");
}

- (void)testNullValues {
    NSDictionary *localResponseDictionary = @{@"ci":@{
                                                      @"ck":@{
                                                              @"rpl":@{
                                                                      @"c":[NSNull null],
                                                                      @"e":@"2015-05-26T22:43:31.505262Z"
                                                                      },
                                                              @"uddif":@{
                                                                      @"c":@"uah6978=1068490497975183452&uahist=%2524Gender%3Dm%26Tag1%3D",
                                                                      @"e":[NSNull null]
                                                                      },
                                                              @"uid":[NSNull null],
                                                              [NSNull null]:@{
                                                                      @"c":@"nu=t&et-Unknown=2832403&et-Other=2832403&et-=2832403&et-Transaction=2832198",
                                                                      @"e":@"2020-05-16T17:34:07.941843Z"
                                                                      }
                                                              },
                                                      @"das":[NSNull null],
                                                      @"mpid":[NSNull null]
                                                      },
                                              @"ct":@1432248211838,
                                              @"dt":@"rh",
                                              @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                                              @"msgs":[NSNull null]
                                              };
    
    NSDictionary *localConsumerInfoDictionary = localResponseDictionary[kMPRemoteConfigConsumerInfoKey];
    
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:localConsumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    NSDictionary *cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    XCTAssertNotNil(cookiesDictionary, @"Cookies dictionary should not have been nil.");
    
    localResponseDictionary = @{@"ci":@{
                                        @"ck":[NSNull null],
                                        @"das":[NSNull null],
                                        @"mpid":[NSNull null]
                                        },
                                @"ct":@1432248211838,
                                @"dt":@"rh",
                                @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                                @"msgs":[NSNull null]
                                };
    
    localConsumerInfoDictionary = localResponseDictionary[kMPRemoteConfigConsumerInfoKey];
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:localConsumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    localResponseDictionary = @{@"ci":[NSNull null],
                                @"ct":@1432248211838,
                                @"dt":@"rh",
                                @"id":@"aeea31ab-2ee6-4126-bf9d-1812873aee20",
                                @"msgs":[NSNull null]
                                };
    
    localConsumerInfoDictionary = localResponseDictionary[kMPRemoteConfigConsumerInfoKey];
    
    consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:localConsumerInfoDictionary];
    XCTAssertNotNil(consumerInfo, @"Consumer info instance should not have been nil.");
    
    cookiesDictionary = [consumerInfo cookiesDictionaryRepresentation];
    XCTAssertNil(cookiesDictionary, @"Cookies dictionary should have been nil.");
}

- (void)testCookie {
    NSString *name = @"Cookie";
    NSDictionary *configuration = @{@"c":@"288160084=2832403&-515079401=2832403&1546594223=2832403&264784951=2832403&4151713=2832403&-1663781220=2832403",
                                    @"e":@"2035-05-26T22:43:31.505262Z"};
    
    MPCookie *cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNotNil(cookie, @"Should not have been nil.");
    XCTAssertFalse([cookie expired], @"Should have been false.");
    
    NSData *cookieData = [NSKeyedArchiver archivedDataWithRootObject:cookie];
    XCTAssertNotNil(cookieData, @"Should not have been nil.");
    MPCookie *deserializedCookie = [NSKeyedUnarchiver unarchiveObjectWithData:cookieData];
    XCTAssertNotNil(deserializedCookie, @"Should not have been nil.");
    XCTAssertEqualObjects(cookie, deserializedCookie, @"Should have been equal.");
    XCTAssertNotEqualObjects(cookie, (MPCookie *)@"A string is not a cookie", @"Should not have been equal.");
    XCTAssertNotEqualObjects(cookie, [NSNull null], @"Should not have been equal.");
    XCTAssertNotEqualObjects(cookie, nil, @"Should not have been equal.");
    
    NSDictionary *dictionary = [cookie dictionaryRepresentation];
    XCTAssertNotNil(dictionary, @"Should not have been nil.");
    
    deserializedCookie.content = nil;
    deserializedCookie.domain = nil;
    deserializedCookie.expiration = nil;
    dictionary = [deserializedCookie dictionaryRepresentation];
    XCTAssertNil(dictionary, @"Should have been nil.");
    
    name = (NSString *)[NSNull null];
    cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNil(cookie, @"Should have been nil.");
    
    name = (NSString *)[NSNumber numberWithInteger:42];
    cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNil(cookie, @"Should have been nil.");
    
    name = nil;
    cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNil(cookie, @"Should have been nil.");
    
    name = @"Cookie";
    configuration = (NSDictionary *)[NSNull null];
    cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNil(cookie, @"Should have been nil.");
    
    configuration = (NSDictionary *)@"This is not a dictionary";
    cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNil(cookie, @"Should have been nil.");
    
    configuration = nil;
    cookie = [[MPCookie alloc] initWithName:name configuration:configuration];
    XCTAssertNil(cookie, @"Should have been nil.");
}

- (void)testConsumerInfoEncoding {
    MPConsumerInfo *consumerInfo = [[MPConsumerInfo alloc] init];
    [consumerInfo updateWithConfiguration:consumerInfoDictionary];
    
    MPConsumerInfo *persistedConsumerInfo = [self attemptSecureEncodingwithClass:[MPConsumerInfo class] Object:consumerInfo];
    XCTAssertEqualObjects(consumerInfo.uniqueIdentifier, persistedConsumerInfo.uniqueIdentifier, @"Consumer Info should have been a match.");
}

@end
