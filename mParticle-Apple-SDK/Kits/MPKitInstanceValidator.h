#import <Foundation/Foundation.h>

@interface MPKitInstanceValidator : NSObject

+ (BOOL)isValidKitCode:(nonnull NSNumber *)integrationId;

@end
