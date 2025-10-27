#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MPNotificationControllerProtocol

#if TARGET_OS_IOS == 1
+ (nullable NSData *)deviceToken DEPRECATED_MSG_ATTRIBUTE("This method is no longer static. Use an instance method instead.");
+ (void)setDeviceToken:(nullable NSData *)devToken DEPRECATED_MSG_ATTRIBUTE("This method is no longer static. Use an instance method instead.");
- (nullable NSData *)deviceToken;
- (void)setDeviceToken:(nullable NSData *)devToken;
#endif

@end

@interface MPNotificationController_PRIVATE : NSObject <MPNotificationControllerProtocol>

#if TARGET_OS_IOS == 1
+ (nullable NSData *)deviceToken;
+ (void)setDeviceToken:(nullable NSData *)devToken;
- (nullable NSData *)deviceToken;
- (void)setDeviceToken:(nullable NSData *)devToken;
#endif

@end
