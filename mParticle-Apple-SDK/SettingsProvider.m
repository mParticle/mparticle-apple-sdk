#import "SettingsProvider.h"
#import "MPIConstants.h"



@implementation SettingsProvider

@synthesize configSettings = _configSettings;

- (NSMutableDictionary *)configSettings {
    if (_configSettings) {
        return _configSettings;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:kMPConfigPlist ofType:@"plist"];
    if (path) {
        _configSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }
    
    return _configSettings;
}

@end
