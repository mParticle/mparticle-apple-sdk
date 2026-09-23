#import <Foundation/Foundation.h>

// MParticleUserNotification itself now lives in Swift as MParticleUserNotificationPRIVATE, exported
// under its original Objective-C runtime name. Only the two typedefs stay here: NS_OPTIONS and
// NS_ENUM are C constructs the Swift module cannot emit, and callers combine
// MPUserNotificationBehavior with `|`.
@import mParticle_Apple_SDK_Swift;

typedef NS_OPTIONS(NSUInteger, MPUserNotificationBehavior) {
    MPUserNotificationBehaviorReceived = 1 << 0,
    MPUserNotificationBehaviorDirectOpen = 1 << 1,
    MPUserNotificationBehaviorRead = 1 << 2,
};

typedef NS_ENUM(NSInteger, MPUserNotificationMode) {
    MPUserNotificationModeAutoDetect = 0,
    MPUserNotificationModeRemote,
    MPUserNotificationModeLocal
};
