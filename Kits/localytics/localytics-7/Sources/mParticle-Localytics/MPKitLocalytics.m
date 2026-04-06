#import "MPKitLocalytics.h"
#import <CoreLocation/CoreLocation.h>

#if defined(__has_include) && __has_include(<Localytics/Localytics.h>)
    #import <Localytics/Localytics.h>
#else
    #import "Localytics.h"
#endif

@interface MPKitLocalytics() {
    BOOL multiplyByOneHundred;
}

@property (nonatomic, strong) NSMutableDictionary *customDimensions;

@end


@implementation MPKitLocalytics

+ (NSNumber *)kitCode {
    return @84;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Localytics" className:@"MPKitLocalytics"];
    [MParticle registerExtension:kitRegister];
}

- (NSMutableDictionary *)customDimensions {
    if (_customDimensions) {
        return _customDimensions;
    }
    
    _customDimensions = [[NSMutableDictionary alloc] initWithCapacity:1];
    return _customDimensions;
}

#pragma mark MPKitInstanceProtocol methods
- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;
    if (!configuration[@"appKey"]) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }
    
    NSString *customDimensions = configuration[@"customDimensions"];
    if (customDimensions && (NSNull *)customDimensions != [NSNull null] && customDimensions.length > 2) {
        NSError *error = nil;
        NSArray *dimensionsMapping = [NSJSONSerialization JSONObjectWithData:[customDimensions dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        
        if (dimensionsMapping && !error) {
            for (NSDictionary *dimensionMap in dimensionsMapping) {
                NSRange dimensionRange = [dimensionMap[@"value"] rangeOfString:@"Dimension "];
                
                if (dimensionRange.location != NSNotFound) {
                    NSString *key = dimensionMap[@"map"];
                    NSNumber *value = @([[dimensionMap[@"value"] substringFromIndex:NSMaxRange(dimensionRange)] integerValue]);
                    
                    if (key && value) {
                        self.customDimensions[key] = value;
                    }
                }
            }
        } else {
            NSLog(@"mParticle -> Invalid 'customDimensions' configuration.");
        }
    }
    
    multiplyByOneHundred = [configuration[@"trackClvAsRawValue"] caseInsensitiveCompare:@"true"] != NSOrderedSame;
    
    _configuration = configuration;
    _started = YES;
    
    [self start];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)dealloc {
    if (_started) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
}

- (void)start {
    [Localytics integrate:self.configuration[@"appKey"] withLocalyticsOptions:nil];
    
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateBackground) {
        [Localytics openSession];
    }
    
    _started = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{mParticleKitInstanceKey:[[self class] kitCode]};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (MPKitExecStatus *)beginSession {
    [Localytics openSession];
    [Localytics upload];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    if ([event isKindOfClass:[MPEvent class]]) {
        return [self routeEvent:(MPEvent *)event];
    } else if ([event isKindOfClass:[MPCommerceEvent class]]) {
        return [self routeCommerceEvent:(MPCommerceEvent *)event];
    } else {
        return [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeUnavailable];
    }
}

- (MPKitExecStatus *)routeCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess forwardCount:0];
    
    switch (commerceEvent.action) {
        case MPCommerceEventActionRefund:
        case MPCommerceEventActionPurchase: {
            NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
            NSString *eventName = [NSString stringWithFormat:@"eCommerce - %@", [[commerceEvent actionNameForAction:commerceEvent.action] capitalizedString]];
            long revenue = lround([commerceEvent.transactionAttributes.revenue doubleValue] * (multiplyByOneHundred ? 100 : 1));
            revenue = commerceEvent.action == MPCommerceEventActionPurchase ? revenue : labs(revenue) * -1;
            
            [Localytics tagEvent:eventName attributes:commerceEventAttributes customerValueIncrease:@(revenue)];
            [execStatus incrementForwardCount];
        }
            break;
            
        default: {
            NSArray *expandedInstructions = [commerceEvent expandedInstructions];
            
            for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
                [self routeEvent:commerceEventInstruction.event];
                [execStatus incrementForwardCount];
            }
        }
            break;
    }
    
    return execStatus;
}

- (MPKitExecStatus *)routeEvent:(MPEvent *)event {
    BOOL hasDuration = event.duration && ![event.duration isEqualToNumber:@0];
    
    if (!hasDuration) {
        if (event.customAttributes) {
            [Localytics tagEvent:event.name attributes:event.customAttributes];
        }
        else {
            [Localytics tagEvent:event.name];
        }
    } else {
        NSMutableDictionary<NSString *, id> *info = [event.customAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
        info[@"event_duration"] = event.duration;
        [Localytics tagEvent:event.name attributes:[info copy]];
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logLTVIncrease:(double)increaseAmount event:(MPEvent *)event {
    long amount = lround(increaseAmount * (multiplyByOneHundred ? 100 : 1));
    [Localytics tagEvent:event.name attributes:event.customAttributes customerValueIncrease:@(amount)];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    [Localytics tagScreen:event.name];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDebugMode:(BOOL)debugMode {
    [Localytics setLoggingEnabled:debugMode];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [Localytics setPushToken:deviceToken];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [Localytics handleNotification:userInfo];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response {
    [Localytics didReceiveNotificationResponseWithUserInfo:response.notification.request.content.userInfo];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setLocation:(MPLocation *)location {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude);
    [Localytics setLocation:coordinate];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [Localytics setOptedOut:optOut];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key value:(NSString *)value {
    NSNumber *customDimensionValue = self.customDimensions[key];
    
    if (customDimensionValue) {
        [Localytics setValue:value forCustomDimension:[customDimensionValue integerValue]];
    } else {
        if ([key isEqualToString:mParticleUserAttributeFirstName]) {
            [Localytics setCustomerFirstName:value];
        } else if ([key isEqualToString:mParticleUserAttributeLastName]) {
            [Localytics setCustomerLastName:value];
        }
    }
    
    [Localytics setValue:value forProfileAttribute:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserAttribute:(NSString *)key values:(NSArray<NSString *> *)values {
    [Localytics setValue:values forProfileAttribute:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    MPKitExecStatus *execStatus;
    NSNumber *customDimensionValue = self.customDimensions[key];
    
    if (customDimensionValue) {
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeCannotExecute];
        return execStatus;
    }
    
    [Localytics incrementValueBy:[value integerValue] forProfileAttribute:key];
    
    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)removeUserAttribute:(NSString *)key {
    [Localytics deleteProfileAttribute:key];
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)setUserIdentity:(NSString *)identityString identityType:(MPUserIdentity)identityType {
    switch (identityType) {
        case MPUserIdentityCustomerId:
            [Localytics setCustomerId:identityString];
            break;
            
        case MPUserIdentityEmail:
            [Localytics setCustomerEmail:identityString];
            break;
            
        default: {
            NSArray *identifierStrings = @[@"Other", @"CustomerId", @"Facebook", @"Twitter", @"Google", @"Microsoft", @"Yahoo", @"Email", @"Alias", @"FacebookCustomAudienceId", @"Other2", @"Other3", @"Other4", @"Other5", @"Other6", @"Other7", @"Other8", @"Other9", @"Other10", @"MobileNumber", @"PhoneNumber2", @"PhoneNumber3"];

            NSUInteger type = (NSUInteger)identityType;
            if (type < identifierStrings.count) {
                NSString *identifier = identifierStrings[type];
                [Localytics setValue:identityString forIdentifier:identifier];
            } else {
                MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeFail];
                return execStatus;
            }
            
        }
            break;
    }
    
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (MPKitExecStatus *)openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:@(MPKitInstanceLocalytics) returnCode:MPKitReturnCodeSuccess];
    [Localytics handleTestModeURL:url];
    return execStatus;
}

- (void)didEnterBackground:(NSNotification *)notification {
    [Localytics dismissCurrentInAppMessage];
    [Localytics closeSession];
    [Localytics upload];
}

@end
