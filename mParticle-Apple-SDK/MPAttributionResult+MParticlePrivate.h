#import <Foundation/Foundation.h>
#import "mParticle.h"

@interface MPAttributionResult ()

@property (nonatomic, readwrite) NSNumber *kitCode;
@property (nonatomic, readwrite) NSString *kitName;

- (instancetype)initWithKitCode:(NSNumber *) kitCode kitName:(NSString *) kitName;

- (NSString *)description;

@end
