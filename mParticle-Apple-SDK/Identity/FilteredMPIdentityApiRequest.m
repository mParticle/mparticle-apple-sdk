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
    NSDictionary<NSNumber *, NSObject *> *unfilteredUserIdentities = self.request.identities;
    NSMutableDictionary *filteredUserIdentities = [NSMutableDictionary dictionary];
    
    for (NSNumber* key in unfilteredUserIdentities) {
        id value = [unfilteredUserIdentities objectForKey:key];
        BOOL shouldFilter = NO;
        
        if (self.kitConfiguration) {
            NSString *identityTypeString = [[NSString alloc] initWithFormat:@"%lu", key.unsignedLongValue];
            shouldFilter = self.kitConfiguration.userIdentityFilters[identityTypeString] && [self.kitConfiguration.userIdentityFilters[identityTypeString] isEqualToNumber:@0];
        }
        
        if (key.integerValue >= MPIdentityIOSAdvertiserId) {
            shouldFilter = YES;
        }
        
        if (!shouldFilter) {
            if (![MParticle.sharedInstance.dataPlanFilter isBlockedUserIdentityType:(MPIdentity)key.integerValue]) {
                [filteredUserIdentities setObject:value forKey:key];
            }
        }
    }
    
    return filteredUserIdentities;
}

- (NSString *)email {
    return self.userIdentities[@(MPUserIdentityEmail)];
}

- (NSString *)customerId {
    return self.userIdentities[@(MPUserIdentityCustomerId)];
}

@end
