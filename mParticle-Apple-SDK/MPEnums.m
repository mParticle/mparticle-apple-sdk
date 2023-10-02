#import "MPEnums.h"
#import "MPIConstants.h"

NSString *const mParticleSessionDidBeginNotification = @"mParticleSessionDidBeginNotification";
NSString *const mParticleSessionDidEndNotification = @"mParticleSessionDidEndNotification";
NSString *const mParticleSessionId = @"mParticleSessionId";
NSString *const mParticleSessionUUID = @"mParticleSessionUUID";
NSString *const mParticleDidFinishInitializing = @"mParticleDidFinishInitializing";

NSString *const mParticleUserAttributeMobileNumber = @"$Mobile";
NSString *const mParticleUserAttributeGender = @"$Gender";
NSString *const mParticleUserAttributeAge = @"$Age";
NSString *const mParticleUserAttributeCountry = @"$Country";
NSString *const mParticleUserAttributeZip = @"$Zip";
NSString *const mParticleUserAttributeCity = @"$City";
NSString *const mParticleUserAttributeState = @"$State";
NSString *const mParticleUserAttributeAddress = @"$Address";
NSString *const mParticleUserAttributeFirstName = @"$FirstName";
NSString *const mParticleUserAttributeLastName = @"$LastName";

NSString *const mParticleKitDidBecomeActiveNotification = @"mParticleKitDidBecomeActiveNotification";
NSString *const mParticleEmbeddedSDKDidBecomeActiveNotification = @"mParticleEmbeddedSDKDidBecomeActiveNotification";
NSString *const mParticleKitDidBecomeInactiveNotification = @"mParticleKitDidBecomeInactiveNotification";
NSString *const mParticleEmbeddedSDKDidBecomeInactiveNotification = @"mParticleEmbeddedSDKDidBecomeInactiveNotification";
NSString *const mParticleKitInstanceKey = @"mParticleKitInstanceKey";
NSString *const mParticleEmbeddedSDKInstanceKey = @"mParticleEmbeddedSDKInstanceKey";

NSString *const mParticleIdentityStateChangeListenerNotification = @"mParticleIdentityStateChangeListenerNotification";
NSString *const mParticleUserKey = @"mParticleUserKey";
NSString *const mParticlePreviousUserKey = @"mParticlePreviousUserKey";
NSString *const mParticleIdentityErrorDomain = @"mParticle Identity Error Domain";
NSString *const mParticleIdentityErrorKey = @"mParticle Identity Error";

NSString *const mParticleGenderMale = @"M";
NSString *const mParticleGenderFemale = @"F";
NSString *const mParticleGenderNotAvailable = @"NA";

NSString * const MPKitAPIErrorDomain = @"com.mparticle.kitapi";
NSString * const MPKitAPIErrorKey = @"mParticle Kit API Error";

@implementation MPEnum

+ (BOOL)isUserIdentity:(MPIdentity)identity {
    if (identity <= MPIdentityPhoneNumber3) {
        return true;
    }
    return  false;
}

+ (MPMessageType)messageTypeFromNSString:(NSString *)messageTypeString {
    if ([messageTypeString isEqualToString:kMPMessageTypeStringUnknown]) {
        return MPMessageTypeUnknown;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringSessionStart]) {
        return MPMessageTypeSessionStart;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringSessionEnd]) {
        return MPMessageTypeSessionEnd;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringScreenView]) {
        return MPMessageTypeScreenView;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringEvent]) {
        return MPMessageTypeEvent;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringCrashReport]) {
        return MPMessageTypeCrashReport;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringOptOut]) {
        return MPMessageTypeOptOut;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringFirstRun]) {
        return MPMessageTypeFirstRun;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringPreAttribution]) {
        return MPMessageTypePreAttribution;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringPushRegistration]) {
        return MPMessageTypePushRegistration;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringNetworkPerformance]) {
        return MPMessageTypeNetworkPerformance;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringBreadcrumb]) {
        return MPMessageTypeBreadcrumb;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringProfile]) {
        return MPMessageTypeProfile;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringPushNotification]) {
        return MPMessageTypePushNotification;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringPushNotificationInteraction]) {
        return MPMessageTypePushNotificationInteraction;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringCommerceEvent]) {
        return MPMessageTypeCommerceEvent;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringUserAttributeChange]) {
        return MPMessageTypeUserAttributeChange;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringUserIdentityChange]) {
        return MPMessageTypeUserIdentityChange;
    } else if ([messageTypeString isEqualToString:kMPMessageTypeStringMedia]) {
        return MPMessageTypeMedia;
    } else {
        return MPMessageTypeUnknown;
    }
}

+ (NSUInteger)messageTypeSize {
   return 20;
}

@end
