#import "SettingsProvider.h"

@interface SettingsProviderMock : NSObject<SettingsProviderProtocol>
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id> *configSettings;
@end
