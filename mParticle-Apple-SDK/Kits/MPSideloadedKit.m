#import "MPSideloadedKit.h"
#import "mParticle.h"
@import mParticle_Apple_SDK_Swift;

@interface MPSideloadedKit ()

// Filter dictionaries
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *eventTypeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *eventNameFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *eventAttributeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *messageTypeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *screenNameFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *screenAttributeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *userIdentityFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *userAttributeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *commerceEventAttributeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *commerceEventEntityTypeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *commerceEventAppFamilyAttributeFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *attributeValueFiltering;

// MUST also include the following keys with empty dictionaries as the values, or the SDK will crash
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *addEventAttributeList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *removeEventAttributeList;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *singleItemEventAttributeList;

// Consent Filtering being handled separately
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *consentRegulationFilters;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *consentPurposeFilters;

@property (nonatomic, strong) MPIHasher *hasher;

@end

@implementation MPSideloadedKit

- (instancetype)initWithKitInstance:(id<MPKitProtocol>)kitInstance {
    self = [super init];
    if (self) {
        _kitInstance = kitInstance;
        
        // Initialize all filter dictionaries
        _eventTypeFilters = [[NSMutableDictionary alloc] init];
        _eventNameFilters = [[NSMutableDictionary alloc] init];
        _eventAttributeFilters = [[NSMutableDictionary alloc] init];
        _messageTypeFilters = [[NSMutableDictionary alloc] init];
        _screenNameFilters = [[NSMutableDictionary alloc] init];
        _screenAttributeFilters = [[NSMutableDictionary alloc] init];
        _userIdentityFilters = [[NSMutableDictionary alloc] init];
        _userAttributeFilters = [[NSMutableDictionary alloc] init];
        _commerceEventAttributeFilters = [[NSMutableDictionary alloc] init];
        _commerceEventEntityTypeFilters = [[NSMutableDictionary alloc] init];
        _commerceEventAppFamilyAttributeFilters = [[NSMutableDictionary alloc] init];
        _attributeValueFiltering = [[NSMutableDictionary alloc] init];
        
        _addEventAttributeList = [[NSMutableDictionary alloc] init];
        _removeEventAttributeList = [[NSMutableDictionary alloc] init];
        _singleItemEventAttributeList = [[NSMutableDictionary alloc] init];
        
        _consentRegulationFilters = [[NSMutableDictionary alloc] init];
        _consentPurposeFilters = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (MPIHasher *)hasher {
    if (!_hasher) {
        MParticle *mparticle = [MParticle sharedInstance];
        MPLog *logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
        logger.customLogger = mparticle.customLogger;
        _hasher = [[MPIHasher alloc] initWithLogger:logger];
    }
    return _hasher;
}

- (void)addEventTypeFilterWithEventType:(MPEventType)eventType {
    MPEventTypeSwift eventTypeSwift = (MPEventTypeSwift)eventType;
    NSString *hashedValue = [self.hasher hashEventType:eventTypeSwift];
    self.eventTypeFilters[hashedValue] = @0;
}

- (void)addEventNameFilterWithEventType:(MPEventType)eventType eventName:(NSString *)eventName {
    MPEventTypeSwift eventTypeSwift = (MPEventTypeSwift)eventType;
    NSString *hashedValue = [self.hasher hashEventType:eventTypeSwift eventName:eventName isLogScreen:NO];
    self.eventNameFilters[hashedValue] = @0;
}

- (void)addScreenNameFilterWithScreenName:(NSString *)screenName {
    NSString *hashedValue = [self.hasher hashEventType:MPEventTypeSwiftClick eventName:screenName isLogScreen:YES];
    self.eventNameFilters[hashedValue] = @0;
}

- (void)addEventAttributeFilterWithEventType:(MPEventType)eventType eventName:(NSString *)eventName customAttributeKey:(NSString *)customAttributeKey {
    MPEventTypeSwift eventTypeSwift = (MPEventTypeSwift)eventType;
    NSString *hashedValue = [self.hasher hashEventAttributeKey:eventTypeSwift
                                                      eventName:eventName
                                             customAttributeName:customAttributeKey
                                                    isLogScreen:NO];
    self.eventAttributeFilters[hashedValue] = @0;
}

- (void)addScreenAttributeFilterWithScreenName:(NSString *)screenName customAttributeKey:(NSString *)customAttributeKey {
    NSString *hashedValue = [self.hasher hashEventAttributeKey:MPEventTypeSwiftClick
                                                      eventName:screenName
                                             customAttributeName:customAttributeKey
                                                    isLogScreen:YES];
    self.eventAttributeFilters[hashedValue] = @0;
}

- (void)addUserIdentityFilterWithUserIdentity:(MPUserIdentity)userIdentity {
    MPUserIdentitySwift userIdentitySwift = (MPUserIdentitySwift)userIdentity;
    NSString *hashedValue = [self.hasher hashUserIdentity:userIdentitySwift];
    self.userIdentityFilters[hashedValue] = @0;
}

- (void)addUserAttributeFilterWithUserAttributeKey:(NSString *)userAttributeKey {
    NSString *hashedValue = [self.hasher hashUserAttributeKey:userAttributeKey];
    self.userAttributeFilters[hashedValue] = @0;
}

- (void)addCommerceEventAttributeFilterWithEventType:(MPEventType)eventType eventAttributeKey:(NSString *)eventAttributeKey {
    MPEventTypeSwift eventTypeSwift = (MPEventTypeSwift)eventType;
    NSString *hashedValue = [self.hasher hashCommerceEventAttribute:eventTypeSwift key:eventAttributeKey];
    self.commerceEventAttributeFilters[hashedValue] = @0;
}

- (void)addCommerceEventEntityTypeFilterWithCommerceEventKind:(MPCommerceEventKind)commerceEventKind {
    NSString *key = [NSString stringWithFormat:@"%ld", (long)commerceEventKind];
    self.commerceEventEntityTypeFilters[key] = @0;
}

- (void)addCommerceEventAppFamilyAttributeFilterWithAttributeKey:(NSString *)attributeKey {
    NSString *hashedValue = [self.hasher hashString:[attributeKey lowercaseString]];
    self.commerceEventAppFamilyAttributeFilters[hashedValue] = @1;
}

- (void)setEventAttributeConditionalForwardingWithAttributeName:(NSString *)attributeName attributeValue:(NSString *)attributeValue onlyForward:(BOOL)onlyForward {
    self.attributeValueFiltering[@"a"] = [self.hasher hashUserAttributeKey:attributeName];
    self.attributeValueFiltering[@"v"] = [self.hasher hashUserAttributeValue:attributeValue];
    self.attributeValueFiltering[@"i"] = @(onlyForward);
}

- (void)addMessageTypeFilterWithMessageTypeConstant:(NSString *)messageTypeConstant {
    self.messageTypeFilters[messageTypeConstant] = @0;
}

- (NSDictionary<NSString *, id> *)getKitFilters {
    NSMutableDictionary<NSString *, id> *kitFilters = [[NSMutableDictionary alloc] init];
    
    kitFilters[@"et"] = self.eventTypeFilters;
    kitFilters[@"ec"] = self.eventNameFilters;
    kitFilters[@"ea"] = self.eventAttributeFilters;
    kitFilters[@"mt"] = self.messageTypeFilters;
    kitFilters[@"svec"] = self.screenNameFilters;
    kitFilters[@"svea"] = self.screenAttributeFilters;
    kitFilters[@"uid"] = self.userIdentityFilters;
    kitFilters[@"ua"] = self.userAttributeFilters;
    kitFilters[@"cea"] = self.commerceEventAttributeFilters;
    kitFilters[@"ent"] = self.commerceEventEntityTypeFilters;
    kitFilters[@"afa"] = self.commerceEventAppFamilyAttributeFilters;
    kitFilters[@"avf"] = self.attributeValueFiltering;
    
    kitFilters[@"eaa"] = self.addEventAttributeList;
    kitFilters[@"ear"] = self.removeEventAttributeList;
    kitFilters[@"eas"] = self.singleItemEventAttributeList;
    
    kitFilters[@"reg"] = self.consentRegulationFilters;
    kitFilters[@"pur"] = self.consentPurposeFilters;
    
    return [kitFilters copy];
}

@end
