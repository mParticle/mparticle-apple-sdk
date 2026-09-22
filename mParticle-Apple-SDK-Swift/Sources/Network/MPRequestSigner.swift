import CryptoKit
import Foundation

@objc public final class MPRequestSigner: NSObject {
    private static let maxQueryLength = 8192

    @objc(hmacSHA256HexForMessage:key:)
    public static func hmacSHA256Hex(message: String?, key: String?) -> String? {
        guard let message, let key else {
            return nil
        }

        let code = HMAC<SHA256>.authenticationCode(
            for: bytesUpToFirstNUL(of: message),
            using: SymmetricKey(data: bytesUpToFirstNUL(of: key))
        )
        return code.map { String(format: "%02x", $0) }.joined()
    }

    @objc(signatureMessageWithHTTPMethod:date:relativePath:query:)
    public static func signatureMessage(
        httpMethod: String,
        date: String,
        relativePath: String,
        query: String?
    ) -> String {
        guard let query else {
            return "\(httpMethod)\n\(date)\n\(relativePath)"
        }
        return "\(httpMethod)\n\(date)\n\(relativePath)?\(query)"
    }

    @objc(signatureMessageWithHTTPMethod:date:relativePath:body:)
    public static func signatureMessage(
        httpMethod: String,
        date: String,
        relativePath: String,
        body: String
    ) -> String {
        "\(httpMethod)\n\(date)\n\(relativePath)\(body)"
    }

    @objc(exceedsMaxQueryLength:)
    public static func exceedsMaxQueryLength(_ query: String?) -> Bool {
        guard let query else {
            return false
        }
        return (query as NSString).length > maxQueryLength
    }

    private static func bytesUpToFirstNUL(of string: String) -> Data {
        let utf8 = Array(string.utf8)
        guard let nul = utf8.firstIndex(of: 0) else {
            return Data(utf8)
        }
        return Data(utf8[..<nul])
    }
}
