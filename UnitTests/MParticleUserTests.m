//
//  MParticleUserTests.m
//

#import <XCTest/XCTest.h>
#import "mParticle.h"
#import "MPBaseTestCase.h"

#import "MPBackendController.h"

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


@end
