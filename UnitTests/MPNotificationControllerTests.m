#import <XCTest/XCTest.h>
#import "MPStateMachine.h"
#import "MPNotificationController.h"
#import "MPNotificationController+Tests.h"
#import "MPIConstants.h"
#import "MParticleUserNotification.h"
#import "MPBaseTestCase.h"

@interface MPNotificationControllerTests : MPBaseTestCase

@property (nonatomic, strong) MPNotificationController *notificationController;
@property (nonatomic, strong) MParticleUserNotification *userNotification;

@end

@implementation MPNotificationControllerTests

- (void)setUp {
    [super setUp];
    
    self.userNotification = nil;
    [self notificationController];
}

- (void)tearDown {
    self.userNotification = nil;
    
    [super tearDown];
}

- (MPNotificationController *)notificationController {
    if (_notificationController) {
        return _notificationController;
    }
    
    _notificationController = [[MPNotificationController alloc] init];
    
    return _notificationController;
}

- (NSDictionary *)remoteNotificationDictionary:(BOOL)expired {
    UIMutableUserNotificationAction *dinoHandsUserAction = [[UIMutableUserNotificationAction alloc] init];
    dinoHandsUserAction.identifier = @"DINO_CAB_ACTION_IDENTIFIER";
    dinoHandsUserAction.title = @"Dino Cab";
    dinoHandsUserAction.activationMode = UIUserNotificationActivationModeForeground;
    dinoHandsUserAction.destructive = NO;
    
    UIMutableUserNotificationAction *shortArmsUserAction = [[UIMutableUserNotificationAction alloc] init];
    shortArmsUserAction.identifier = @"DINO_UBER_ACTION_IDENTIFIER";
    shortArmsUserAction.title = @"Dino Uber";
    shortArmsUserAction.activationMode = UIUserNotificationActivationModeBackground;
    shortArmsUserAction.destructive = NO;
    
    UIMutableUserNotificationCategory *dinosaurCategory = [[UIMutableUserNotificationCategory alloc] init];
    dinosaurCategory.identifier = @"DINOSAUR_TRANSPORTATION_CATEGORY";
    [dinosaurCategory setActions:@[dinoHandsUserAction, shortArmsUserAction] forContext:UIUserNotificationActionContextDefault];
    
    // Categories
    NSSet *categories = [NSSet setWithObjects:dinosaurCategory, nil];
    
    UIUserNotificationSettings *userNotificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert
                                                                                             categories:categories];
    
    UIApplication *application = [UIApplication sharedApplication];
    [application registerUserNotificationSettings:userNotificationSettings];
    [application registerForRemoteNotifications];
        
    NSDictionary *remoteNotificationDictionary = @{@"aps":@{
                                                           @"alert":@{
                                                                   @"body":@"Your pre-historic ride has arrived.",
                                                                   @"show-view":@NO
                                                                   },
                                                           @"badge":@1,
                                                           @"sound":@"t-rex_roar.aiff",
                                                           @"category":@"DINOSAUR_TRANSPORTATION_CATEGORY"
                                                           }
                                                   };
    
    return remoteNotificationDictionary;
}

- (NSArray *)retrieveDisplayedUserNotificationsSince:(NSTimeInterval)referenceDate mode:(MPUserNotificationMode)mode {
    return @[self.userNotification];
}

- (NSArray *)retrieveDisplayedUserNotificationsWithMode:(MPUserNotificationMode)mode {
    return nil;
}

- (void)receivedUserNotification:(MParticleUserNotification *)userNotification {
    self.userNotification = userNotification;
}

@end
