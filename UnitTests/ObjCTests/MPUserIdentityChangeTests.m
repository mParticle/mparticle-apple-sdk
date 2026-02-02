#import <XCTest/XCTest.h>
#import "MPIdentityApiRequest.h"
#import "MParticleUser.h"
#import "mParticle.h"
#import "MPIConstants.h"
#import "MPBackendController.h"
#import "MParticleSwift.h"
#import "MPBaseTestCase.h"
@import mParticle_Apple_SDK_Swift;

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

@end
