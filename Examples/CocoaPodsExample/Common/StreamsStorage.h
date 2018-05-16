#import <Foundation/Foundation.h>

@class Stream;

@interface StreamsStorage : NSObject

- (NSArray<Stream *> *)fetchStreams;

@end
