#import "Stream.h"

@implementation Stream

- (instancetype)initWithTitle:(NSString *)title url:(NSURL *)url {
    self = [super init];
    if (!self || !title || !url) {
        return nil;
    }
    
    _title = title;
    _url = url;
    
    return self;
}

@end
