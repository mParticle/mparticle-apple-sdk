#ifndef mParticle_Apple_SDK_MPRoktKitDispatchTarget_h
#define mParticle_Apple_SDK_MPRoktKitDispatchTarget_h

#import <Foundation/Foundation.h>

/**
 Selectors implemented by the Rokt kit and invoked synchronously by `MPRokt`.

 Rokt kit versions must adopt this protocol to receive these calls. A
 nonconforming kit instance is rejected without invoking the selectors.
 */
@protocol MPRoktKitDispatchTarget <NSObject>

@optional

/**
 Returns the current Rokt session identifier for WebView hand-off.

 @return The session identifier, or `nil` if no session is present.
 */
- (NSString * _Nullable)getSessionId;

/**
 Forwards a redirect URL (for example Afterpay or PayPal) to registered payment extensions.

 @param url The URL received by the app's URL handler.
 @return `YES` if a payment extension claimed the URL; otherwise `NO`.
 */
- (BOOL)handleURLCallback:(NSURL * _Nonnull)url;

/**
 Records a bounded, non-PII public-API-usage diagnostic code (for example `"LOG_EVENT"`).

 @param code The diagnostic code for the partner-facing API that was called.
 */
- (void)logMParticleApiDiagnostic:(NSString * _Nonnull)code;

@end

#endif
