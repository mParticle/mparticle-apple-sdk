#import "MPAppDelegateProxy.h"
#import "MPIConstants.h"
#import "MPSurrogateAppDelegate.h"
#import "MPILogger.h"
#import "mParticle.h"
#import <objc/runtime.h>

@interface MPAppDelegateProxy() {
    SEL originalAppDelegateSelector;
}

@end

@implementation MPAppDelegateProxy

static MPAppDelegateProxy* _defaultProxy = nil;
+ (MPAppDelegateProxy *)defaultProxy {
    return _defaultProxy;
}

- (instancetype)initWithOriginalAppDelegate:(id)originalAppDelegate {
    _originalAppDelegate = originalAppDelegate;
    originalAppDelegateSelector = @selector(originalAppDelegate);
    static dispatch_once_t pred = 0;
    dispatch_once(&pred, ^{
        _defaultProxy = self;
    });
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate implementsSelector:selector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:selector]) {
        MPILogError(@"App Delegate does not implement selector: %@", NSStringFromSelector(selector));
    }
    
    [anInvocation invokeWithTarget:target];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate implementsSelector:aSelector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:aSelector]) {
        MPILogError(@"App Delegate does not implement selector: %@", NSStringFromSelector(aSelector));
    }
    
    return target;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [[_originalAppDelegate class] instanceMethodSignatureForSelector:selector];
    if (!signature) {
        signature = [self.surrogateAppDelegate methodSignatureForSelector:selector];
        
        if (!signature) {
            signature = [_originalAppDelegate methodSignatureForSelector:selector];
        }
    }
    
    return signature;
}

- (IMP)methodForSelector:(SEL)selector {
    IMP method = NULL;
    if (selector == @selector(originalAppDelegate)) {
        method = method_getImplementation(class_getInstanceMethod(object_getClass(self), selector));
    } else {
        method = [self.surrogateAppDelegate methodForSelector:selector];
        if (!method) {
            method = [[_originalAppDelegate class] methodForSelector:selector];
            
            if (!method) {
                method = [_originalAppDelegate methodForSelector:selector];
            }
        }
    }
    return method;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector = NO;
    if (aSelector == originalAppDelegateSelector) {
        respondsToSelector = YES;
    } else if ([_originalAppDelegate respondsToSelector:aSelector]) {
        respondsToSelector = YES;
    } else if ([self.surrogateAppDelegate implementsSelector:aSelector]) {
        respondsToSelector = YES;
    }
    
    return respondsToSelector;
}

+ (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    id original = [[MPAppDelegateProxy defaultProxy] originalAppDelegate];
    id surrogate = [[MPAppDelegateProxy defaultProxy] surrogateAppDelegate];
    return [original conformsToProtocol:aProtocol] || [surrogate conformsToProtocol:aProtocol];
}

#pragma mark Public accessors
- (MPSurrogateAppDelegate *)surrogateAppDelegate {
    if (_surrogateAppDelegate) {
        return _surrogateAppDelegate;
    }
    
    _surrogateAppDelegate = [[MPSurrogateAppDelegate alloc] init];
    _surrogateAppDelegate.appDelegateProxy = self;
    
    return _surrogateAppDelegate;
}

@end
