import Foundation

/// What the backend controller tells the SDK instance that created it.
@objc(MPBackendControllerDelegate)
public protocol MPBackendControllerDelegate: NSObjectProtocol {
    @objc func forwardLogInstall()
    @objc func forwardLogUpdate()
    @objc(sessionDidBegin:) func sessionDidBegin(_ session: MPSessionPRIVATE)
    @objc(sessionDidEnd:) func sessionDidEnd(_ session: MPSessionPRIVATE)
}
