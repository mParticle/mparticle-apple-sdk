#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MPNotificationControllerProtocol

#if TARGET_OS_IOS == 1
- (nullable NSData *)deviceToken;
- (void)setDeviceToken:(nullable NSData *)devToken;
#endif

@end

@interface MPNotificationController_PRIVATE : NSObject <MPNotificationControllerProtocol>

#if TARGET_OS_IOS == 1
- (nullable NSData *)deviceToken;
- (void)setDeviceToken:(nullable NSData *)devToken;
#endif

@end
