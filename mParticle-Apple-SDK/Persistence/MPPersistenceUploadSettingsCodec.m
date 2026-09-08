#import "MPPersistenceUploadSettingsCodec.h"
#import "MPUploadSettings.h"

@implementation MPPersistenceUploadSettingsCodec

- (NSData *)archiveUploadSettings:(NSObject *)settings {
    if (![settings isKindOfClass:[MPUploadSettings class]]) {
        return nil;
    }

    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:settings
                                        requiringSecureCoding:YES
                                                        error:&error];
    return error == nil ? data : nil;
}

- (NSObject *)unarchiveUploadSettings:(NSData *)data {
    NSError *error = nil;
    MPUploadSettings *settings = [NSKeyedUnarchiver unarchivedObjectOfClass:[MPUploadSettings class]
                                                                   fromData:data
                                                                      error:&error];
    return error == nil ? settings : nil;
}

@end
