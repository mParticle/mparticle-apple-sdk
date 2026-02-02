#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


NS_ASSUME_NONNULL_BEGIN

@protocol OpenURLHandlerProtocol <NSObject>
- (void)open:(NSURL *)url options:(nullable NSDictionary<NSString *, id> *)options;
- (BOOL)continueUserActivity:(NSUserActivity *)userActivity
          restorationHandler:(void (^_Nonnull)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler;
@end

@interface SceneDelegateHandler : NSObject

- (instancetype)initWithAppNotificationHandler:(id<OpenURLHandlerProtocol>)appNotificationHandler;
- (void)handleUserActivity:(NSUserActivity *)userActivity;

#if TARGET_OS_IOS == 1
- (void)handleWithUrlContext:(UIOpenURLContext *)urlContext API_AVAILABLE(ios(13.0));
#endif

@end

NS_ASSUME_NONNULL_END

