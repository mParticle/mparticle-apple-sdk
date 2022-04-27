#import <Foundation/Foundation.h>

@interface MPForwardQueueParameters : NSObject

@property (nonatomic, readonly) NSUInteger count;

- (nonnull instancetype)initWithParameters:(nonnull NSArray *)parameters;
- (void)addParameter:(nullable id)parameter;
- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx;

@end
