#import "MPBaseProjection.h"
@import mParticle_Apple_SDK_Swift;

@implementation MPBaseProjection

@synthesize name = _name;
@synthesize projectedName = _projectedName;
@synthesize matchType = _matchType;
@synthesize projectionType = _projectionType;
@synthesize propertyKind = _propertyKind;
@synthesize projectionId = _projectionId;

- (instancetype)initWithConfiguration:(NSDictionary *)configuration projectionType:(MPProjectionType)projectionType attributeIndex:(NSUInteger)attributeIndex {
    self = [super init];
    NSDictionary *actionDictionary = [MPProjectionFieldParser actionFromConfiguration:configuration];

    if (!self || !actionDictionary) {
        return nil;
    }

    _configuration = configuration;
    _attributeIndex = attributeIndex;
    _projectionType = projectionType;

    MPProjectionFields *fields = nil;

    switch (projectionType) {
        case MPProjectionTypeAttribute:
            fields = [MPProjectionFieldParser attributeFieldsFromAction:actionDictionary attributeIndex:attributeIndex];
            if (!fields) {
                return nil;
            }
            break;

        case MPProjectionTypeEvent:
            _projectionId = [MPProjectionFieldParser projectionIdFromConfiguration:configuration];
            fields = [MPProjectionFieldParser eventFieldsFromConfiguration:configuration action:actionDictionary];
            break;

        default:
            break;
    }

    if (fields) {
        _name = fields.name;
        _projectedName = fields.projectedName;
        _propertyKind = (MPProjectionPropertyKind)fields.propertyKind;
        _matchType = (MPProjectionMatchType)fields.matchType;
    }

    return self;
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = [object isKindOfClass:[self class]];
    
    if (isEqual) {
        MPBaseProjection *baseProjection = (MPBaseProjection *)object;
        
        isEqual = [_name isEqualToString:baseProjection.name] &&
                  [_projectedName isEqualToString:baseProjection.projectedName] &&
                  _matchType == baseProjection.matchType &&
                  _projectionType == baseProjection.projectionType;
    }
    
    return isEqual;
}

- (NSUInteger)hash {
    return [self.name hash] ^ [self.projectedName hash] ^ self.matchType ^ self.projectionType;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] init];
    
    if (_name) {
        [description appendFormat:@" name: %@\n", _name];
    }
    
    if (_projectedName) {
        [description appendFormat:@" projected name: %@\n", _projectedName];
    }
    
    NSString *matchType;
    switch (_matchType) {
        case MPProjectionMatchTypeString:
            matchType = @"String";
            break;
            
        case MPProjectionMatchTypeHash:
            matchType = @"Hash";
            break;

        case MPProjectionMatchTypeField:
            matchType = @"Field";
            break;

        case MPProjectionMatchTypeStatic:
            matchType = @"Static";
            break;
            
        case MPProjectionMatchTypeNotSpecified:
            matchType = @"Not Specified";
            break;
        default:
            break;
    }
    [description appendFormat:@" matchType: %@\n", matchType];
    
    NSString *projectionType;
    switch (_projectionType) {
        case MPProjectionTypeAttribute:
            projectionType = @"Attribute";
            break;
            
        case MPProjectionTypeEvent:
            projectionType = @"Event";
            break;
    }
    [description appendFormat:@" projectionType: %@\n", projectionType];
    
    NSString *propertyKind;
    switch (_propertyKind) {
        case MPProjectionPropertyKindEventField:
            propertyKind = @"Event Field";
            break;
            
        case MPProjectionPropertyKindEventAttribute:
            propertyKind = @"Event Attribute";
            break;
            
        case MPProjectionPropertyKindProductField:
            propertyKind = @"Product Field";
            break;
            
        case MPProjectionPropertyKindProductAttribute:
            propertyKind = @"Product Attribute";
            break;
            
        case MPProjectionPropertyKindPromotionField:
            propertyKind = @"Promotion Field";
            break;
            
        case MPProjectionPropertyKindPromotionAttribute:
            propertyKind = @"Promotion Attribute";
            break;
            
        default:
            break;
    }
    [description appendFormat:@" propertyKind: %@\n", propertyKind];
    
    return (NSString *)description;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.name) {
        [coder encodeObject:_name forKey:@"name"];
    }
    
    if (self.projectedName) {
        [coder encodeObject:_projectedName forKey:@"projectedName"];
    }
    
    [coder encodeObject:_configuration forKey:@"configuration"];
    [coder encodeInteger:_matchType forKey:@"matchType"];
    [coder encodeInteger:_projectionType forKey:@"projectionType"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:_propertyKind] forKey:@"propertyKind"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:_projectionId] forKey:@"projectionId"];
    [coder encodeObject:[NSNumber numberWithUnsignedInteger:_attributeIndex] forKey:@"attributeIndex"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];

    if (self) {
        [coder decodeObjectOfClass:[NSNumber class] forKey:@"propertyKind"];
        _configuration = [coder decodeObjectOfClass:[NSDictionary class] forKey:@"configuration"];
        _name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
        _projectedName = [coder decodeObjectOfClass:[NSString class] forKey:@"projectedName"];
        _matchType = (MPProjectionMatchType)[coder decodeIntegerForKey:@"matchType"];
        _projectionType = (MPProjectionType)[coder decodeIntegerForKey:@"projectionType"];
        _propertyKind = (MPProjectionPropertyKind)[[coder decodeObjectOfClass:[NSNumber class] forKey:@"propertyKind"] unsignedIntegerValue];
        _projectionId = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"projectionId"] unsignedIntegerValue];
        _attributeIndex = [[coder decodeObjectOfClass:[NSNumber class] forKey:@"attributeIndex"] unsignedIntegerValue];
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPBaseProjection *copyObject = [[[self class] alloc] init];
    
    if (copyObject) {
        copyObject.name = [_name copy];
        copyObject.projectedName = [_projectedName copy];
        copyObject.matchType = _matchType;
        copyObject->_configuration = [_configuration copy];
        copyObject->_projectionType = _projectionType;
        copyObject->_propertyKind = _propertyKind;
        copyObject->_projectionId = _projectionId;
        copyObject->_attributeIndex = _attributeIndex;
    }
    
    return copyObject;
}

@end
