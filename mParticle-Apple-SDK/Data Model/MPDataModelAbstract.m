#import "MPDataModelAbstract.h"
@import mParticle_Apple_SDK_Swift;

@implementation MPDataModelAbstract

@synthesize uuid = _uuid;

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone {
    MPDataModelAbstract *copyObject = [[[self class] alloc] init];
    if (copyObject) {
        copyObject.uuid = [MPDataModelAbstractPRIVATE copyUUID:_uuid];
    }

    return copyObject;
}

@end
