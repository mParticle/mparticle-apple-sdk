#import "MPURL.h"

@implementation MPURL

- (instancetype)initWithURL:(NSURL *)url defaultURL:(nonnull NSURL *)defaultURL {
    self = [super init];
    if (!self || !url || !defaultURL) {
        return nil;
    }
    
    _url = url;
    _defaultURL = defaultURL;

    return self;
}

@end
