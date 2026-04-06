#import "MPKitAdjust.h"
#import <AdjustSdk/Adjust.h>
#import <AdjustSdk/ADJConfig.h>
#import <AdjustSdk/ADJAttribution.h>

static NSObject<AdjustDelegate> *temporaryDelegate = nil;
static BOOL didSetKitDelegate = NO;

static NSString *const adjustDeviceIdentifierIntegrationAttributeKey = @"adid";
NSString *const MPKitAdjustAttributionResultKey = @"mParticle-Adjust Attribution Result";
NSString *const MPKitAdjustErrorKey = @"mParticle-Adjust Error";
NSString *const MPKitAdjustErrorDomain = @"mParticle-Adjust";

@interface MPKitAdjust()

@property (nonatomic, strong) ADJConfig *adjustConfig;
@property (nonatomic) BOOL hasSetADID;

@end


@implementation MPKitAdjust

+ (void)setDelegate:(id)delegate {
    if (didSetKitDelegate) {
        NSLog(@"Warning: Adjust delegate can not be set because it is already in use by kit. \
              If you'd like to set your own delegate, please do so before you initialize mParticle.\
              Note: When setting your own delegate, you will not be able to use \
              `onAttributionComplete`.");
        return;
    } else {
        temporaryDelegate = (NSObject<AdjustDelegate> *)delegate;
    }
}

+ (NSNumber *)kitCode {
    return @68;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Adjust" className:@"MPKitAdjust"];
    [MParticle registerExtension:kitRegister];
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    
    NSString *appToken = configuration[@"appToken"];
    if (!appToken) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    _configuration = configuration;
    NSString *adjEnvironment = [MParticle sharedInstance].environment == MPEnvironmentProduction ? ADJEnvironmentProduction : ADJEnvironmentSandbox;
    static dispatch_once_t adjustPredicate;
    
    
    
    dispatch_once(&adjustPredicate, ^{
        CFTypeRef adjustConfigRef = CFRetain((__bridge CFTypeRef)[[ADJConfig alloc] initWithAppToken:appToken
                                                                                         environment:adjEnvironment]);
        self->_adjustConfig = (__bridge ADJConfig *)adjustConfigRef;
        
        NSObject<AdjustDelegate> *delegate = nil;
        if (temporaryDelegate) {
            delegate = temporaryDelegate;
        } else {
            delegate = (NSObject<AdjustDelegate> *)self;
            didSetKitDelegate = YES;
        }
        
        self->_adjustConfig.delegate = delegate;
        
        [Adjust initSdk:self->_adjustConfig];
        self->_started = YES;
        
        [Adjust adidWithCompletionHandler:^(NSString * _Nullable adid) {
            if (adid != nil && adid.length > 0) {
                [[MParticle sharedInstance] setIntegrationAttributes:@{adjustDeviceIdentifierIntegrationAttributeKey: adid} forKit:[[self class] kitCode]];
                self->_hasSetADID = YES;
            }
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (id const)providerKitInstance {
    return [self started] ? self : nil;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    if (optOut) {
        [Adjust disable];
    } else {
        [Adjust enable];
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Adjust setPushToken:deviceToken];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (NSError *)errorWithMessage:(NSString *)message {
    NSError *error = [NSError errorWithDomain:MPKitAPIErrorDomain code:0 userInfo:@{MPKitAdjustErrorKey:message}];
    return error;
}

- (void)adjustAttributionChanged:(nullable ADJAttribution *)attribution {
    NSDictionary *attributionDictionary = nil;
    
    if (attribution) {
        attributionDictionary = attribution.dictionary;
    } else {
        attributionDictionary = @{};
    }
    
    NSString *adid = attributionDictionary[adjustDeviceIdentifierIntegrationAttributeKey];
    if (adid != nil && adid.length > 0) {
        [[MParticle sharedInstance] setIntegrationAttributes:@{adjustDeviceIdentifierIntegrationAttributeKey: adid} forKit:[[self class] kitCode]];
        _hasSetADID = YES;
    }
    
    NSMutableDictionary *outerDictionary = [NSMutableDictionary dictionary];
    
    if (attributionDictionary) {
        outerDictionary[MPKitAdjustAttributionResultKey] = attributionDictionary;
    }
    
    MPAttributionResult *attributionResult = [[MPAttributionResult alloc] init];
    attributionResult.linkInfo = outerDictionary;
    
    [_kitApi onAttributionCompleteWithResult:attributionResult error:nil];
}

- (MPKitExecStatus *)setATTStatus:(MPATTAuthorizationStatus)status withATTStatusTimestampMillis:(NSNumber *)attStatusTimestampMillis  API_AVAILABLE(ios(14)){
    if (status != MPATTAuthorizationStatusNotDetermined) {
        [Adjust requestAppTrackingAuthorizationWithCompletionHandler:^(NSUInteger status) {
            NSLog(@"Adjust: App Tracking Transparency Authorization Status set to %lu", (unsigned long)status);
        }];
    }

    return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceAdjust) returnCode:MPKitReturnCodeSuccess];
}

- (BOOL)shouldDelayMParticleUpload {
    return !_hasSetADID;
}

@end
