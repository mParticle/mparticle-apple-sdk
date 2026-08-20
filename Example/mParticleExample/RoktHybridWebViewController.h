#import <UIKit/UIKit.h>

@class MPRoktSession;

NS_ASSUME_NONNULL_BEGIN

/**
 * Loads a bundled mParticle Web SDK page and seeds Rokt launcherOptions from a native session.
 */
@interface RoktHybridWebViewController : UIViewController

- (instancetype)initWithSession:(MPRoktSession *)session NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
