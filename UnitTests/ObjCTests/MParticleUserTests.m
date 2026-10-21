//
//  MParticleUserTests.m
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"
#import "MPBackendController.h"
#import "MPKitContainer+MParticlePrivate.h"
@import mParticle_Apple_SDK_Swift;
#import "FilteredMParticleUser.h"

// Ceilings, not delays: the positive wait returns as soon as both forwards land. The inverted
// wait is spent in full on every run, so keep it short.
static const NSTimeInterval kMPUserAttributeForwardTimeout = 5.0;
static const NSTimeInterval kMPUserAttributeNoForwardTimeout = 0.3;

@interface MParticle ()

+ (dispatch_queue_t)messageQueue;
@property (nonatomic, strong) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

@interface MParticleUserTests : MPBaseTestCase

@property (nonatomic, strong) id mockBackendController;
@property (nonatomic, strong) id mockKitContainer;

@end

@interface MParticleUser ()

@property (nonatomic, strong) MPBackendController_PRIVATE *backendController;
- (BOOL)forwardLegacyUserIdentityToKitContainer:(NSString *)identityString identityType:(MPUserIdentity)identityType execStatus:(MPExecStatus) execStatus;
- (void)setIdentitySync:(NSString *)identityString identityType:(MPIdentity)identityType;
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

- (void)testSetIdentitySyncIgnoresANonStringUserIdentity {
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
    [user setIdentitySync:@"a@example.com" identityType:MPIdentityEmail];

    [user setIdentitySync:(NSString *)@7 identityType:MPIdentityEmail];

    XCTAssertEqualObjects(user.identities[@(MPIdentityEmail)], @"a@example.com");
}

- (void)testSetIdentitySyncStillRemovesAUserIdentityWithNilNullOrAnEmptyString {
    MParticleUser *user = [MParticle sharedInstance].identity.currentUser;
    for (id removal in @[[NSNull null], @""]) {
        [user setIdentitySync:@"a@example.com" identityType:MPIdentityEmail];
        [user setIdentitySync:(NSString *)removal identityType:MPIdentityEmail];
        XCTAssertNil(user.identities[@(MPIdentityEmail)], @"%@ should remove the identity", [removal class]);
    }

    [user setIdentitySync:@"a@example.com" identityType:MPIdentityEmail];
    [user setIdentitySync:nil identityType:MPIdentityEmail];
    XCTAssertNil(user.identities[@(MPIdentityEmail)]);
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
    // Return type must stay NSMutableDictionary (as before the Swift extraction).
    XCTAssertTrue([filteredUser.userIdentities isKindOfClass:[NSMutableDictionary class]]);
    XCTAssertTrue([filteredUser.userAttributes isKindOfClass:[NSMutableDictionary class]]);
}

- (void)tearDown {
    // Stop the mocks only once the queues that can still reach them are empty: an increment
    // hops onto the message queue and then onto main, and a block landing on a stopped mock
    // raises where XCTest cannot catch it.
    if (self.mockBackendController != nil || self.mockKitContainer != nil) {
        dispatch_sync([MParticle messageQueue], ^{});
        [self mp_drainMainQueue];
        [MParticle sharedInstance].kitContainer_PRIVATE = nil;
        [self.mockKitContainer stopMocking];
        [self.mockBackendController stopMocking];
        self.mockKitContainer = nil;
        self.mockBackendController = nil;
    }
    [super tearDown];
}

// Tests run on the main thread, so spin the run loop rather than block on it.
- (void)mp_drainMainQueue {
    __block BOOL drained = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        drained = YES;
    });
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:kMPUserAttributeForwardTimeout];
    while (!drained && [[NSDate date] compare:deadline] == NSOrderedAscending) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
}

// Installs a backend controller whose increment returns newValue, and a kit container mock to
// record what the user forwards.
- (MParticleUser *)userWithIncrementResult:(NSNumber *)newValue {
    self.mockBackendController = OCMClassMock([MPBackendController_PRIVATE class]);
    OCMStub([self.mockBackendController incrementUserAttribute:OCMOCK_ANY byValue:OCMOCK_ANY]).andReturn(newValue);

    self.mockKitContainer = OCMClassMock([MPKitContainer_PRIVATE class]);
    [MParticle sharedInstance].kitContainer_PRIVATE = self.mockKitContainer;

    MParticleUser *user = [[MParticleUser alloc] init];
    user.backendController = self.mockBackendController;
    return user;
}

// The core returns nil when it refuses an increment: an unusable key or value, or a stored value
// that is not a number. Kits must not be told the attribute changed, and a kit that implements
// only -setUserAttribute:value: must not be handed the nil as the attribute's new value.
- (void)testRefusedIncrementIsNotForwardedToKits {
    MParticleUser *user = [self userWithIncrementResult:nil];

    XCTestExpectation *forwarded = [self expectationWithDescription:@"a refused increment reaches no kit"];
    forwarded.inverted = YES;
    OCMStub([self.mockKitContainer forwardSDKCall:[OCMArg anySelector]
                                 userAttributeKey:OCMOCK_ANY
                                            value:OCMOCK_ANY
                                       kitHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        [forwarded fulfill];
    });

    [user incrementUserAttribute:@"push ups" byValue:@1];

    dispatch_sync([MParticle messageQueue], ^{});
    [self waitForExpectations:@[forwarded] timeout:kMPUserAttributeNoForwardTimeout];
}

// The counterpart: an increment the core accepts still reaches kits both ways - the increment
// itself, and the new total for kits without an increment method - so the guard above cannot
// quietly swallow a successful increment.
- (void)testAcceptedIncrementIsForwardedToKits {
    MParticleUser *user = [self userWithIncrementResult:@5];

    XCTestExpectation *incrementForwarded = [self expectationWithDescription:@"kits receive the increment"];
    OCMStub([self.mockKitContainer forwardSDKCall:@selector(incrementUserAttribute:byValue:)
                                 userAttributeKey:@"push ups"
                                            value:@1
                                       kitHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        [incrementForwarded fulfill];
    });

    XCTestExpectation *newValueForwarded = [self expectationWithDescription:@"kits receive the new total"];
    OCMStub([self.mockKitContainer forwardSDKCall:@selector(setUserAttribute:value:)
                                 userAttributeKey:@"push ups"
                                            value:@5
                                       kitHandler:OCMOCK_ANY]).andDo(^(NSInvocation *invocation) {
        [newValueForwarded fulfill];
    });

    [user incrementUserAttribute:@"push ups" byValue:@1];

    [self waitForExpectations:@[incrementForwarded, newValueForwarded] timeout:kMPUserAttributeForwardTimeout];
}

@end
