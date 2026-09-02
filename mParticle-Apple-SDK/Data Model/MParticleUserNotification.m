#import "MParticleUserNotification.h"
#import "mParticle.h"

NSString *const kMPUserNotificationApsKey = @"aps";
NSString *const kMPUserNotificationAlertKey = @"alert";
NSString *const kMPUserNotificationBodyKey = @"body";
NSString *const kMPUserNotificationContentAvailableKey = @"content-available";
NSString *const kMPUserNotificationCategoryKey = @"category";

#if TARGET_OS_IOS == 1

#import "MPIConstants.h"
#import <UIKit/UIKit.h>
#import "MPILogger.h"
@import mParticle_Apple_SDK_Swift;

@implementation MParticleUserNotification

- (instancetype)initWithDictionary:(NSDictionary *)notificationDictionary state:(NSString *)state behavior:(MPUserNotificationBehavior)behavior mode:(MPUserNotificationMode)mode {
    self = [super init];
    if (!self || !state) {
        return nil;
    }
    
    _shouldPersist = YES;
    
    if (mode == MPUserNotificationModeAutoDetect) {
        _mode = MPUserNotificationModeRemote;
    } else {
        _mode = mode;
    }

    _behavior = behavior;
    _state = state;

    MParticleUserNotificationPRIVATE *implementation = [[MParticleUserNotificationPRIVATE alloc] initWithNotificationDictionary:notificationDictionary];
    _redactedUserNotificationString = implementation.redactedUserNotificationString;
    _categoryIdentifier = implementation.categoryIdentifier;

    _uuid = [[NSUUID UUID] UUIDString];
    _actionTitle = nil;
    _actionIdentifier = nil;
    _type = kMPPushMessageReceived;
    _receiptTime = [NSDate date];
    
    return self;
}

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithFormat:@"User Notification\n Receipt Time: %@\n State: %@\n Type Id: %@\n", self.receiptTime, self.state, self.type];
    
    if (self.redactedUserNotificationString) {
        [description appendFormat:@" Redacted notification: %@\n", self.redactedUserNotificationString];
    }
    
    if (self.categoryIdentifier) {
        [description appendFormat:@" Category identifier: %@\n", self.categoryIdentifier];
    }
    
    if (self.behavior > 0) {
        [description appendFormat:@" Behavior: %d\n", (int)self.behavior];
    }
    
    if (_userNotificationId > 0) {
        [description appendFormat:@" Notification Id: %d\n", (int)_userNotificationId];
    }
    
    return description;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[MParticleUserNotification class]]) {
        return NO;
    }

    MParticleUserNotification *other = (MParticleUserNotification *)object;
    return [MParticleUserNotificationPRIVATE isEqualWithUserNotificationId:_userNotificationId
                                                           redactedString:_redactedUserNotificationString
                                                  otherUserNotificationId:other.userNotificationId
                                                      otherRedactedString:other.redactedUserNotificationString];
}

- (NSUInteger)hash {
    return (NSUInteger)self.userNotificationId;
}

#pragma mark NSSecureCoding
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_receiptTime forKey:@"receiptTime"];
    [coder encodeObject:_state forKey:@"state"];
    [coder encodeObject:_type forKey:@"type"];
    [coder encodeObject:_uuid forKey:@"uuid"];
    [coder encodeInt64:_userNotificationId forKey:@"userNotificationId"];
    [coder encodeInteger:_behavior forKey:@"behavior"];
    [coder encodeInteger:_mode forKey:@"mode"];
    
    if (_redactedUserNotificationString) {
        [coder encodeObject:_redactedUserNotificationString forKey:@"redactedUserNotificationString"];
    }
    
    if (_categoryIdentifier) {
        [coder encodeObject:_categoryIdentifier forKey:@"categoryIdentifier"];
    }
    
    if (_actionTitle) {
        [coder encodeObject:_actionTitle forKey:@"actionTitle"];
    }
    
    if (_actionIdentifier) {
        [coder encodeObject:_actionIdentifier forKey:@"actionIdentifier"];
    }
    
    if (_localAlertDate) {
        [coder encodeObject:_localAlertDate forKey:@"localAlertDate"];
    }
    
    if (_deferredPayload) {
        [coder encodeObject:_deferredPayload forKey:@"deferredPayload"];
    }
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _shouldPersist = YES;
    _receiptTime = [coder decodeObjectOfClass:[NSDate class] forKey:@"receiptTime"];
    _state = [coder decodeObjectOfClass:[NSString class] forKey:@"state"];
    _type = [coder decodeObjectOfClass:[NSString class] forKey:@"type"];
    _uuid = [coder decodeObjectOfClass:[NSString class] forKey:@"uuid"];
    _userNotificationId = [coder decodeInt64ForKey:@"userNotificationId"];
    _behavior = [coder decodeIntegerForKey:@"behavior"];
    _mode = [coder decodeIntegerForKey:@"mode"];
    
    id object = [coder decodeObjectOfClass:[NSString class] forKey:@"categoryIdentifier"];
    if (object) {
        _categoryIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectOfClass:[NSString class] forKey:@"redactedUserNotificationString"];
    if (object) {
        _redactedUserNotificationString = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"actionTitle"];
    if (object) {
        _actionTitle = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"actionIdentifier"];
    if (object) {
        _actionIdentifier = (NSString *)object;
    }
    
    object = [coder decodeObjectForKey:@"localAlertDate"];
    if (object) {
        _localAlertDate = (NSDate *)object;
    }
    
    object = [coder decodeObjectForKey:@"deferredPayload"];
    if (object) {
        _deferredPayload = (NSDictionary *)object;
    }
    
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

@end

#endif
