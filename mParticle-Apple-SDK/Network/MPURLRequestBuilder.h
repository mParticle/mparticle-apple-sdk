#import <Foundation/Foundation.h>

@class MPURL;

@interface MPURLRequestBuilder : NSObject

@property (nonatomic, strong, nonnull) NSString *httpMethod;
@property (nonatomic, strong, nullable) NSData *postData;
@property (nonatomic, strong, nonnull) MPURL *url;

+ (nonnull MPURLRequestBuilder *)newBuilderWithURL:(nonnull MPURL *)url;
+ (nonnull MPURLRequestBuilder *)newBuilderWithURL:(nonnull MPURL *)url message:(nullable NSString *)message httpMethod:(nullable NSString *)httpMethod;
+ (NSTimeInterval)requestTimeout;
- (nonnull instancetype)initWithURL:(nonnull MPURL *)url;
- (nonnull MPURLRequestBuilder *)withHeaderData:(nullable NSData *)headerData;
- (nonnull MPURLRequestBuilder *)withHttpMethod:(nonnull NSString *)httpMethod;
- (nonnull MPURLRequestBuilder *)withPostData:(nullable NSData *)postData;
- (nonnull MPURLRequestBuilder *)withSecret:(nullable NSString *)secret;
- (nonnull NSMutableURLRequest *)build;

@end
