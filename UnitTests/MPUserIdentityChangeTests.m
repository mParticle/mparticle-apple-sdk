#import <XCTest/XCTest.h>
#import "MPUserIdentityChange.h"
#import "MPIdentityApiRequest.h"
#import "MParticleUser.h"
#import "mParticle.h"
#import "MPIUserDefaults.h"
#import "MPIConstants.h"
#import "MPBackendController.h"
#import "MPBaseTestCase.h"

@interface MParticle ()
@property (nonatomic, strong, nonnull) MPBackendController *backendController;
@end

@interface MPUserIdentityChangeTests : MPBaseTestCase

@end

@implementation MPUserIdentityChangeTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [[MPIUserDefaults standardUserDefaults] resetDefaults];

    [super tearDown];
}

- (void)testUserIdentityRequest {
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    
    MParticleUser *currentUser = [[MParticle sharedInstance].identity currentUser];

    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    NSArray *userIdentityArray = @[@{@"n" : [NSNumber numberWithLong:MPUserIdentityCustomerId], @"i" : @"test"}, @{@"n" : [NSNumber numberWithLong:MPUserIdentityEmail], @"i" : @"test@example.com"}];
    
    [userDefaults setMPObject:userIdentityArray forKey:kMPUserIdentityArrayKey userId:currentUser.userId];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:currentUser];
    XCTAssertEqualObjects(request.customerId, @"test");
    XCTAssertEqualObjects(request.email, @"test@example.com");
}

- (void)testSelectedUserIdentityRequest {
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    
    NSNumber *selectedUserID = [NSNumber numberWithInteger:58591];


    MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
    
    //Set up Identity to exist
    [userDefaults setMPObject:[NSDate date] forKey:kMPLastIdentifiedDate userId:selectedUserID];
    
    MParticleUser *selectedUser = [[MParticle sharedInstance].identity getUser:selectedUserID];
    
    XCTAssertNotNil(selectedUser);
    
    NSArray *userIdentityArray = @[@{@"n" : [NSNumber numberWithLong:MPUserIdentityCustomerId], @"i" : @"test"}, @{@"n" : [NSNumber numberWithLong:MPUserIdentityEmail], @"i" : @"test@example.com"}];
    
    [userDefaults setMPObject:userIdentityArray forKey:kMPUserIdentityArrayKey userId:selectedUser.userId];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:selectedUser];
    XCTAssertEqualObjects(request.customerId, @"test");
    XCTAssertEqualObjects(request.email, @"test@example.com");
}

- (void)testUserIdentityInstance {
    NSDate *date = [NSDate date];
    
    // New user identity
    MPUserIdentityInstance *userIdentity = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:YES];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(userIdentity.dateFirstSet, date);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
    
    NSDictionary *dictionary = [userIdentity dictionaryRepresentation];
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"n"], @(MPUserIdentityCustomerId));
    XCTAssertEqualObjects(dictionary[@"i"], @"The Most Interesting Man in the World");
    XCTAssertEqualObjects(dictionary[@"dfs"], MPMilliseconds([date timeIntervalSince1970]));
    XCTAssertEqualObjects(dictionary[@"f"], @(YES));
    
    // Delete user identity
    userIdentity = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:nil dateFirstSet:date isFirstTimeSet:NO];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertNil(userIdentity.value);
    XCTAssertEqualObjects(userIdentity.dateFirstSet, date);
    XCTAssertFalse(userIdentity.isFirstTimeSet);
    
    dictionary = [userIdentity dictionaryRepresentation];
    XCTAssertNotNil(dictionary);
    XCTAssertEqualObjects(dictionary[@"n"], @(MPUserIdentityCustomerId));
    XCTAssertNil(dictionary[@"i"]);
    XCTAssertEqualObjects(dictionary[@"dfs"], MPMilliseconds([date timeIntervalSince1970]));
    XCTAssertEqualObjects(dictionary[@"f"], @(NO));
}

- (void)testUserIdentityInstanceWithDictionary {
    NSDate *date = [NSDate date];

    NSDictionary<NSString *, id> *userIdentityDictionary = @{@"n":@(MPUserIdentityCustomerId),
                                                             @"i":@"The Most Interesting Man in the World",
                                                             @"dfs":MPMilliseconds([date timeIntervalSince1970]),
                                                             @"f":@YES};

    MPUserIdentityInstance *userIdentity = [[MPUserIdentityInstance alloc] initWithUserIdentityDictionary:userIdentityDictionary];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualWithAccuracy([userIdentity.dateFirstSet timeIntervalSince1970], [date timeIntervalSince1970], 0.01);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
}

- (void)testUserIdentityChange {
    NSDate *date = [NSDate date];
    MPUserIdentityInstance *userIdentityNew = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:NO];
    MPUserIdentityInstance *userIdentityOld = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Least Interesting Man in the World" dateFirstSet:[NSDate distantPast] isFirstTimeSet:YES];

    MPUserIdentityChange *userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew oldUserIdentity:userIdentityOld timestamp:date userIdentities:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.userIdentityNew);
    XCTAssertNotNil(userIdentityChange.userIdentityOld);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertTrue(userIdentityChange.changed);
    
    userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew oldUserIdentity:nil timestamp:nil userIdentities:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.userIdentityNew);
    XCTAssertNil(userIdentityChange.userIdentityOld);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertTrue(userIdentityChange.changed);
}

- (void)testIdenticalUserIdentityChange {
    NSArray<NSDictionary<NSString *, id> *> *userIdentities = @[
                                                                @{
                                                                    kMPUserIdentityTypeKey:@(MPUserIdentityCustomerId),
                                                                    kMPUserIdentityIdKey:@"The Most Interesting Man in the World"
                                                                }
                                                              ];

    MPUserIdentityInstance *userIdentityNew = [[MPUserIdentityInstance alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:[NSDate date] isFirstTimeSet:NO];
    MPUserIdentityChange *userIdentityChange = [[MPUserIdentityChange alloc] initWithNewUserIdentity:userIdentityNew userIdentities:userIdentities];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.userIdentityNew);
    XCTAssertNil(userIdentityChange.userIdentityOld);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertFalse(userIdentityChange.changed);
}

@end
