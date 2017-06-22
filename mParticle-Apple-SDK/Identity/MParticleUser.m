//
//  MParticleUser.m
//

#import "MParticleUser.h"

@implementation MParticleUser


- (nullable NSNumber *)incrementUserAttribute:(NSString *)key byValue:(NSNumber *)value {
    //TODO
    return nil;
}

- (void)setUserAttribute:(NSString *)key value:(nullable id)value {
    //TODO
}

- (void)setUserAttributeList:(NSString *)key values:(nullable NSArray<NSString *> *)values {
    //TODO
}

- (void)setUserTag:(NSString *)tag {
    //TODO
}
- (void)removeUserAttribute:(NSString *)key {
    //TODO
}

#pragma mark - User Segments

- (void)userSegments:(NSTimeInterval)timeout endpointId:(NSString *)endpointId completionHandler:(MPUserSegmentsHandler)completionHandler {
    
}

@end
