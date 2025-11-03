#import <XCTest/XCTest.h>
#import "MPIdentityApiRequest.h"
#import "MParticleUser.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPBackendController.h"
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end


@interface MPUserIdentityChangeTests : MPBaseTestCase

@end

@implementation MPUserIdentityChangeTests

- (void)testUserIdentityRequest {
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    
    MParticleUser *currentUser = [[MParticle sharedInstance].identity currentUser];

    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    NSArray *userIdentityArray = @[@{@"n" : [NSNumber numberWithLong:MPIdentityCustomerId], @"i" : @"test"}, @{@"n" : [NSNumber numberWithLong:MPIdentityEmail], @"i" : @"test@example.com"}, @{@"n" : [NSNumber numberWithLong:MPIdentityIOSAdvertiserId], @"i" : @"exampleIDFA"}];
    
    [userDefaults setMPObject:userIdentityArray forKey:kMPUserIdentityArrayKey userId:currentUser.userId];
    
    MPIdentityApiRequest *request = [MPIdentityApiRequest requestWithUser:currentUser];
    XCTAssertEqualObjects(request.customerId, @"test");
    XCTAssertEqualObjects(request.email, @"test@example.com");
    XCTAssertEqualObjects([request.identities objectForKey:@(MPIdentityIOSAdvertiserId)], @"exampleIDFA");
}

- (void)testSelectedUserIdentityRequest {
    MParticle *mParticle = [MParticle sharedInstance];
    mParticle.backendController = [[MPBackendController_PRIVATE alloc] initWithDelegate:(id<MPBackendControllerDelegate>)mParticle];
    
    NSNumber *selectedUserID = [NSNumber numberWithInteger:58591];


    MPUserDefaults *userDefaults = [MPUserDefaults standardUserDefaultsWithStateMachine:[MParticle sharedInstance].stateMachine backendController:[MParticle sharedInstance].backendController identity:[MParticle sharedInstance].identity];
    
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
    MPUserIdentityInstance_PRIVATE *userIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:YES];
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
    userIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:nil dateFirstSet:date isFirstTimeSet:NO];
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

    MPUserIdentityInstance_PRIVATE *userIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithUserIdentityDictionary:userIdentityDictionary];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityCustomerId);
    XCTAssertEqualObjects(userIdentity.value, @"The Most Interesting Man in the World");
    XCTAssertEqualWithAccuracy([userIdentity.dateFirstSet timeIntervalSince1970], [date timeIntervalSince1970], 0.01);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
    
    
    userIdentityDictionary = @{@"n":@(MPUserIdentityOther2),
                               @"i":@"34353234",
                               @"dfs":MPMilliseconds([date timeIntervalSince1970]),
                               @"f":@YES};

    userIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithUserIdentityDictionary:userIdentityDictionary];
    XCTAssertNotNil(userIdentity);
    XCTAssertEqual(userIdentity.type, MPUserIdentityOther2);
    XCTAssertEqualObjects(userIdentity.value, @"34353234");
    XCTAssertEqualWithAccuracy([userIdentity.dateFirstSet timeIntervalSince1970], [date timeIntervalSince1970], 0.01);
    XCTAssertTrue(userIdentity.isFirstTimeSet);
}

- (void)testUserIdentityChange {
    NSDate *date = [NSDate date];
    MPUserIdentityInstance_PRIVATE *newUserIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:date isFirstTimeSet:NO];
    MPUserIdentityInstance_PRIVATE *oldUserIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:@"The Least Interesting Man in the World" dateFirstSet:[NSDate distantPast] isFirstTimeSet:YES];

    MPUserIdentityChange_PRIVATE *userIdentityChange = [[MPUserIdentityChange_PRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:oldUserIdentity timestamp:date userIdentities:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.newUserIdentity);
    XCTAssertNotNil(userIdentityChange.oldUserIdentity);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertTrue(userIdentityChange.changed);
    
    userIdentityChange = [[MPUserIdentityChange_PRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:nil timestamp:nil userIdentities:nil];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.newUserIdentity);
    XCTAssertNil(userIdentityChange.oldUserIdentity);
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

    MPUserIdentityInstance_PRIVATE *newUserIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:@"The Most Interesting Man in the World" dateFirstSet:[NSDate date] isFirstTimeSet:NO];
    MPUserIdentityChange_PRIVATE *userIdentityChange = [[MPUserIdentityChange_PRIVATE alloc] initWithNewUserIdentity:newUserIdentity userIdentities:userIdentities];
    XCTAssertNotNil(userIdentityChange);
    XCTAssertNotNil(userIdentityChange.newUserIdentity);
    XCTAssertNil(userIdentityChange.oldUserIdentity);
    XCTAssertNotNil(userIdentityChange.timestamp);
    XCTAssertFalse(userIdentityChange.changed);
}

- (void)testUserIdentityChangeTimestampBehavior {
    
    MPUserIdentityInstance_PRIVATE *newUserIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:@"test1" dateFirstSet:[NSDate date] isFirstTimeSet:NO];
    MPUserIdentityInstance_PRIVATE *oldUserIdentity = [[MPUserIdentityInstance_PRIVATE alloc] initWithType:MPUserIdentityCustomerId value:@"test2" dateFirstSet:[NSDate distantPast] isFirstTimeSet:YES];

    // Set date on init
    NSDate *date1 = [NSDate date];
    MPUserIdentityChange_PRIVATE *userIdentityChange1 = [[MPUserIdentityChange_PRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:oldUserIdentity timestamp:date1 userIdentities:nil];
    XCTAssertEqualObjects(userIdentityChange1.timestamp, date1);
    
    // Date is created on get
    MPUserIdentityChange_PRIVATE *userIdentityChange2 = [[MPUserIdentityChange_PRIVATE alloc] initWithNewUserIdentity:newUserIdentity oldUserIdentity:oldUserIdentity timestamp:nil userIdentities:nil];
    NSTimeInterval timestamp = userIdentityChange2.timestamp.timeIntervalSince1970;
    XCTAssertNotNil(userIdentityChange2.timestamp);
    [NSThread sleepForTimeInterval:0.5];
    XCTAssertEqual(timestamp, userIdentityChange2.timestamp.timeIntervalSince1970);
    XCTAssertNotNil(userIdentityChange2.timestamp);
}

@end
