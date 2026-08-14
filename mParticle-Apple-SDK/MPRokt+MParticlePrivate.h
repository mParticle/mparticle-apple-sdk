//
//  MPRokt+MParticlePrivate.h
//  mParticle-Apple-SDK
//
//  Internal forwarder used by mParticle core to record public-API usage into the Rokt kit.
//  Not partner-facing — deliberately kept out of the public MPRokt.h.
//

#import "MPRokt.h"

@interface MPRokt (MParticlePrivate)

/// Forwards a bounded, non-PII public-API-usage diagnostic code (uppercase SNAKE_CASE, e.g.
/// "LOG_EVENT") to the Rokt kit — only when the kit is active, no-op otherwise.
- (void)logRoktApiDiagnostic:(NSString * _Nonnull)code;

@end
