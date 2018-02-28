#import "MPKitAPI.h"
#import "MPPersistenceController.h"
#import "MPIntegrationAttributes.h"
#import "MPKitContainer.h"
#import "MPILogger.h"

@interface MPAttributionResult ()

@property (nonatomic, readwrite) NSNumber *kitCode;
@property (nonatomic, readwrite) NSString *kitName;

@end

@interface MPKitAPI ()

@property (nonatomic) NSNumber *kitCode;

@end

@implementation MPKitAPI

- (NSString *)kitName {
    __block NSString *component = nil;
    NSSet<id<MPExtensionKitProtocol>> *kits = [MPKitContainer registeredKits];
    NSNumber *kitCode = _kitCode;
    
    if (kits && kitCode) {
        [kits enumerateObjectsUsingBlock:^(id<MPExtensionKitProtocol>  _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.code.intValue == _kitCode.intValue) {
                component = obj.name;
            }
        }];
    }
    
    return component;
}

- (NSString *)logMessageWithFormat:(NSString *)format withParameters:(va_list)valist {
    NSString *formattedOriginalMessage = [[NSString alloc] initWithFormat:format arguments:valist];
    NSString *kitName = [self kitName];
    NSString *prefixedMessage = [NSString stringWithFormat:@"%@ Kit: %@", kitName, formattedOriginalMessage];
    return prefixedMessage;
}

- (void)logError:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogError(@"%@", formattedMessage);
    va_end(args);
}

- (void)logWarning:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogWarning(@"%@", formattedMessage);
    va_end(args);
}

- (void)logDebug:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogDebug(@"%@", formattedMessage);
    va_end(args);
}

- (void)logVerbose:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString* formattedMessage = [self logMessageWithFormat:format withParameters:args];
    MPILogVerbose(@"%@", formattedMessage);
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

- (void)onAttributionCompleteWithResult:(MPAttributionResult *)result error:(NSError *)error {
    if (error || !result) {
        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        if (_kitCode != nil) {
            userInfo[mParticleKitInstanceKey] = _kitCode;
        }
        
        NSString *errorMessage = nil;
        
        if (error) {
            errorMessage = @"mParticle Kit Attribution Error";
            userInfo[NSUnderlyingErrorKey] = error;
        }
        
        if (!result) {
            errorMessage = @"mParticle Kit Attribution handler was called with nil info and no error";
        }
        
        userInfo[MPKitAPIErrorKey] = errorMessage;
        NSError *attributionError = [NSError errorWithDomain:MPKitAPIErrorDomain code:0 userInfo:userInfo];
        [MPKitContainer sharedInstance].attributionCompletionHandler(nil, attributionError);
        return;
    }
    
    result.kitCode = _kitCode;
    result.kitName = [self kitName];
    
    [MPKitContainer sharedInstance].attributionCompletionHandler(result, nil);
}

@end
