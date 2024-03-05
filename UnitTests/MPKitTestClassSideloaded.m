//
//  MPKitTestClassSideloaded.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 3/2/23.
//  Copyright © 2023 mParticle, Inc. All rights reserved.
//

#import "MPKitTestClassSideloaded.h"
#import "MPKitExecStatus.h"

@implementation MPKitTestClassSideloaded
+ (NSNumber *)kitCode {
    return @(-1);
}

- (BOOL)started {
    return YES;
}

- (id)providerKitInstance {
    return self;
}

- (nonnull MPKitExecStatus *)didFinishLaunchingWithConfiguration:(nonnull NSDictionary *)configuration {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.sideloadedKitCode returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)didBecomeActive {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.sideloadedKitCode returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)beginSession {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.sideloadedKitCode returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)endSession {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.sideloadedKitCode returnCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)logBaseEvent:(nonnull MPBaseEvent *)event {
    return [[MPKitExecStatus alloc] initWithSDKCode:self.sideloadedKitCode returnCode:MPKitReturnCodeSuccess];
}

@end
