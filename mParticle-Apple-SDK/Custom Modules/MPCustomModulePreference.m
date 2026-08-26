#import "MPCustomModulePreference.h"
#import "MPILogger.h"
#import "MPPersistenceController.h"
#import "mParticle.h"
#import "MPUserDefaultsConnector.h"
@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong, readonly) MPStateMachine_PRIVATE *stateMachine;
@property (nonatomic, strong, nonnull) MPBackendController_PRIVATE *backendController;

@end

@interface MPCustomModulePreference()

@property (nonatomic, strong) NSString *location;

@end


@implementation MPCustomModulePreference

- (instancetype)initWithDictionary:(NSDictionary *)preferenceDictionary location:(NSString *)location moduleId:(NSNumber *)moduleId {
    self = [super init];

    _readKey = preferenceDictionary[kMPRemoteConfigCustomModuleReadKey];
    _writeKey = preferenceDictionary[kMPRemoteConfigCustomModuleWriteKey];

    if (!self || MPIsNull(moduleId) || MPIsNull(_readKey) || MPIsNull(_writeKey)) {
        return nil;
    }
    
    id temp = preferenceDictionary[kMPRemoteConfigCustomModuleDataTypeKey];
    if (!MPIsNull(temp) && [temp isKindOfClass:[NSNumber class]]) {
        _dataType = [(NSNumber *)temp intValue];
    } else {
        _dataType = MPDataTypeString;
    }
    
    _moduleId = [moduleId copy];

    NSString *defaultValue = preferenceDictionary[kMPRemoteConfigCustomModuleDefaultKey];
    
    if ([MPCustomModulePreferenceLogic isMacroPlaceholder:defaultValue]) {
        _defaultValue = [MPCustomModulePreferenceLogic defaultValueForMacroPlaceholder:defaultValue];
    } else if (!MPIsNull(defaultValue) && [defaultValue isKindOfClass:[NSString class]]) {
        _defaultValue = defaultValue;
    } else {
        _defaultValue = [MPCustomModulePreferenceLogic defaultValueForDataType:_dataType];
    }
    
    _location = location;
    
    return self;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.defaultValue forKey:@"defaultValue"];
    [coder encodeObject:self.location forKey:@"location"];
    [coder encodeObject:self.readKey forKey:@"readKey"];
    [coder encodeObject:self.value forKey:@"value"];
    [coder encodeObject:self.writeKey forKey:@"writeKey"];
    [coder encodeInteger:self.dataType forKey:@"dataType"];
    [coder encodeInt64:self.moduleId.longLongValue forKey:@"moduleId"];
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        _defaultValue = [coder decodeObjectOfClass:[NSString class] forKey:@"defaultValue"];
        _location = [coder decodeObjectOfClass:[NSString class] forKey:@"location"];
        _readKey = [coder decodeObjectOfClass:[NSString class] forKey:@"readKey"];
        _value = [coder decodeObjectOfClass:[NSObject class] forKey:@"value"];
        _writeKey = [coder decodeObjectOfClass:[NSString class] forKey:@"writeKey"];
        _dataType = [coder decodeIntegerForKey:@"dataType"];
        _moduleId = @([coder decodeInt64ForKey:@"moduleId"]);
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark Public methods
- (id)value {
    MPUserDefaults *userDefaults = MPUserDefaultsConnector.userDefaults;
    
    NSString *deprecatedKey = [NSString stringWithFormat:@"cms::%@", self.writeKey];
    NSString *customModuleKey = [NSString stringWithFormat:@"cms::%@::%@", self.moduleId, self.writeKey];
    NSNumber *mpId = [MPPersistenceController_PRIVATE mpId];
    id valueWithDeprecatedKey = [userDefaults mpObjectForKey:deprecatedKey userId:mpId];
    if (valueWithDeprecatedKey) {
        _value = valueWithDeprecatedKey;
        [userDefaults setMPObject:_value forKey:customModuleKey userId:mpId];
        [userDefaults removeMPObjectForKey:deprecatedKey userId:mpId];
        return _value;
    }
    _value = [userDefaults mpObjectForKey:customModuleKey userId:mpId];
    if (_value) {
        return _value;
    }
    
    NSDictionary *userDefaultsDictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    NSArray *keys = [userDefaultsDictionary allKeys];

    if ([keys containsObject:self.readKey]) {
        id storedValue = [[NSUserDefaults standardUserDefaults] objectForKey:_readKey];
        if (!MPIsNull(storedValue)) {
            _value = [storedValue isKindOfClass:[NSDate class]] ? [MPDateFormatter stringFromDateRFC3339:storedValue] : storedValue;
        }
        
        if (!_value && _dataType != MPDataTypeString) {
            switch (_dataType) {
                case MPDataTypeInt:
                case MPDataTypeLong:
                    _value = @([[NSUserDefaults standardUserDefaults] integerForKey:_readKey]);
                    break;
                    
                case MPDataTypeBool:
                    _value = @([[NSUserDefaults standardUserDefaults] boolForKey:_readKey]);
                    break;
                    
                case MPDataTypeFloat:
                    _value = @([[NSUserDefaults standardUserDefaults] floatForKey:_readKey]);
                    break;
                    
                default:
                    _value = self.defaultValue;
                    break;
            }
        }
    } else {
        _value = [MPCustomModulePreferenceLogic valueForDefaultValue:self.defaultValue dataType:self.dataType];
    }
    [userDefaults setMPObject:_value forKey:customModuleKey userId:mpId];
    
    return _value;
}

@end
