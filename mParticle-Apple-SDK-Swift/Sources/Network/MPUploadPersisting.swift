import Foundation

/// The single persistence operation the network upload paths depend on, expressed
/// as a Foundation-only seam so upload handling can move to Swift without reaching
/// the Objective-C persistence controller (which the Swift module cannot import).
/// The concrete conformer forwards to `MParticle.sharedInstance.persistenceController`.
@objc public protocol MPUploadPersisting: AnyObject {
    @objc func deleteUpload(_ upload: MPUploadPRIVATE)
}
