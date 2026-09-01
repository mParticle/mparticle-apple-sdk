import Foundation

/// Selectors implemented by the Rokt kit and invoked synchronously by `MPRokt`.
///
/// Rokt kit versions must adopt this protocol to receive these calls. A
/// nonconforming target is rejected safely by the dispatcher.
@objc(MPRoktKitDispatchTarget)
public protocol MPRoktKitDispatchTarget: AnyObject {
    @objc(getSessionId)
    optional func getSessionId() -> String?

    @objc(handleURLCallback:)
    optional func handleURLCallback(_ url: URL) -> Bool

    @objc(logMParticleApiDiagnostic:)
    optional func logMParticleApiDiagnostic(_ code: String)
}
