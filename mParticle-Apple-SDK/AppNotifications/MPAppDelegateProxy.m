#import "MPAppDelegateProxy.h"
#import "MPIConstants.h"
#import "MPSurrogateAppDelegate.h"
#import "MPILogger.h"
#import "MParticle.h"
#import <objc/runtime.h>

@interface MPAppDelegateProxy() {
    SEL applicationOpenURLOptionsSelector;
#if TARGET_OS_IOS == 1
    SEL applicationOpenURLSelector;
    SEL didFailToRegisterForRemoteNotificationSelector;
    SEL didReceiveRemoteNotificationSelector;
    SEL didRegisterForRemoteNotificationSelector;
    SEL handleActionWithIdentifierForRemoteNotificationSelector;
    SEL handleActionWithIdentifierForRemoteNotificationSelectorWithResponseInfo;
    SEL continueUserActivityRestorationHandlerSelector;
    SEL didUpdateUserActivitySelector;
    SEL originalAppDelegateSelector;
#endif
}

@end

@implementation MPAppDelegateProxy

- (instancetype)initWithOriginalAppDelegate:(id)originalAppDelegate {
    _originalAppDelegate = originalAppDelegate;

    applicationOpenURLOptionsSelector = @selector(application:openURL:options:);
#if TARGET_OS_IOS == 1
    applicationOpenURLSelector = @selector(application:openURL:sourceApplication:annotation:);
    didFailToRegisterForRemoteNotificationSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
    didReceiveRemoteNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    didRegisterForRemoteNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
    continueUserActivityRestorationHandlerSelector = @selector(application:continueUserActivity:restorationHandler:);
    didUpdateUserActivitySelector = @selector(application:didUpdateUserActivity:);
    originalAppDelegateSelector = @selector(originalAppDelegate);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    handleActionWithIdentifierForRemoteNotificationSelector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    handleActionWithIdentifierForRemoteNotificationSelectorWithResponseInfo = @selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:);
#pragma clang diagnostic pop
#endif
    return self;
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    BOOL conformsToProtocol = [self.surrogateAppDelegate conformsToProtocol:aProtocol];
    
    if (!conformsToProtocol) {
        conformsToProtocol = [_originalAppDelegate conformsToProtocol:aProtocol];
    }
    
    return conformsToProtocol;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate respondsToSelector:selector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:selector]) {
        MPILogError(@"App Delegate does not implement selector: %@", NSStringFromSelector(selector));
    }
    
    [anInvocation invokeWithTarget:target];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate respondsToSelector:aSelector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:aSelector]) {
        MPILogError(@"App Delegate does not implement selector: %@", NSStringFromSelector(aSelector));
    }
    
    return target;
}

- (BOOL)isKindOfClass:(Class)aClass {
    BOOL isKindOfClass = [self.surrogateAppDelegate isKindOfClass:aClass];
    
    if (!isKindOfClass) {
        isKindOfClass = [_originalAppDelegate isKindOfClass:aClass];
    }
    
    return isKindOfClass;
}

- (BOOL)isMemberOfClass:(Class)aClass {
    BOOL isMemberOfClass = [self.surrogateAppDelegate isMemberOfClass:aClass];
    
    if (!isMemberOfClass) {
        isMemberOfClass = [_originalAppDelegate isMemberOfClass:aClass];
    }
    
    return isMemberOfClass;
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
    BOOL respondsToSelector;
    if ([_originalAppDelegate respondsToSelector:aSelector]) {
        respondsToSelector = YES;
    } else {
        respondsToSelector = (aSelector == applicationOpenURLOptionsSelector && [[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0)
#if TARGET_OS_IOS == 1
                             ||
                             (aSelector == applicationOpenURLSelector) ||
                             (aSelector == didFailToRegisterForRemoteNotificationSelector) ||
                             (aSelector == didReceiveRemoteNotificationSelector) ||
                             (aSelector == didRegisterForRemoteNotificationSelector) ||
                             (aSelector == handleActionWithIdentifierForRemoteNotificationSelector) ||
                             (aSelector == handleActionWithIdentifierForRemoteNotificationSelectorWithResponseInfo) ||
                             (aSelector == continueUserActivityRestorationHandlerSelector) ||
                             (aSelector == didUpdateUserActivitySelector)  ||
                             (aSelector == originalAppDelegateSelector);
#else
        ;
#endif
    }
    
    return respondsToSelector;
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
