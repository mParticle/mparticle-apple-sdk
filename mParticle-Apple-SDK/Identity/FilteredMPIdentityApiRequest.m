//
//  FilteredMPIdentityApiRequest.m
//

#import "FilteredMPIdentityApiRequest.h"
#import "MPNotificationController.h"
#import "MPIConstants.h"
#import "MParticleUser.h"
#import "MPKitConfiguration.h"
#import "MPIdentityApiRequest.h"
#import "MPDataPlanFilter.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong) MPDataPlanFilter *dataPlanFilter;

@end

@interface FilteredMPIdentityApiRequest ()

@property (nonatomic, strong) MPIdentityApiRequest *request;

@property (nonatomic, strong) MPKitConfiguration *kitConfiguration;

@end

@implementation FilteredMPIdentityApiRequest

- (instancetype)initWithIdentityRequest:(MPIdentityApiRequest *)request kitConfiguration:(MPKitConfiguration *)kitConfiguration {
    self = [super init];
    if (self) {
        _kitConfiguration = kitConfiguration;
        _request = request;
    }
    return self;
}

- (NSDictionary<NSNumber *,NSString *> *)userIdentities {
    NSDictionary<NSNumber *, NSObject *> *identities = self.request.identities;
    // Nothing to filter: return before reading kitConfiguration, which some kit callers pass as a raw NSDictionary.
    if (identities.count == 0) {
        return [NSMutableDictionary dictionary];
    }
    MPDataPlanFilter *dataPlanFilter = MParticle.sharedInstance.dataPlanFilter;
    NSDictionary<NSNumber *, NSString *> *filtered = [[[MPIdentityFilteringPRIVATE alloc] init] filterUserIdentities:identities
                                                      userIdentityFilters:self.kitConfiguration.userIdentityFilters
                                                                isBlocked:^BOOL(NSNumber * _Nonnull key) {
        return [dataPlanFilter isBlockedUserIdentityType:(MPIdentity)key.integerValue];
    }];
    // Preserve the pre-migration NSMutableDictionary return type.
    return filtered.mutableCopy;
}

- (NSString *)email {
    return self.userIdentities[@(MPUserIdentityEmail)];
}

- (NSString *)customerId {
    return self.userIdentities[@(MPUserIdentityCustomerId)];
}

@end
