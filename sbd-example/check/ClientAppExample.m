/// Example of using module A in Objective-C Client App
///
/// This file demonstrates how a client application (Objective-C)
/// can use module A

@import Foundation;
@import A;

@implementation ClientAppExample

- (void)demonstrateUsage {
    // Use ObjC module A
    AThing *thing = [[AThing alloc] init];
    [thing demo];
    
    // Module A inside uses BObjC, which in turn
    // uses pure Swift module B
    // But client application doesn't know about this
}

@end

