//
//  NSURLConnection+mParticle.m
//
//  Copyright 2015 mParticle, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSURLConnection+mParticle.h"
#import <objc/runtime.h>
#import "MPNetworkPerformance.h"
#import "MPIConstants.h"
#import "MPURLConnectionAssociate.h"

typedef NS_ENUM(int, MPSwizzledIndex) {
    MPSwizzledIndexSendAsynchronousRequest = 0, // Class methods
    MPSwizzledIndexSendSynchronousRequest = 1,
    MPSwizzledIndexConnectionWithRequest = 2,
    MPSwizzledIndexInitWithRequest = 3, // Instance methods
    MPSwizzledIndexInitWithRequestStartImmediately = 4,
    MPSwizzledIndexStart = 5,
    MPSwizzledIndexCancel = 6
};

NSString *const ucURLFormat = @"%@://%@";

static IMP *originalMethodsImplementations;
static IMP *swizzledMethodsImplementations;

static NSArray *NSURLConnectionOriginalMethods;
static NSMutableArray *excludeURLs;
static NSMutableArray *preserverQueryFilters;
static NSArray *mpNSURLConnectionImplementedSelectors;
static BOOL NSURLConnectionMethodsSwizzled = NO;

typedef void(^MPAsynchronousRequestCompletionHandler)(NSURLResponse *, NSData *, NSError *);


@interface NSURLConnection() <NSURLConnectionDelegate>

@end

// Swizzled methods prototypes
void swizzledSendAsynchronousRequest(id self, SEL _cmd, NSURLRequest *request, NSOperationQueue *queue, MPAsynchronousRequestCompletionHandler handler);
NSData *swizzledSendSynchronousRequest(id self, SEL _cmd, NSURLRequest *request, NSURLResponse **response, NSError **error);
NSURLConnection *swizzledConnectionWithRequest(id self, SEL _cmd, NSURLRequest *request, id<NSURLConnectionDelegate> delegate);
id swizzledInitWithRequest(id self, SEL _cmd, NSURLRequest *request, id<NSURLConnectionDelegate> delegate);
id swizzledInitWithRequestStartImmediately(id self, SEL _cmd, NSURLRequest *request, id<NSURLConnectionDelegate> delegate, BOOL startImmediately);
void swizzledStart(id self, SEL _cmd);
void swizzledCancel(id self, SEL _cmd);


@implementation NSURLConnection(mParticle)

+ (void)initialize {
    NSURLConnectionOriginalMethods = @[@"sendAsynchronousRequest:queue:completionHandler:", // Class methods
                                       @"sendSynchronousRequest:returningResponse:error:",
                                       @"connectionWithRequest:delegate:",
                                       @"initWithRequest:delegate:", // Instance methods
                                       @"initWithRequest:delegate:startImmediately:",
                                       @"start",
                                       @"cancel"];
    
    mpNSURLConnectionImplementedSelectors = @[@"initWithRequest:delegate:", @"initWithRequest:delegate:startImmediately:", @"start", @"cancel"];
    
    excludeURLs = [[NSMutableArray alloc] init];
    preserverQueryFilters = [[NSMutableArray alloc] init];
    
    size_t allocMemorySize = NSURLConnectionOriginalMethods.count * sizeof(IMP);
    
    originalMethodsImplementations = malloc(allocMemorySize);
    swizzledMethodsImplementations = malloc(allocMemorySize);
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));

    if ([connectionAssociate.delegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:connectionAssociate.delegate];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    id target = nil;
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));

    if ([(NSObject *)connectionAssociate.delegate respondsToSelector:aSelector]) {
        target = connectionAssociate.delegate;
    } else {
        target = [super forwardingTargetForSelector:aSelector];
    }
    
    return target;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        signature = [(NSObject *)connectionAssociate.delegate methodSignatureForSelector:selector];
    }
    
    return signature;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSString *selectorString = NSStringFromSelector(aSelector);
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    BOOL respondsToSelector = [mpNSURLConnectionImplementedSelectors containsObject:selectorString] || [(NSObject *)connectionAssociate.delegate respondsToSelector:aSelector] || [super respondsToSelector:aSelector];
    
    return respondsToSelector;
}

- (void)dealloc {
    objc_removeAssociatedObjects(self);
}

#pragma mark Swizzled methods
void swizzledSendAsynchronousRequest(id self, SEL _cmd, NSURLRequest *request, NSOperationQueue *queue, MPAsynchronousRequestCompletionHandler handler) {
    NSString *npeHeader = [request valueForHTTPHeaderField:kMPMessageTypeNetworkPerformance];
    MPNetworkMeasurementMode networkMeasurementMode = npeHeader ? MPNetworkMeasurementModeExclude : [NSURLConnection networkMeasurementModeForRequest:request];
    
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
    [networkPerformance setStartDate:[NSDate date]];
    networkPerformance.bytesOut = [NSURLConnection sizeForRequest:request];
    
    IMP originalSendAsynchronousRequest = originalMethodsImplementations[MPSwizzledIndexSendAsynchronousRequest];
    ((void (*)(id, SEL, NSURLRequest *, NSOperationQueue *, MPAsynchronousRequestCompletionHandler))originalSendAsynchronousRequest)(self, _cmd, request, queue, ^(NSURLResponse *response, NSData *data, NSError *error) {
        [networkPerformance setEndDate:[NSDate date]];
        
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
        networkPerformance.responseCode = [httpURLResponse statusCode];
        networkPerformance.bytesIn = [data length] + [NSURLConnection sizeForResponse:httpURLResponse];
        
        if (networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
            });
        }
        
        handler(response, data, error);
    });
}

NSData *swizzledSendSynchronousRequest(id self, SEL _cmd, NSURLRequest *request, NSURLResponse **response, NSError **error) {
    MPNetworkMeasurementMode networkMeasurementMode = [NSURLConnection networkMeasurementModeForRequest:request];
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
    [networkPerformance setStartDate:[NSDate date]];
    networkPerformance.bytesOut = [NSURLConnection sizeForRequest:request];
    
    IMP originalSendSynchronousRequest = originalMethodsImplementations[MPSwizzledIndexSendSynchronousRequest];
    NSData *data = ((NSData * (*)(id, SEL, NSURLRequest *, NSURLResponse **, NSError **))originalSendSynchronousRequest)(self, _cmd, request, response, error);
    
    [networkPerformance setEndDate:[NSDate date]];
    NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)*response;
    networkPerformance.responseCode = [httpURLResponse statusCode];
    networkPerformance.bytesIn = [data length] + [NSURLConnection sizeForResponse:httpURLResponse];
    
    if (networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
        });
    }
    
    return data;
}

NSURLConnection *swizzledConnectionWithRequest(id self, SEL _cmd, NSURLRequest *request, id<NSURLConnectionDelegate> delegate) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:NO];
#pragma clang diagnostic pop
    [connection start];
    
    return connection;
}

id swizzledInitWithRequest(id self, SEL _cmd, NSURLRequest *request, id<NSURLConnectionDelegate> delegate) {
    IMP originalInitWithRequest = originalMethodsImplementations[MPSwizzledIndexInitWithRequest];
    self = ((id (*)(id, SEL, NSURLRequest *, id<NSURLConnectionDelegate>))originalInitWithRequest)(self, _cmd, request, self);
    
    MPNetworkMeasurementMode networkMeasurementMode = [NSURLConnection networkMeasurementModeForRequest:request];
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
    networkPerformance.bytesOut = [NSURLConnection sizeForRequest:request];
    [networkPerformance setStartDate:[NSDate date]];
    
    MPURLConnectionAssociate *connectionAssociate = [[MPURLConnectionAssociate alloc] init];
    connectionAssociate.delegate = delegate;
    connectionAssociate.networkPerformance = networkPerformance;
    
    objc_setAssociatedObject(self, @selector(self), connectionAssociate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return self;
}

id swizzledInitWithRequestStartImmediately(id self, SEL _cmd, NSURLRequest *request, id<NSURLConnectionDelegate> delegate, BOOL startImmediately) {
    IMP originalInitWithRequestStartImmediately = originalMethodsImplementations[MPSwizzledIndexInitWithRequestStartImmediately];
    self = ((id (*)(id, SEL, NSURLRequest *, id<NSURLConnectionDelegate>, BOOL))originalInitWithRequestStartImmediately)(self, _cmd, request, self, startImmediately);
    
    MPNetworkMeasurementMode networkMeasurementMode = [NSURLConnection networkMeasurementModeForRequest:request];
    MPNetworkPerformance *networkPerformance = [[MPNetworkPerformance alloc] initWithURLRequest:request networkMeasurementMode:networkMeasurementMode];
    networkPerformance.bytesOut = [NSURLConnection sizeForRequest:request];
    
    MPURLConnectionAssociate *connectionAssociate = [[MPURLConnectionAssociate alloc] init];
    connectionAssociate.delegate = delegate;
    connectionAssociate.networkPerformance = networkPerformance;
    
    objc_setAssociatedObject(self, @selector(self), connectionAssociate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    return self;
}

void swizzledStart(id self, SEL _cmd) {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    [connectionAssociate.networkPerformance setStartDate:[NSDate date]];
    
    IMP originalStart = originalMethodsImplementations[MPSwizzledIndexStart];
    ((void (*)(id, SEL))originalStart)(self, _cmd);
}

void swizzledCancel(id self, SEL _cmd) {
    objc_removeAssociatedObjects(self);
    
    IMP originalCancel = originalMethodsImplementations[MPSwizzledIndexCancel];
    ((void (*)(id, SEL))originalCancel)(self, _cmd);
}

#pragma mark Private class methods
+ (NSUInteger)sizeForRequest:(NSURLRequest *const)request {
    NSDictionary *allHeaderFields = [request allHTTPHeaderFields];
    NSString *headerValue;
    NSUInteger bodySize = [[request HTTPBody] length];
    NSUInteger urlLength = [[request.URL absoluteString] length];
    NSUInteger headersSize = 0;
    
    for (NSString *headerField in allHeaderFields) {
        headerValue = [request valueForHTTPHeaderField:headerField];
        headersSize += [headerField length] + [headerValue length];
    }
    
    return bodySize + urlLength + headersSize;
}

+ (NSUInteger)sizeForResponse:(NSHTTPURLResponse *const)response {
    NSDictionary *allHeaderFields = [response allHeaderFields];
    NSString *headerValue;
    NSUInteger headersSize = 0;
    
    for (NSString *headerField in allHeaderFields) {
        headerValue = allHeaderFields[headerField];
        headersSize += [headerField length] + [headerValue length];
    }
    
    return headersSize;
}

+ (MPNetworkMeasurementMode)networkMeasurementModeForRequest:(NSURLRequest *const)request {
//    __block NetworkMeasurementMode networkMeasurementMode = NetworkMeasurementModeAbridged;
// TODO: #warning Preserving query by default is temporary until we implement the server side exception list
    __block MPNetworkMeasurementMode networkMeasurementMode = MPNetworkMeasurementModePreserveQuery;
    
    NSString *urlString = [NSString stringWithFormat:ucURLFormat, [request.URL scheme], [request.URL host]];
    [excludeURLs enumerateObjectsWithOptions:NSEnumerationConcurrent
                                  usingBlock:^(NSString *excludeURL, NSUInteger idx, BOOL *stop) {
                                      NSRange range = [excludeURL rangeOfString:urlString];
                                      
                                      if (range.location != NSNotFound) {
                                          networkMeasurementMode = MPNetworkMeasurementModeExclude;
                                          *stop = YES;
                                      }
                                  }];
    
    if (networkMeasurementMode != MPNetworkMeasurementModeAbridged) {
        return networkMeasurementMode;
    }
    
    urlString = [request.URL absoluteString];
    [preserverQueryFilters enumerateObjectsWithOptions:NSEnumerationConcurrent
                                            usingBlock:^(NSString *preserverQueryFilter, NSUInteger idx, BOOL *stop) {
                                                NSRange range = [urlString rangeOfString:preserverQueryFilter];
                                                
                                                if (range.location != NSNotFound) {
                                                    networkMeasurementMode = MPNetworkMeasurementModePreserveQuery;
                                                    *stop = YES;
                                                }
                                            }];
    
    return networkMeasurementMode;
}

#pragma mark Public class methods
+ (void)freeResources {
    free(originalMethodsImplementations);
    free(swizzledMethodsImplementations);
}

+ (BOOL)methodsSwizzled {
    return NSURLConnectionMethodsSwizzled;
}

+ (void)swizzleMethods {
    if (NSURLConnectionMethodsSwizzled) {
        return;
    }
    
    NSURLConnectionMethodsSwizzled = YES;
    
    // Class methods
    swizzledMethodsImplementations[MPSwizzledIndexSendAsynchronousRequest] = (IMP)swizzledSendAsynchronousRequest;
    swizzledMethodsImplementations[MPSwizzledIndexSendSynchronousRequest] = (IMP)swizzledSendSynchronousRequest;
    swizzledMethodsImplementations[MPSwizzledIndexConnectionWithRequest] = (IMP)swizzledConnectionWithRequest;
    // Instance methods
    swizzledMethodsImplementations[MPSwizzledIndexInitWithRequest] = (IMP)swizzledInitWithRequest;
    swizzledMethodsImplementations[MPSwizzledIndexInitWithRequestStartImmediately] = (IMP)swizzledInitWithRequestStartImmediately;
    swizzledMethodsImplementations[MPSwizzledIndexStart] = (IMP)swizzledStart;
    swizzledMethodsImplementations[MPSwizzledIndexCancel] = (IMP)swizzledCancel;

    Method originalMethod;
    MPSwizzledIndex idx = MPSwizzledIndexSendAsynchronousRequest;
    SEL originalSelector;
    for (NSString *originalMethodName in NSURLConnectionOriginalMethods) {
        originalSelector = NSSelectorFromString(originalMethodName);
        
        if (idx < MPSwizzledIndexInitWithRequest) { // Class methods
            originalMethod = class_getClassMethod([NSURLConnection class], originalSelector);
        } else { // Instance methods
            originalMethod = class_getInstanceMethod([NSURLConnection class], originalSelector);
        }
        
        originalMethodsImplementations[idx] = method_setImplementation(originalMethod, swizzledMethodsImplementations[idx]);
        ++idx;
    }
}

+ (void)restoreMethods {
    if (!NSURLConnectionMethodsSwizzled) {
        return;
    }
    
    NSString *originalMethodName;
    Method originalMethod;
    SEL originalSelector;
    for (MPSwizzledIndex idx = MPSwizzledIndexSendAsynchronousRequest; idx <= MPSwizzledIndexCancel; ++idx) {
        originalMethodName = NSURLConnectionOriginalMethods[idx];
        originalSelector = NSSelectorFromString(originalMethodName);
        
        if (idx < MPSwizzledIndexInitWithRequest) { // Class methods
            originalMethod = class_getClassMethod([NSURLConnection class], originalSelector);
        } else { // Instance methods
            originalMethod = class_getInstanceMethod([NSURLConnection class], originalSelector);
        }
        
        method_setImplementation(originalMethod, originalMethodsImplementations[idx]);
    }

    NSURLConnectionMethodsSwizzled = NO;
}

+ (void)excludeURLFromNetworkPerformanceMeasuring:(NSURL *)url {
    NSString *urlAbsoluteString = [[url absoluteString] copy];
    
    if ([excludeURLs containsObject:urlAbsoluteString]) {
        return;
    }
    
    [excludeURLs addObject:urlAbsoluteString];
}

+ (void)preserveQueryMeasuringNetworkPerformance:(NSString *)queryString {
    NSString *preserveQueryString = [queryString copy];
    
    if ([preserverQueryFilters containsObject:preserveQueryString]) {
        return;
    }
    
    [preserverQueryFilters addObject:preserveQueryString];
}

+ (void)resetNetworkPerformanceExclusionsAndFilters {
    [excludeURLs removeAllObjects];
    [preserverQueryFilters removeAllObjects];
}

#pragma mark NSURLConnectionDelegate methods
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        return [connectionAssociate.delegate connection:connection canAuthenticateAgainstProtectionSpace:protectionSpace];
    }
    
    return NO;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connection:connection didCancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connection:connection didFailWithError:error];
    }
    
    connectionAssociate.delegate = nil;
    objc_removeAssociatedObjects(self);
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connection:connection didReceiveAuthenticationChallenge:challenge];
    }
}

// Not implemented, on purpose
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        return [connectionAssociate.delegate connectionShouldUseCredentialStorage:connection];
    }
    
    return NO;
}

#pragma mark NSURLConnectionDataDelegate methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    connectionAssociate.networkPerformance.bytesIn += [data length];

    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connection:connection didReceiveData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    connectionAssociate.networkPerformance.responseCode = [(NSHTTPURLResponse *)response statusCode];
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connection:connection didReceiveResponse:response];
    }
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connection:connection didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

// Not implemented, on purpose
//- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request {
//}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        return [connectionAssociate.delegate connection:connection willCacheResponse:cachedResponse];
    }
    
    return nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        return [connectionAssociate.delegate connection:connection willSendRequest:request redirectResponse:redirectResponse];
    }
    
    return request;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    MPURLConnectionAssociate *connectionAssociate = objc_getAssociatedObject(self, @selector(self));
    [connectionAssociate.networkPerformance setEndDate:[NSDate date]];
    
    if ([connectionAssociate.delegate respondsToSelector:_cmd]) {
        [connectionAssociate.delegate connectionDidFinishLoading:connection];
    }
    
    if (connectionAssociate.networkPerformance.networkMeasurementMode != MPNetworkMeasurementModeExclude) {
        MPNetworkPerformance *networkPerformance = [connectionAssociate.networkPerformance copy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kMPNetworkPerformanceMeasurementNotification object:nil userInfo:@{kMPNetworkPerformanceKey:networkPerformance}];
        });
    }
    
    connectionAssociate.delegate = nil;
    objc_removeAssociatedObjects(self);
}

@end
