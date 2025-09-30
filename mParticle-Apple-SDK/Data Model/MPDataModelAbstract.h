#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface MPDataModelAbstract : NSObject <NSCopying> {
@protected
  NSString *_uuid;
}

@property(nonatomic, strong, nullable) NSString *uuid;

- (nonnull id)copyWithZone:(nullable NSZone *)zone;

@end
