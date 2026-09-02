import Foundation

/// Pairs the outgoing endpoint with the canonical endpoint used to sign an SDK request.
@objc(MPURL)
public final class MPURL: NSObject {
    /// The endpoint that receives the request.
    @objc public let url: URL
    /// The canonical mParticle endpoint used when signing the request.
    @objc public let defaultURL: URL

    /// Creates a URL pair when both endpoints are available.
    @objc(initWithURL:defaultURL:)
    public init?(url: URL?, defaultURL: URL?) {
        guard let url, let defaultURL else {
            return nil
        }

        self.url = url
        self.defaultURL = defaultURL
        super.init()
    }
}
