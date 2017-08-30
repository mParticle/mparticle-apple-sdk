#import "MPKitAPI.h"
#import "MPPersistenceController.h"
#import "MPIntegrationAttributes.h"
#import "MPKitContainer.h"

@interface MPKitAPI ()

@property (nonatomic) NSNumber *kitCode;

@end

@implementation MPKitAPI

- (id)initWithKitCode:(NSNumber *)kitCode {
    self = [super init];
    if (self) {
        _kitCode = kitCode;
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)integrationAttributes {
    NSDictionary *dictionary = [[MPKitContainer sharedInstance] integrationAttributesForKit:_kitCode];
    return dictionary;
}

- (NSDictionary<NSNumber *, NSString *> *)userIdentities {
    NSDictionary *dictionary = [[MPKitContainer sharedInstance] userIdentitiesForKit:_kitCode];
    return dictionary;
}

- (NSDictionary<NSString *, id> *)userAttributes {
    NSDictionary *dictionary = [[MPKitContainer sharedInstance] userAttributesForKit:_kitCode];
    return dictionary;
}

@end
