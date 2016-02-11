//
//  MPLogger.h
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

#ifndef mParticleSDK_MPLogger_h
#define mParticleSDK_MPLogger_h

#import "MPStateMachine.h"
#import "MPEnums.h"

#define MPLogger(loggerLevel, format, ...) if ([MPStateMachine sharedInstance].logLevel >= (loggerLevel) && [MPStateMachine sharedInstance].logLevel != MPLogLevelNone) { \
                                               NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                           }

#define MPLogError(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPLogLevelError) { \
                                    NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                }

#define MPLogWarning(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPLogLevelWarning) { \
                                      NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                  }

#define MPLogDebug(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPLogLevelDebug) { \
                                    NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                }

#define MPLogVerbose(format, ...) if ([MPStateMachine sharedInstance].logLevel >= MPLogLevelVerbose) { \
                                    NSLog((@"mParticle -> " format), ##__VA_ARGS__); \
                                }

#endif
