#import "MPKitConfiguration.h"
#import "MPIConstants.h"
#import "MPEventProjection.h"
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
    if (!self || MPIsNull(configurationDictionary)) {
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
    [self configureProjections:configurationDictionary[@"pr"]];
    
    // Consent kit filter
    if (configurationDictionary[kMPConsentKitFilter]) {
        _consentKitFilter = [MPConsentSerialization filterFromDictionary:configurationDictionary[kMPConsentKitFilter]];
    }
    
    // Kit instance
    _bracketConfiguration = !MPIsNull(configurationDictionary[kMPRemoteConfigBracketKey]) ? configurationDictionary[kMPRemoteConfigBracketKey] : nil;
    
    _integrationId = !MPIsNull(configurationDictionary[@"id"]) ? configurationDictionary[@"id"] : nil;
    
    if (_integrationId != nil) {
        _configurationDictionary = configurationDictionary;
        _excludeAnonymousUsers = [configurationDictionary[kMPRemoteConfigExcludeAnonymousUsersKey] boolValue];
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
    
    _eventTypeFilters = _filters[@"et"];
    _eventNameFilters = _filters[@"ec"];
    _eventAttributeFilters = _filters[@"ea"];
    _messageTypeFilters = _filters[@"mt"];
    _screenNameFilters = _filters[@"svec"];
    _screenAttributeFilters = _filters[@"svea"];
    _userIdentityFilters = _filters[@"uid"];
    _userAttributeFilters = _filters[@"ua"];
    _commerceEventAttributeFilters = _filters[@"cea"];
    _commerceEventEntityTypeFilters = _filters[@"ent"];
    _commerceEventAppFamilyAttributeFilters = _filters[@"afa"];
    _addEventAttributeList = _filters[@"eaa"];
    _removeEventAttributeList = _filters[@"ear"];
    _singleItemEventAttributeList = _filters[@"eas"];
    _consentRegulationFilters = _filters[kMPConsentRegulationFilters];
    _consentPurposeFilters = _filters[kMPConsentPurposeFilters];
}

#pragma mark Public methods

- (void)configureProjections:(NSArray *)projections {
    _defaultProjections = nil;
    
    if (MPIsNull(projections) || projections.count == 0) {
        _projections = nil;
        return;
    }
    
    NSUInteger numberOfMessageTypes = [MPEnum messageTypeSize];
    NSMutableArray<NSNumber *> *configuredMessageTypeProjectionsArray = [[NSMutableArray alloc] initWithCapacity:numberOfMessageTypes];
    NSMutableArray *defaultProjectionsArray = [[NSMutableArray alloc] initWithCapacity:numberOfMessageTypes];
    NSMutableArray<MPEventProjection *> *projectionsArray = [[NSMutableArray alloc] initWithCapacity:projections.count];
    
    for (NSUInteger i = 0; i < numberOfMessageTypes; ++i) {
        [configuredMessageTypeProjectionsArray addObject:@NO];
        [defaultProjectionsArray addObject:[NSNull null]];
    }
    
    for (NSDictionary *projectionDictionary in projections) {
        MPEventProjection *eventProjection = [[MPEventProjection alloc] initWithConfiguration:projectionDictionary];
        
        if (eventProjection) {
            // message_type comes straight from remote configuration and indexes
            // two arrays holding numberOfMessageTypes entries.
            // -setObject:atIndexedSubscript: allows index == count and appends,
            // which is how MPMessageTypeMedia (20) has always been registered
            // even though +[MPEnum messageTypeSize] is only 20 — so that case is
            // preserved rather than skipped. A larger value, or a negative one
            // that wrapped, is a genuine NSRangeException.
            NSUInteger messageType = eventProjection.messageType;
            if (messageType > numberOfMessageTypes) {
                MPILogError(@"Ignoring projection with out-of-range message type: %@", @(messageType));
                continue;
            }

            configuredMessageTypeProjectionsArray[messageType] = @YES;

            if (eventProjection.isDefault) {
                defaultProjectionsArray[messageType] = eventProjection;
            } else {
                [projectionsArray addObject:eventProjection];
            }
        }
    }
    
    _configuredMessageTypeProjections = configuredMessageTypeProjectionsArray;
    _defaultProjections = defaultProjectionsArray;
    _projections = projectionsArray.count > 0 ? projectionsArray : nil;
}

@end
