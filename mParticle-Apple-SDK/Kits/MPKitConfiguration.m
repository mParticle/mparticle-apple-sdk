#import "MPKitConfiguration.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "MPConsentSerialization.h"
#import "mParticle.h"
#import "MPEnums.h"
@import mParticle_Apple_SDK_Swift;

@interface MPKitConfiguration()
@property (nonatomic, strong) NSDictionary *configurationDictionary;
@end


@implementation MPKitConfiguration

@synthesize configurationDictionary = _configurationDictionary;

- (instancetype)initWithDictionary:(NSDictionary *)configurationDictionary {
    self = [super init];
    // A kit entry reaches here straight from parsed or unarchived configuration, so its type is
    // only known now. Every read below, starting with the configuration hash, assumes an object.
    if (!self || ![configurationDictionary isKindOfClass:[NSDictionary class]] ||
        ![NSJSONSerialization isValidJSONObject:configurationDictionary]) {
        return nil;
    }
    
    NSJSONWritingOptions options = 0;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        options = NSJSONWritingSortedKeys;
    }
    NSData *ekConfigData = [NSJSONSerialization dataWithJSONObject:configurationDictionary options:options error:nil];
    NSString *ekConfigString = [[NSString alloc] initWithData:ekConfigData encoding:NSUTF8StringEncoding];
    MParticle* mparticle = MParticle.sharedInstance;
    MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
    logger.customLogger = mparticle.customLogger;
    MPIHasher* hasher = [[MPIHasher alloc] initWithLogger:logger];
    _configurationHash = @([[hasher hashString:ekConfigString] intValue]);
    
    // Attribute value filtering
    MPAttributeValueFilterConfig *attributeValueFilter = [MPKitConfigurationParser attributeValueFilterFromConfiguration:configurationDictionary];
    if (attributeValueFilter.isActive) {
        _attributeValueFilteringIsActive = YES;
        _attributeValueFilteringShouldIncludeMatches = attributeValueFilter.shouldIncludeMatches;
        _attributeValueFilteringHashedAttribute = attributeValueFilter.hashedAttribute;
        _attributeValueFilteringHashedValue = attributeValueFilter.hashedValue;
    }
    
    // Filters
    [self setFilters:configurationDictionary[kMPRemoteConfigKitHashesKey]];
    
    // Configuration
    _configuration = [MPKitConfigurationParser mergedConfigurationFrom:configurationDictionary[@"as"]
                                                 addEventAttributeList:_addEventAttributeList
                                              removeEventAttributeList:_removeEventAttributeList
                                          singleItemEventAttributeList:_singleItemEventAttributeList];
    
    // Projections
    [self configureProjections:configurationDictionary[@"pr"]
                       factory:[[MPKitProjectionSnapshotFactory alloc] initWithHasher:hasher logger:logger]];
    
    // Consent kit filter
    if (configurationDictionary[kMPConsentKitFilter]) {
        _consentKitFilter = [MPConsentSerialization filterFromDictionary:configurationDictionary[kMPConsentKitFilter]];
    }
    
    // Kit instance
    // The container subscripts bracketConfiguration for lo/hi and keys kitConfigurations by
    // integrationId, comparing it with isEqualToNumber:, so neither tolerates another type.
    id bracketConfiguration = configurationDictionary[kMPRemoteConfigBracketKey];
    _bracketConfiguration = [bracketConfiguration isKindOfClass:[NSDictionary class]] ? bracketConfiguration : nil;
    
    id integrationId = configurationDictionary[@"id"];
    _integrationId = [integrationId isKindOfClass:[NSNumber class]] ? integrationId : nil;
    
    if (_integrationId != nil) {
        _configurationDictionary = configurationDictionary;
        // NSNumber and NSString both answer boolValue and remote configuration uses either
        // interchangeably; nothing else does, so reading it would raise rather than return.
        id excludeAnonymousUsers = configurationDictionary[kMPRemoteConfigExcludeAnonymousUsersKey];
        _excludeAnonymousUsers = ([excludeAnonymousUsers isKindOfClass:[NSNumber class]] ||
                                  [excludeAnonymousUsers isKindOfClass:[NSString class]])
            ? [excludeAnonymousUsers boolValue]
            : NO;
    } else {
        return nil;
    }
    
    return self;
}

- (BOOL)isEqual:(MPKitConfiguration *)object {
    return [_configurationHash isEqualToNumber:object.configurationHash];
}

- (NSUInteger)hash {
    return [self.configurationHash hash];
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.configurationDictionary forKey:@"configurationDictionary"];
}

- (id)initWithCoder:(NSCoder *)coder {
    NSDictionary *configurationDictionary;
    
    @try {
        configurationDictionary = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"configurationDictionary"];
    }
    @catch ( NSException *e) {
        configurationDictionary = nil;
        MPILogError(@"Exception decoding MPKitConfiguration Attributes: %@", [e reason]);
    }
    
    self = [self initWithDictionary:configurationDictionary];
    if (!self) {
        return nil;
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPKitConfiguration *copyObject = [[MPKitConfiguration alloc] initWithDictionary:_configurationDictionary];

    return copyObject;
}

#pragma mark Public accessors
- (void)setFilters:(NSDictionary *)filters {
    if (_filters && [_filters isEqualToDictionary:filters]) {
        return;
    }
    
    _filters = [MPKitConfigurationParser sanitizedFiltersFrom:filters];
    
    _eventTypeFilters = [self subFilterForKey:@"et"];
    _eventNameFilters = [self subFilterForKey:@"ec"];
    _eventAttributeFilters = [self subFilterForKey:@"ea"];
    _messageTypeFilters = [self subFilterForKey:@"mt"];
    _screenNameFilters = [self subFilterForKey:@"svec"];
    _screenAttributeFilters = [self subFilterForKey:@"svea"];
    _userIdentityFilters = [self subFilterForKey:@"uid"];
    _userAttributeFilters = [self subFilterForKey:@"ua"];
    _commerceEventAttributeFilters = [self subFilterForKey:@"cea"];
    _commerceEventEntityTypeFilters = [self subFilterForKey:@"ent"];
    _commerceEventAppFamilyAttributeFilters = [self subFilterForKey:@"afa"];
    _addEventAttributeList = [self subFilterForKey:@"eaa"];
    _removeEventAttributeList = [self subFilterForKey:@"ear"];
    _singleItemEventAttributeList = [self subFilterForKey:@"eas"];
    _consentRegulationFilters = [self subFilterForKey:kMPConsentRegulationFilters];
    _consentPurposeFilters = [self subFilterForKey:kMPConsentPurposeFilters];
}

/// sanitizedFiltersFrom: types the filter container but not its members, and every property above
/// is declared NSDictionary and subscripted by its consumers, so a wrong-typed member is dropped
/// rather than published under a type it does not have.
- (NSDictionary *)subFilterForKey:(NSString *)key {
    id subFilter = _filters[key];
    return [subFilter isKindOfClass:[NSDictionary class]] ? subFilter : nil;
}

#pragma mark Public methods

- (void)configureProjections:(NSArray *)projections factory:(MPKitProjectionSnapshotFactory *)factory {
    MPKitProjectionSet *projectionSet =
        [factory projectionSetFromConfigurations:(!MPIsNull(projections) ? projections : nil)
                                messageTypeCount:[MPEnum messageTypeSize]];

    _configuredMessageTypeProjections = projectionSet.configuredMessageTypeProjections;
    _defaultProjections = projectionSet.defaultProjections;
    _projections = projectionSet.projections;
}

@end
