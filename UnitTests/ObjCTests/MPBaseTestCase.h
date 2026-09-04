#import <Foundation/Foundation.h>

#define DEFAULT_TIMEOUT 15

@class MPMessageBuilderContext;

@interface MPBaseTestCase : XCTestCase

- (id)attemptSecureEncodingwithClass:(Class)cls Object:(id)object;

/// The message-builder context the SDK itself passes, so tests exercise the same data-plan and
/// logging path production does.
- (MPMessageBuilderContext *)messageBuilderContext;

@end
