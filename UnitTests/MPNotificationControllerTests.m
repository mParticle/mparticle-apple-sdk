#import <XCTest/XCTest.h>
#import "MPStateMachine.h"
#import "MPNotificationController.h"
#import "MPNotificationController+Tests.h"
#import "MPIConstants.h"
#import "MParticleUserNotification.h"

@interface MPNotificationControllerTests : XCTestCase <MPNotificationControllerDelegate>

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
    
    _notificationController = [[MPNotificationController alloc] initWithDelegate:self];
    
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
    
    NSTimeInterval increment = expired ? -100 : 100;
    
    NSDictionary *remoteNotificationDictionary = @{@"aps":@{
                                                           @"alert":@{
                                                                   @"body":@"Your pre-historic ride has arrived.",
                                                                   @"show-view":@NO
                                                                   },
                                                           @"badge":@1,
                                                           @"sound":@"t-rex_roar.aiff",
                                                           @"category":@"DINOSAUR_TRANSPORTATION_CATEGORY"
                                                           },
                                                   @"m_cmd":@1,
                                                   @"m_cid":@2,
                                                   @"m_cntid":@3,
                                                   @"m_expy":MPMilliseconds([[NSDate date] timeIntervalSince1970] + increment),
                                                   @"m_uid":@(arc4random_uniform(INT_MAX))
                                                   };
    
    return remoteNotificationDictionary;
}

- (NSDictionary *)nonmParticleRemoteNotificationDictionary {
    NSDictionary *remoteNotificationDictionary = @{@"aps":@{
                                                           @"alert":@{
                                                                   @"body":@"Your regular transportation has arrived.",
                                                                   @"show-view":@NO
                                                                   },
                                                           @"badge":@1,
                                                           @"sound":@"engine_sound.aiff"
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

- (void)testDidFinishLaunchingWithRemoteNotification {
    NSDictionary *remoteNotificationDictionary = [self remoteNotificationDictionary:NO];
    
    NSNotification *notification = [[NSNotification alloc] initWithName:@"Testing did finish launching"
                                                                 object:nil
                                                               userInfo:@{UIApplicationLaunchOptionsRemoteNotificationKey:remoteNotificationDictionary}];
    
    [self.notificationController handleApplicationDidFinishLaunching:notification];
    
    XCTAssertNotNil(self.userNotification, @"User notification should not have been nil.");
    XCTAssertEqualObjects(self.userNotification.contentId, @3, @"Content id is incorrect.");
    XCTAssertEqualObjects(self.userNotification.campaignId, @2, @"Campaign id is incorrect.");
    XCTAssertNotNil(self.userNotification.redactedUserNotificationString, @"Redacted notification should not have been nil.");
    XCTAssertEqual(self.userNotification.behavior, (MPUserNotificationBehaviorReceived | MPUserNotificationBehaviorRead), @"Behavior is incorrect.");
}

- (void)testDidFinishLaunchingNotInfluencedOpen {
    NSDictionary *remoteNotificationDictionary = [self remoteNotificationDictionary:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kMPRemoteNotificationReceivedNotification
                                                        object:self
                                                      userInfo:@{kMPUserNotificationDictionaryKey:remoteNotificationDictionary}];
    
    sleep(1);
    
    NSNotification *notification = [[NSNotification alloc] initWithName:@"Testing did finish launching"
                                                                 object:nil
                                                               userInfo:nil];
    
    [self.notificationController handleApplicationDidFinishLaunching:notification];
    
    XCTAssertFalse(self.userNotification.hasBeenUsedInInfluencedOpen, @"User notification should not have been marked as influenced open.");
    XCTAssertFalse(self.userNotification.hasBeenUsedInDirectOpen, @"User notification should not have been marked as direct open.");
}

@end
