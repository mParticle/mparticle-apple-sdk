#import "UploadSettingsUtils.h"
#import "mParticle.h"

@implementation UploadSettingsUtils

// Archive the runtime-identity-pinned MPUploadSettings class and obtain the SDK logger
// on the ObjC side. The Swift module cannot import these ObjC types without a dependency
// cycle; MPUserDefaults handles storage in Swift. See docs/swift-migration/CONVERSION-RECIPE.md.

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
