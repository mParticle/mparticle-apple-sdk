//
//  MParticleUserTests.m
//

#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPBackendController.h"
#import "MPStateMachine.h"
#import "FilteredMParticleUser.h"

@interface MParticle ()

@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;

@end

@interface MParticleUserTests : MPBaseTestCase

@end

@interface MParticleUser ()

- (BOOL)forwardLegacyUserIdentityToKitContainer:(NSString *)identityString identityType:(MPUserIdentity)identityType execStatus:(MPExecStatus) execStatus;
@end


@implementation MParticleUserTests

- (void)testForwardLegacyIdentityToKits {
    MParticleUser *user = [[MParticleUser alloc] init];
    XCTAssertTrue([user forwardLegacyUserIdentityToKitContainer:@"foo"
                                                   identityType:MPUserIdentityEmail
                                                     execStatus:MPExecStatusSuccess]);
}

- (void)testFailedStatusForwardLegacyIdentityToKits {
    MParticleUser *user = [[MParticleUser alloc] init];
    XCTAssertFalse([user forwardLegacyUserIdentityToKitContainer:@"foo"
                                                   identityType:MPUserIdentityEmail
                                                     execStatus:MPExecStatusFail]);
}

- (void)testNilOrNullForwardLegacyIdentityToKits {
    MParticleUser *user = [[MParticleUser alloc] init];
    XCTAssertFalse([user forwardLegacyUserIdentityToKitContainer:nil
                                                    identityType:MPUserIdentityEmail
                                                      execStatus:MPExecStatusSuccess]);
    NSString *null = (NSString*)[NSNull null];
    XCTAssertFalse([user forwardLegacyUserIdentityToKitContainer:null
                                                    identityType:MPUserIdentityEmail
                                                      execStatus:MPExecStatusSuccess]);
}

- (void)testForwardLegacyIdentityToKitsWithUserIdentity {
    MParticleUser *user = [[MParticleUser alloc] init];
    XCTAssertTrue([user forwardLegacyUserIdentityToKitContainer:@"foo"
                                                   identityType:MPUserIdentityEmail
                                                     execStatus:MPExecStatusSuccess]);
}

- (void)testGetUserAudiencesWithCompletionHandlerEnabled {
    MParticleUser *user = [[MParticleUser alloc] init];
    
    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.enableAudienceAPI = YES;
    
    [user getUserAudiencesWithCompletionHandler:^(NSArray<MPAudience *> * _Nonnull currentAudiences, NSError *_Nullable error) {
        XCTAssertNil(error);
    }];
}

- (void)testGetUserAudiencesWithCompletionHandlerDisabled {
    MParticleUser *user = [[MParticleUser alloc] init];

    MPStateMachine_PRIVATE *stateMachine = [MParticle sharedInstance].stateMachine;
    stateMachine.enableAudienceAPI = NO;

    [user getUserAudiencesWithCompletionHandler:^(NSArray<MPAudience *> * _Nonnull currentAudiences, NSError *_Nullable error) {
        XCTAssert(error);
        XCTAssertTrue(error.code == 202);
    }];
}

// A kit may pass a raw NSDictionary as the configuration; with no user identities
// the filtered accessors must return empty without dereferencing kit-configuration
// properties. Regression for the eager kitConfiguration access that crashed the
// Braze kit tests.
- (void)testFilteredUserToleratesRawDictionaryConfigWhenNoIdentities {
    MParticleUser *user = [[MParticleUser alloc] init];
    NSDictionary *rawConfig = @{@"apiKey": @"testKey"};
    FilteredMParticleUser *filteredUser = [[FilteredMParticleUser alloc] initWithMParticleUser:user
                                                                             kitConfiguration:(id)rawConfig];
    XCTAssertNoThrow(filteredUser.userIdentities);
    XCTAssertEqual(filteredUser.userIdentities.count, 0);
    XCTAssertNoThrow(filteredUser.userAttributes);
}


@end
