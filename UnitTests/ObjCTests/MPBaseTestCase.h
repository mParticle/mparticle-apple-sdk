#import <Foundation/Foundation.h>

#define DEFAULT_TIMEOUT 15

@interface MPBaseTestCase : XCTestCase

- (id)attemptSecureEncodingwithClass:(Class)cls Object:(id)object;

@end
