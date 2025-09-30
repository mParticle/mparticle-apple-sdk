@import Foundation;

@protocol SettingsProviderProtocol <NSObject>

@property (nonatomic, strong, nullable) NSMutableDictionary *configSettings;

@end

@interface SettingsProvider : NSObject<SettingsProviderProtocol>

@end


