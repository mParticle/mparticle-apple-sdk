//
//  MPAttributionResult.m
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/29/23.
//

#import "MPAttributionResult.h"

@interface MPAttributionResult ()
@property (nonatomic, readwrite) NSNumber *kitCode;
@property (nonatomic, readwrite) NSString *kitName;
@end

@implementation MPAttributionResult

- (NSString *)description {
    NSMutableString *description = [[NSMutableString alloc] initWithString:@"MPAttributionResult {\n"];
    [description appendFormat:@"  kitCode: %@\n", _kitCode];
    [description appendFormat:@"  kitName: %@\n", _kitName];
    [description appendFormat:@"  linkInfo: %@\n", _linkInfo];
    [description appendString:@"}"];
    return description;
}

@end
