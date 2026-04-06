#import "MPKitCleverTap.h"
#import <CoreLocation/CoreLocation.h>

#if defined(__has_include) && __has_include(<CleverTapSDK/CleverTap.h>)
    #import <CleverTapSDK/CleverTap.h>
#else
    #import "CleverTap.h"
#endif

static NSString *const ctAccountID = @"AccountID";
static NSString *const ctAccountToken = @"AccountToken";
static NSString *const ctRegion = @"Region";
static NSString *const kUserIdField = @"userIdField";
static NSString *const ctCleverTapIdIntegrationKey = @"clevertap_id_integration_setting";
static NSString *const kCTTransactionID = @"Transaction Id";
static NSString *const kCTChargedID = @"Charged ID";
static NSString *const kLibName = @"mParticle-iOS";
static NSString *const kLibVersion = @"9.0.0";

@implementation MPKitCleverTap

+ (NSNumber *)kitCode {
    return @135;
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"CleverTap" className:@"MPKitCleverTap"];
    [MParticle registerExtension:kitRegister];
}

- (MPKitExecStatus *)execStatus:(MPKitReturnCode)returnCode {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.class.kitCode returnCode:returnCode];
}

#pragma mark - MPKitProtocol methods

#pragma mark Kit instance and lifecycle

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    NSString *accountID = configuration[ctAccountID];
    NSString *accountToken = configuration[ctAccountToken];

    if (![accountID isKindOfClass:[NSString class]] || accountID.length == 0 ||
        ![accountToken isKindOfClass:[NSString class]] || accountToken.length == 0) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    _configuration = configuration;
    [self start];

    return [self execStatus:MPKitReturnCodeSuccess];
}

- (void)start {
    static dispatch_once_t kitPredicate;

    dispatch_once(&kitPredicate, ^{
        NSString *accountID = self->_configuration[ctAccountID];
        NSString *accountToken = self->_configuration[ctAccountToken];
        NSString *region = self->_configuration[ctRegion];

        [CleverTap setCredentialsWithAccountID:accountID token:accountToken region:region];
        [[CleverTap sharedInstance] setLibrary:kLibName];
        [[CleverTap sharedInstance] setCustomSdkVersion:kLibName version:[self.class intVersion:kLibVersion]];
        [[CleverTap sharedInstance] notifyApplicationLaunchedWithOptions:nil];

        self->_started = YES;

        NSString *cleverTapID = [[CleverTap sharedInstance] profileGetCleverTapID];
        if (cleverTapID) {
            NSDictionary *integrationAttributes = @{ctCleverTapIdIntegrationKey: cleverTapID};
            [[MParticle sharedInstance] setIntegrationAttributes:integrationAttributes forKit:[[self class] kitCode]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey: [[self class] kitCode]};
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification
                                                                object:nil
                                                              userInfo:userInfo];
        });
    });
}

- (id const)providerKitInstance {
    if (![self started]) {
        return nil;
    }
    return [CleverTap sharedInstance];
}

#pragma mark Application

- (nonnull MPKitExecStatus *)userNotificationCenter:(nonnull UNUserNotificationCenter *)center
                     didReceiveNotificationResponse:(nonnull UNNotificationResponse *)response {
    [CleverTap handlePushNotification:response.notification.request.content.userInfo openDeepLinksInForeground:YES];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo {
    [[CleverTap sharedInstance] handleNotificationWithData:userInfo];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)handleActionWithIdentifier:(nullable NSString *)identifier
                                  forRemoteNotification:(nonnull NSDictionary *)userInfo
                                       withResponseInfo:(nonnull NSDictionary *)responseInfo {
    [[CleverTap sharedInstance] handleNotificationWithData:userInfo];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)receivedUserNotification:(NSDictionary *)userInfo {
    [[CleverTap sharedInstance] handleNotificationWithData:userInfo];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)setDeviceToken:(NSData *)deviceToken {
    [[CleverTap sharedInstance] setPushToken:deviceToken];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url options:(nullable NSDictionary *)options {
    [[CleverTap sharedInstance] handleOpenURL:url sourceApplication:nil];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)openURL:(nonnull NSURL *)url
                   sourceApplication:(nullable NSString *)sourceApplication
                          annotation:(nullable id)annotation {
    [[CleverTap sharedInstance] handleOpenURL:url sourceApplication:nil];
    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark Location tracking

- (nonnull MPKitExecStatus *)setLocation:(nonnull MPLocation *)location {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude);
    [CleverTap setLocation:coordinate];
    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark User attributes

- (nonnull MPKitExecStatus *)removeUserAttribute:(nonnull NSString *)key {
    [[CleverTap sharedInstance] profileRemoveValueForKey:key];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key value:(nonnull id)value {
    if ([value isKindOfClass:[NSDictionary class]]) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    NSMutableDictionary *profile = [NSMutableDictionary new];

    if ([key isEqualToString:@"name"]) {
        profile[@"Name"] = value;
    } else if ([key isEqualToString:mParticleUserAttributeMobileNumber] ||
               [key isEqualToString:@"$MPUserMobile"] ||
               [key isEqualToString:@"phone"]) {
        profile[@"Phone"] = [NSString stringWithFormat:@"%@", value];
        profile[key] = value;
    } else if ([key isEqualToString:mParticleUserAttributeGender]) {
        profile[@"Gender"] = [value isEqualToString:mParticleGenderMale] ? @"M" : @"F";
    } else if ([key isEqualToString:@"birthday"] && [value isKindOfClass:[NSString class]]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [dateFormatter setLocale:enUSPOSIXLocale];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZZZ"];
        NSDate *d = [dateFormatter dateFromString:value];
        profile[@"DOB"] = d;
        profile[key] = value;
    } else {
        profile[key] = value;
    }

    if (profile.count == 0) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    [[CleverTap sharedInstance] profilePush:profile];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key values:(nonnull NSArray *)values {
    [[CleverTap sharedInstance] profileAddMultiValues:values forKey:key];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)onLoginComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request isLogin:YES];
}

- (nonnull MPKitExecStatus *)onIdentifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request isLogin:NO];
}

- (nonnull MPKitExecStatus *)onModifyComplete:(FilteredMParticleUser *)user request:(FilteredMPIdentityApiRequest *)request {
    return [self updateUser:user request:request isLogin:NO];
}

- (nonnull MPKitExecStatus *)updateUser:(FilteredMParticleUser *)user
                                request:(FilteredMPIdentityApiRequest *)request
                                isLogin:(BOOL)isLogin {
    NSDictionary *userIDsCopy = (request.userIdentities != nil) ? [request.userIdentities copy] : @{};
    NSMutableDictionary *profile = [NSMutableDictionary new];

    NSString *userIdField = self->_configuration[kUserIdField];
    if ([userIdField isEqualToString:@"mpid"]) {
        profile[@"Identity"] = [user.userId stringValue];
    } else if (userIDsCopy[@(MPUserIdentityCustomerId)]) {
        profile[@"Identity"] = userIDsCopy[@(MPUserIdentityCustomerId)];
    }

    if (userIDsCopy[@(MPUserIdentityEmail)]) {
        profile[@"Email"] = userIDsCopy[@(MPUserIdentityEmail)];
    }
    if (userIDsCopy[@(MPUserIdentityFacebook)]) {
        profile[@"FBID"] = userIDsCopy[@(MPUserIdentityFacebook)];
    }
    if (userIDsCopy[@(MPUserIdentityGoogle)]) {
        profile[@"GPID"] = userIDsCopy[@(MPUserIdentityGoogle)];
    }

    if (profile.count == 0) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }

    if (isLogin) {
        [[CleverTap sharedInstance] onUserLogin:profile];
    } else {
        [[CleverTap sharedInstance] profilePush:profile];
    }

    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark e-Commerce

- (MPKitExecStatus *)logCommerceEvent:(MPCommerceEvent *)commerceEvent {
    MPKitExecStatus *execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode]
                                                                returnCode:MPKitReturnCodeSuccess
                                                              forwardCount:0];
    if (commerceEvent.action == MPCommerceEventActionPurchase) {
        NSMutableDictionary *details = [NSMutableDictionary new];
        NSMutableArray *items = [NSMutableArray new];

        NSDictionary *transactionAttributes = [commerceEvent.transactionAttributes beautifiedDictionaryRepresentation];
        if (transactionAttributes) {
            [details addEntriesFromDictionary:transactionAttributes];
        }

        NSDictionary *commerceEventAttributes = [commerceEvent beautifiedAttributes];
        NSArray *keys = @[kMPExpCECheckoutOptions, kMPExpCECheckoutStep, kMPExpCEProductListName, kMPExpCEProductListSource];
        for (NSString *key in keys) {
            if (commerceEventAttributes[key]) {
                details[key] = commerceEventAttributes[key];
            }
        }

        NSString *transactionId = commerceEventAttributes[kCTTransactionID];
        if (transactionId) {
            details[kCTChargedID] = transactionId;
        }

        NSArray *products = commerceEvent.products;
        for (MPProduct *product in products) {
            [items addObject:[product beautifiedAttributes]];
        }

        [[CleverTap sharedInstance] recordChargedEventWithDetails:details andItems:items];
        [execStatus incrementForwardCount];
    } else {
        NSArray *expandedInstructions = [commerceEvent expandedInstructions];
        for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
            [self logEvent:commerceEventInstruction.event];
            [execStatus incrementForwardCount];
        }
    }

    return execStatus;
}

#pragma mark Events

- (MPKitExecStatus *)logEvent:(MPEvent *)event {
    [[CleverTap sharedInstance] recordEvent:event.name withProps:event.customAttributes];
    return [self execStatus:MPKitReturnCodeSuccess];
}

- (MPKitExecStatus *)logScreen:(MPEvent *)event {
    NSString *screenName = event.name;
    if (!screenName) {
        return [self execStatus:MPKitReturnCodeRequirementsNotMet];
    }
    [[CleverTap sharedInstance] recordScreenView:screenName];
    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark Assorted

- (MPKitExecStatus *)setOptOut:(BOOL)optOut {
    [[CleverTap sharedInstance] setOptOut:optOut];
    return [self execStatus:MPKitReturnCodeSuccess];
}

#pragma mark Private

+ (int)intVersion:(NSString *)version {
    NSArray *split = [version componentsSeparatedByString:@"."];
    if (split.count != 3) {
        return 0;
    }
    NSString *string = [NSString stringWithFormat:@"%d%02d%02d", [split[0] intValue], [split[1] intValue], [split[2] intValue]];
    return [string intValue];
}

@end
