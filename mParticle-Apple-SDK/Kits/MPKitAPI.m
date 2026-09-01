#import "MPKitAPI.h"
#import "MPAttributionResult+MParticlePrivate.h"
#import "MPKitContainer+MParticlePrivate.h"
#import "FilteredMParticleUser.h"
#import "mParticle.h"

@import mParticle_Apple_SDK_Swift;

@interface MParticle ()

@property (nonatomic, strong) MPKitContainer_PRIVATE *kitContainer_PRIVATE;

@end

@interface MPKitContainer_PRIVATE ()

@property (nonatomic, strong, readonly) NSMutableDictionary<NSNumber *, MPKitConfiguration *> *kitConfigurations;

@end

@interface MPKitAPI ()

@property (nonatomic) NSNumber *kitCode;

@end

@implementation MPKitAPI

- (NSString *)kitName {
    __block NSString *component = nil;
    NSSet<id<MPExtensionKitProtocol>> *kits = [MPKitContainer_PRIVATE registeredKits];
    NSNumber *kitCode = _kitCode;
    
    if (kits && kitCode) {
        // No *stop = YES: on duplicate codes the last match wins, as it always has.
        [kits enumerateObjectsUsingBlock:^(id<MPExtensionKitProtocol> _Nonnull obj, __unused BOOL * _Nonnull stop) {
            if (obj.code.intValue == kitCode.intValue) {
                component = obj.name;
            }
        }];
    }

    return component;
}

- (void)emitLogWithMessageLevel:(MPILogLevelSwift)messageLevel format:(NSString *)format parameters:(va_list)valist {
    MParticle *mparticle = MParticle.sharedInstance;
    NSString *message = [[NSString alloc] initWithFormat:format arguments:valist];

    [MPKitAPIHelper emitKitLogWithKitName:[self kitName]
                                 message:message
                            messageLevel:messageLevel
                         currentLogLevel:mparticle.logLevel
                            customLogger:mparticle.customLogger];
}

- (void)logError:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self emitLogWithMessageLevel:MPILogLevelSwiftError format:format parameters:args];
    va_end(args);
}

- (void)logWarning:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self emitLogWithMessageLevel:MPILogLevelSwiftWarning format:format parameters:args];
    va_end(args);
}

- (void)logDebug:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self emitLogWithMessageLevel:MPILogLevelSwiftDebug format:format parameters:args];
    va_end(args);
}

- (void)logVerbose:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    [self emitLogWithMessageLevel:MPILogLevelSwiftVerbose format:format parameters:args];
    va_end(args);
}

- (id)initWithKitCode:(NSNumber *)kitCode {
    self = [super init];
    if (self) {
        _kitCode = kitCode;
    }
    return self;
}

- (NSDictionary<NSString *, NSString *> *)integrationAttributes {
    NSDictionary *dictionary = [[MParticle sharedInstance].kitContainer_PRIVATE integrationAttributesForKit:_kitCode];
    return dictionary;
}

- (void)onAttributionCompleteWithResult:(MPAttributionResult *)result error:(NSError *)error {
    NSError *attributionError = [MPKitAPIHelper attributionErrorForError:error
                                                              hasResult:result != nil
                                                                kitCode:_kitCode];
    if (attributionError) {
        [MParticle sharedInstance].kitContainer_PRIVATE.attributionCompletionHandler(nil, attributionError);
        return;
    }

    result.kitCode = _kitCode;
    result.kitName = [self kitName];

    [MParticle sharedInstance].kitContainer_PRIVATE.attributionCompletionHandler(result, nil);
}

#pragma mark Kit Identity methods

- (FilteredMParticleUser *_Nonnull)getCurrentUserWithKit:(id<MPKitProtocol> _Nonnull)kit {
    return [[FilteredMParticleUser alloc] initWithMParticleUser:[[[MParticle sharedInstance] identity] currentUser] kitConfiguration:[MParticle sharedInstance].kitContainer_PRIVATE.kitConfigurations[[[kit class] kitCode]]];
}

- (nullable NSNumber *)incrementUserAttribute:(NSString *_Nonnull)key byValue:(NSNumber *_Nonnull)value forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    return [selectedUser incrementUserAttribute:key byValue:value];
}

- (void)setUserAttribute:(NSString *_Nonnull)key value:(id _Nonnull)value forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    [selectedUser setUserAttribute:key value:value];
}

- (void)setUserAttributeList:(NSString *_Nonnull)key values:(NSArray<NSString *> *_Nonnull)values forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    [selectedUser setUserAttributeList:key values:values];
    
}

- (void)setUserTag:(NSString *_Nonnull)tag forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    [selectedUser setUserTag:tag];
}

- (void)removeUserAttribute:(NSString *_Nonnull)key forUser:(FilteredMParticleUser *_Nonnull)filteredUser {
    MParticleUser *selectedUser = [[[MParticle sharedInstance] identity] getUser:filteredUser.userId];
    
    [selectedUser removeUserAttribute:key];
}

#pragma mark - Date Formatting

+ (NSString *)stringFromDateRFC3339:(NSDate *)date {
    return [MPDateFormatter stringFromDateRFC3339:date];
}


+ (NSDate *)dateFromStringRFC3339:(NSString *)string {
    return [MPDateFormatter dateFromStringRFC3339:string];
}

+ (NSString *_Nullable)hashString:(NSString * _Nonnull)string {
    MParticle *mparticle = MParticle.sharedInstance;
    return [MPKitAPIHelper hashString:string logLevel:mparticle.logLevel customLogger:mparticle.customLogger];
}

@end
