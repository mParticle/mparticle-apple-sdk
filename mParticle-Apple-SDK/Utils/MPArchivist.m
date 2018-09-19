#import "MPArchivist.h"
#import "MParticle.h"
#import "MPILogger.h"

@implementation MPArchivist

+ (void)archiveDataWithRootObject:(id)object toFile:(NSString *)path error:(NSError ** _Nullable)error {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    @try {
        if (![NSKeyedArchiver archiveRootObject:object toFile:path]) {
            MPILogError(@"Object was not persisted.");
        }
    } @catch(NSException *ex) {
        MPILogger(MPILogLevelError, @"Failed To archive: %@", ex);
    }
#pragma clang diagnostic pop
}

+ (id)unarchiveObjectOfClass:(Class)cls withFile:(NSString *)path error:(NSError ** _Nullable)error {
    id object = nil;
    @try {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        object = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
#pragma clang diagnostic pop
    } @catch(NSException *ex) {
        MPILogger(MPILogLevelError, @"Failed To retrieve %@: %@", cls, ex);
    }
    
    return object;
}

@end
