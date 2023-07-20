//
//  MPMediator.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MPMediator.h"

@interface MPMediator()
@property (nonatomic, strong) MPEventLogging *eventLogging;
@end

@implementation MPMediator

- (instancetype)init {
    if (self = [super init]) {
        _eventLogging = [[MPEventLogging alloc] init];
    }
    return self;
}

@end
