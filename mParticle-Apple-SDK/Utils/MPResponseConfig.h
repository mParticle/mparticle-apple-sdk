#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPResponseConfig : NSObject <NSCoding>

@property (nonatomic, copy, nonnull, readonly) NSDictionary *configuration;
@property (nonatomic, strong, readonly, nullable) NSNumber *influencedOpenTimer;

- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration;
- (nonnull instancetype)initWithConfiguration:(nonnull NSDictionary *)configuration dataReceivedFromServer:(BOOL)dataReceivedFromServer;

+ (void)save:(nonnull MPResponseConfig *)responseConfig;
+ (nullable MPResponseConfig *)restore;

#if TARGET_OS_IOS == 1
- (void)configureLocationTracking:(nonnull NSDictionary *)locationDictionary;
- (void)configurePushNotifications:(nonnull NSDictionary *)pushNotificationDictionary;
#endif

@end
