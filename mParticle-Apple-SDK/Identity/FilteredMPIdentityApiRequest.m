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
    MPDataPlanFilter *dataPlanFilter = MParticle.sharedInstance.dataPlanFilter;
    return [[[MPIdentityFilteringPRIVATE alloc] init] filterUserIdentities:self.request.identities
                                                      userIdentityFilters:self.kitConfiguration.userIdentityFilters
                                                                isBlocked:^BOOL(NSNumber * _Nonnull key) {
        return [dataPlanFilter isBlockedUserIdentityType:(MPIdentity)key.integerValue];
    }];
}

- (NSString *)email {
    return self.userIdentities[@(MPUserIdentityEmail)];
}

- (NSString *)customerId {
    return self.userIdentities[@(MPUserIdentityCustomerId)];
}

@end
