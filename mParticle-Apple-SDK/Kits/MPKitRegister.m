#import "MPKitRegister.h"
#import "MPIConstants.h"
#import "MPILogger.h"
#import "mParticle.h"

@implementation MPKitRegister

- (instancetype)init {
    id invalidVar = nil;
    self = [self initWithName:invalidVar className:invalidVar];
    if (self) {
        MPILogError(@"MPKitRegister cannot be initialized using the init method");
    }
    
    return nil;
}

- (nullable instancetype)initWithName:(nonnull NSString *)name className:(nonnull NSString *)className {
    Class stringClass = [NSString class];
    BOOL validName = !MPIsNull(name) && [name isKindOfClass:stringClass];
    NSAssert(validName, @"The 'name' variable is not valid.");
    
    BOOL validClassName = !MPIsNull(className) && [className isKindOfClass:stringClass];
    NSAssert(validClassName, @"The 'className' variable is not valid.");
    
    self = [super init];
    if (!self || !validName || !validClassName) {
        return nil;
    }
    
    _name = name;
    _className = className;
    _code = [(id<MPKitProtocol>)NSClassFromString(_className) kitCode];
    
    _wrapperInstance = nil;

    return self;
}

- (nullable instancetype)initWithInstance:(nonnull NSObject<MPKitProtocol> *)instance kitCode:(nonnull NSNumber *)kitCode {
    NSString *className = NSStringFromClass([instance class]);
    self = [self initWithName:className className:className];
    if (!self || MPIsNull(className) || MPIsNull(instance)) {
        return nil;
    }
    
    // All sideloaded kits have an internally generated code in a specified range determined by MPKitContainer
    _code = kitCode;
    
    // Use the already initialized instance instead of creating one later
    _wrapperInstance = instance;
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"%@ {\n", [self class]];
    [description appendFormat:@"    code: %@,\n", _code];
    [description appendFormat:@"    name: %@,\n", _name];
    [description appendString:@"}"];
    
    return description;
}

- (NSUInteger)hash {
    return _code.hash ^ _className.hash ^ _name.hash;
}

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![super isEqual:other]) {
        return NO;
    } else {
        MPKitRegister *otherRegister = other;
        return [_code isEqualToNumber:otherRegister.code]
            && [_className isEqualToString:otherRegister.className]
            && [_name isEqualToString:otherRegister.name];
    }
}

- (void)setWrapperInstance:(id<MPKitProtocol>)wrapperInstance {
    _wrapperInstance = wrapperInstance;
}

@end
