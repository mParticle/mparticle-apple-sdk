#import <Foundation/Foundation.h>
@class MPUploadSettings;
@import mParticle_Apple_SDK_Swift;

NS_ASSUME_NONNULL_BEGIN

@interface UploadSettingsUtils: NSObject

+ (void)setLastUploadSettings:(nullable MPUploadSettings *)lastUploadSettings userDefaults:(MPUserDefaults*)userDefaults;
+ (nullable MPUploadSettings *)lastUploadSettingsWithUserDefaults:(MPUserDefaults*)userDefaults;
+ (void)registerUploadSettingsClassMappings;

@end

NS_ASSUME_NONNULL_END
