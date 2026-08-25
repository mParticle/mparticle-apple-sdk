#import "FilteredMParticleUser.h"
#import "mParticle.h"
#import "MParticleUser.h"
#import "MPStateMachine.h"
#import "MPKitConfiguration.h"
#import "MPDataPlanFilter.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong) id<MPDataPlanFilterProtocol> dataPlanFilter;
@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;

@end

@interface FilteredMParticleUser ()

@property (nonatomic, strong) MParticleUser *user;

@property (nonatomic, strong) MPKitConfiguration *kitConfiguration;

@end

@implementation FilteredMParticleUser

- (instancetype)initWithMParticleUser:(MParticleUser *)user kitConfiguration:(MPKitConfiguration *)kitConfiguration {
    self = [super init];
    if (self) {
        _user = user;
        _kitConfiguration = kitConfiguration;
    }

    return self;
}

-(NSNumber *)userId {
    return self.user.userId;
}

-(BOOL)isLoggedIn {
    return self.user.isLoggedIn;
}

-(NSString *)idfa {
    NSNumber *currentStatus = [MParticle sharedInstance].stateMachine.attAuthorizationStatus;
    if (currentStatus != nil && currentStatus.integerValue == MPATTAuthorizationStatusAuthorized) {
        return self.user.identities[@(MPIdentityIOSAdvertiserId)];
    }
    return nil;
}

-(NSString *)idfv {
    return self.user.identities[@(MPIdentityIOSVendorId)];
}

-(NSDictionary<NSNumber *, NSString *> *) userIdentities {
    NSDictionary<NSNumber *, NSString *> *identities = self.user.identities;
    // Nothing to filter: return before reading kitConfiguration, which some kit callers pass as a raw NSDictionary.
    if (identities.count == 0) {
        return @{};
    }
    id<MPDataPlanFilterProtocol> dataPlanFilter = MParticle.sharedInstance.dataPlanFilter;
    return [[[MPIdentityFilteringPRIVATE alloc] init] filterUserIdentities:identities
                                                      userIdentityFilters:self.kitConfiguration.userIdentityFilters
                                                                isBlocked:^BOOL(NSNumber * _Nonnull key) {
        return [dataPlanFilter isBlockedUserIdentityType:(MPIdentity)key.intValue];
    }];
}

-(NSDictionary<NSString *, id> *) userAttributes {
    NSDictionary<NSString *, id> *attributes = self.user.userAttributes;
    // Nothing to filter: return before reading kitConfiguration, which some kit callers pass as a raw NSDictionary.
    if (attributes.count == 0) {
        return @{};
    }
    MParticle *mparticle = MParticle.sharedInstance;
    MPLog *logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    MPIHasher *hasher = [[MPIHasher alloc] initWithLogger:logger];
    id<MPDataPlanFilterProtocol> dataPlanFilter = mparticle.dataPlanFilter;

    return [[[MPIdentityFilteringPRIVATE alloc] init] filterUserAttributes:attributes
                                                      userAttributeFilters:self.kitConfiguration.userAttributeFilters
                                                                    hasher:hasher
                                                                 isBlocked:^BOOL(NSString * _Nonnull key) {
        return [dataPlanFilter isBlockedUserAttributeKey:key];
    }];
}

@end
