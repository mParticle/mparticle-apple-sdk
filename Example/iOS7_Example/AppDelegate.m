//
//  AppDelegate.m
//
//  Copyright 2016 mParticle, Inc.
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

#import "AppDelegate.h"
#import <mParticle_Apple_SDK/mParticle.h>

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Starts the mParticle SDK
    MParticle *mParticle = [MParticle sharedInstance];
    [mParticle startWithKey:@"Your_App_Key" secret:@"Your_App_Secret"];
    
    // Debug log level to the console. The default log level is
    // MPILogLevelWarning (only warning and error log messages are displayed to the console)
    mParticle.logLevel = MPILogLevelDebug;
    
    return YES;
}

@end
