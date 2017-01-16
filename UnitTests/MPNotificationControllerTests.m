//
//  MPNotificationControllerTests.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

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

- (NSDictionary *)silentNotificationDictionary {
    NSDictionary *silentNotificationDictionary = @{@"aps":@{
                                                           @"content-available":@1,
                                                           @"sound":@""
                                                           }
                                                   };
    
    return silentNotificationDictionary;
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
