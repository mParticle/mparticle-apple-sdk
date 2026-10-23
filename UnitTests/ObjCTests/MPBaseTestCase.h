#import <Foundation/Foundation.h>

#define DEFAULT_TIMEOUT 15

@class MPMessageBuilderContext;
@class MPUploadBuilderContext;
@class MPStateMachine_PRIVATE;
@class MPNetworkCommunication_PRIVATE;

@interface MPBaseTestCase : XCTestCase

- (id)attemptSecureEncodingwithClass:(Class)cls Object:(id)object;

/// The message-builder context the SDK itself passes, so tests exercise the same data-plan and
/// logging path production does.
- (MPMessageBuilderContext *)messageBuilderContext;
- (MPUploadBuilderContext *)uploadBuilderContext;

/// A state machine wired the way the SDK wires its own, for tests that need a clean one.
- (MPStateMachine_PRIVATE *)freshStateMachine;

/// A network layer made the way the SDK makes its own, hosted by the live SDK instance.
- (MPNetworkCommunication_PRIVATE *)sdkNetworkCommunication;

@end
