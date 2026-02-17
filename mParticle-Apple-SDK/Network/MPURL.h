#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPURL : NSObject

@property (nonatomic, strong, readonly, nonnull) NSURL *url;
@property (nonatomic, strong, readonly, nonnull) NSURL *defaultURL;

- (nonnull instancetype)initWithURL:(nonnull NSURL *)url defaultURL:(nonnull NSURL *)defaultURL;

@end

NS_ASSUME_NONNULL_END
