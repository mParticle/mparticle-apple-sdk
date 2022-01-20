#ifndef mParticleSDK_MPILogger_h
#define mParticleSDK_MPILogger_h

#import "MPEnums.h"

#define MPILogger(loggerLevel, format, ...) if ([MParticle sharedInstance].logLevel >= (loggerLevel) && [MParticle sharedInstance].logLevel != MPILogLevelNone) { \
                                NSString *msg = [NSString stringWithFormat:@"mParticle -> " format, ##__VA_ARGS__]; \
                                if ([MParticle sharedInstance].customLogger != NULL) { \
                                    [MParticle sharedInstance].customLogger(msg); \
                                } \
                                else { \
                                    NSLog(@"%@", msg); \
                                } \
                        }

#define MPILogError(format, ...) MPILogger(MPILogLevelError, format, ##__VA_ARGS__);

#define MPILogWarning(format, ...) MPILogger(MPILogLevelWarning, format, ##__VA_ARGS__);

#define MPILogDebug(format, ...) MPILogger(MPILogLevelDebug, format, ##__VA_ARGS__);

#define MPILogVerbose(format, ...) MPILogger(MPILogLevelVerbose, format, ##__VA_ARGS__);

#endif
