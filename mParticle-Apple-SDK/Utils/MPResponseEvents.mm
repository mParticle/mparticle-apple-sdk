#import "MPResponseEvents.h"
#import "MPConsumerInfo.h"
#import "MPIConstants.h"
#import "MPPersistenceController.h"
#import "MPStateMachine.h"
#import "MPIUserDefaults.h"
#import "MPSession.h"

@implementation MPResponseEvents

+ (void)parseConfiguration:(NSDictionary *)configuration session:(MPSession *)session {
    if (MPIsNull(configuration) || MPIsNull(configuration[kMPMessageTypeKey])) {
        return;
    }
    
    MPPersistenceController *persistence = [MPPersistenceController sharedInstance];

    // Consumer Information
    if (session) {
        MPConsumerInfo *consumerInfo = [MPStateMachine sharedInstance].consumerInfo;
        [consumerInfo updateWithConfiguration:configuration[kMPRemoteConfigConsumerInfoKey]];
        [persistence updateConsumerInfo:consumerInfo];
        [persistence fetchConsumerInfoForUserId:[MPPersistenceController mpId] completionHandler:^(MPConsumerInfo *consumerInfo) {
            [MPStateMachine sharedInstance].consumerInfo = consumerInfo;
        }];
    }
    
    // LTV
    NSNumber *increasedLTV = !MPIsNull(configuration[kMPIncreasedLifeTimeValueKey]) ? configuration[kMPIncreasedLifeTimeValueKey] : nil;
    if (increasedLTV != nil) {
        MPIUserDefaults *userDefaults = [MPIUserDefaults standardUserDefaults];
        NSNumber *ltv = userDefaults[kMPLifeTimeValueKey];
        
        if (ltv != nil) {
            ltv = @([ltv doubleValue] + [increasedLTV doubleValue]);
        } else {
            ltv = increasedLTV;
        }
        
        userDefaults[kMPLifeTimeValueKey] = ltv;
    }
}

@end
