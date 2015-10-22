//
//  MPAppDelegateProxy.m
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

#import "MPAppDelegateProxy.h"
#import "MPStateMachine.h"
#import "MPConstants.h"
#import "MPSurrogateAppDelegate.h"
#import "MPLogger.h"

@interface MPAppDelegateProxy() {
    SEL applicationOpenURLOptions;
    SEL applicationOpenURLSelector;
    SEL didFailToRegisterForRemoteNotificationSelector;
    SEL didReceiveLocalNotificationSelector;
    SEL didReceiveRemoteNotificationSelector;
    SEL didRegisterForRemoteNotificationSelector;
    SEL handleActionWithIdentifierForLocalNotificationSelector;
    SEL handleActionWithIdentifierForRemoteNotificationSelector;
}

@end

@implementation MPAppDelegateProxy

- (instancetype)initWithOriginalAppDelegate:(id)originalAppDelegate {
    _originalAppDelegate = originalAppDelegate;

    applicationOpenURLOptions = @selector(application:openURL:options:);
    applicationOpenURLSelector = @selector(application:openURL:sourceApplication:annotation:);
    didFailToRegisterForRemoteNotificationSelector = @selector(application:didFailToRegisterForRemoteNotificationsWithError:);
    didReceiveLocalNotificationSelector = @selector(application:didReceiveLocalNotification:);
    didReceiveRemoteNotificationSelector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    didRegisterForRemoteNotificationSelector = @selector(application:didRegisterForRemoteNotificationsWithDeviceToken:);
    handleActionWithIdentifierForLocalNotificationSelector = @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:);
    handleActionWithIdentifierForRemoteNotificationSelector = @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:);
    
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate respondsToSelector:selector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:selector]) {
        MPLogError(@"App Delagate does not implement selector: %@", NSStringFromSelector(selector));
    }
    
    [anInvocation invokeWithTarget:target];
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    id target = _originalAppDelegate;
    
    if ([self.surrogateAppDelegate respondsToSelector:aSelector]) {
        target = self.surrogateAppDelegate;
    } else if (![_originalAppDelegate respondsToSelector:aSelector]) {
        MPLogError(@"App Delagate does not implement selector: %@", NSStringFromSelector(aSelector));
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

- (BOOL)respondsToSelector:(SEL)aSelector {
    BOOL respondsToSelector;
    if ([_originalAppDelegate respondsToSelector:aSelector]) {
        respondsToSelector = YES;
    } else {
        respondsToSelector = (aSelector == applicationOpenURLOptions && [[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) ||
                             (aSelector == applicationOpenURLSelector) ||
                             (aSelector == didFailToRegisterForRemoteNotificationSelector) ||
                             (aSelector == didReceiveLocalNotificationSelector) ||
                             (aSelector == didReceiveRemoteNotificationSelector) ||
                             (aSelector == didRegisterForRemoteNotificationSelector) ||
                             (aSelector == handleActionWithIdentifierForLocalNotificationSelector) ||
                             (aSelector == handleActionWithIdentifierForRemoteNotificationSelector);
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
