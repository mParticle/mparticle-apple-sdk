#import "MPNotificationController.h"

@interface MPNotificationController(Tests)

- (void)handleApplicationDidFinishLaunching:(NSNotification *)notification;
- (void)handleApplicationDidEnterBackground:(NSNotification *)notification;
- (void)handleApplicationWillEnterForeground:(NSNotification *)notification;
- (void)handleApplicationDidBecomeActive:(NSNotification *)notification;
- (void)handleRemoteNotificationReceived:(NSNotification *)notification;

@end
