#import <Foundation/Foundation.h>

@interface Stream : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSURL *url;

- (instancetype)initWithTitle:(NSString *)title url:(NSURL *)url;

@end
