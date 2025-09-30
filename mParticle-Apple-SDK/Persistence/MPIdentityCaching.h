//
//  MPIdentityCaching.h
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 12/12/23.
//

#import <Foundation/Foundation.h>
#import "MPListenerProtocol.h"
#import "MPIdentityDTO.h"

@interface MPIdentityCachedResponse : NSObject
@property (nonnull, nonatomic, readonly) NSData *bodyData;
@property (nonatomic, readonly) NSInteger statusCode;
@property (nonnull, nonatomic, readonly) NSDate *expires;
- (nonnull instancetype)initWithBodyData:(nonnull NSData *)bodyData statusCode:(NSInteger)statusCode expires:(nonnull NSDate *)expires;
@end

@interface MPIdentityCaching : NSObject

+ (void)cacheIdentityResponse:(nonnull MPIdentityCachedResponse *)cachedResponse endpoint:(MPEndpoint)endpoint identityRequest:(nonnull MPIdentityHTTPBaseRequest *)identityRequest;
+ (nullable MPIdentityCachedResponse *)getCachedIdentityResponseForEndpoint:(MPEndpoint)endpoint identityRequest:(nonnull MPIdentityHTTPBaseRequest *)identityRequest;
+ (void)clearAllCache;
+ (void)clearExpiredCache;

@end
