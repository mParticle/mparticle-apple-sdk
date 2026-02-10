#import "UploadSettingsUtils.h"
#import "mParticle.h"

@implementation UploadSettingsUtils


+ (void)setLastUploadSettings:(nullable MPUploadSettings *)lastUploadSettings userDefaults:(MPUserDefaults*)userDefaults {
    if (lastUploadSettings) {
        NSError *error = nil;

        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:lastUploadSettings
                                           requiringSecureCoding:YES
                                                           error:&error];
        if (data && !error) {
            [userDefaults setLastUploadSettingsData:data];
        } else {
            MParticle* mparticle = MParticle.sharedInstance;
            MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
            logger.customLogger = mparticle.customLogger;
            [logger error:[NSString stringWithFormat:@"Failed to archive upload settings: %@", error]];
        }
    } else {
        [userDefaults removeLastUploadSettings];
    }
}

+ (nullable MPUploadSettings*)lastUploadSettingsWithUserDefaults:(MPUserDefaults*)userDefaults{
    id obj = [userDefaults lastUploadSettingsData];
    if (![obj isKindOfClass:[NSData class]]) {
        return nil;
    }

    NSError *error = nil;
    [NSKeyedUnarchiver setClass: [MPUploadSettings class]
                   forClassName: @"mParticle_Apple_SDK.MPUploadSettings"];
    [NSKeyedUnarchiver setClass: [MPUploadSettings class]
                   forClassName: @"mParticle_Apple_SDK_NoLocation"];
    
    MPUploadSettings *settings =
        [NSKeyedUnarchiver unarchivedObjectOfClass:[MPUploadSettings class]
                                          fromData:(NSData *)obj
                                             error:&error];

    if (settings) {
        return settings;
    }

    if (error) {
        MParticle* mparticle = MParticle.sharedInstance;
        MPLog* logger = [[MPLog alloc] initWithLogLevel:[MPLog fromRawValue:mparticle.logLevel]];
        logger.customLogger = mparticle.customLogger;
        [logger error:[NSString stringWithFormat:@"Failed to unarchive upload settings: %@", error]];
    }
    return nil;
}

@end
