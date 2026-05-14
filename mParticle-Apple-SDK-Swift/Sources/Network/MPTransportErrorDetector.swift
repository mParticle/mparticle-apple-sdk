import Foundation

@objc public class MPTransportErrorDetector: NSObject {
    private static let noConnectionErrorCode = 1

    @objc(isRetriableTransportError:)
    public static func isRetriableTransportError(_ error: NSError?) -> Bool {
        guard let error else {
            return false
        }

        if error.code == noConnectionErrorCode {
            return true
        }

        if error.domain == NSURLErrorDomain {
            switch error.code {
            case NSURLErrorNotConnectedToInternet,
                NSURLErrorTimedOut,
                NSURLErrorCannotFindHost,
                NSURLErrorCannotConnectToHost,
                NSURLErrorNetworkConnectionLost,
                NSURLErrorDNSLookupFailed,
                NSURLErrorCannotLoadFromNetwork,
                NSURLErrorSecureConnectionFailed,
                NSURLErrorInternationalRoamingOff,
                NSURLErrorDataNotAllowed,
                NSURLErrorCallIsActive,
                NSURLErrorAppTransportSecurityRequiresSecureConnection:
                return true
            default:
                return false
            }
        }

        return error.domain == "com.mparticle" && error.code == 0
    }
}
