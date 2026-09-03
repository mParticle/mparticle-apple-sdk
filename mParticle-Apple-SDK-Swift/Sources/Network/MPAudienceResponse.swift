import Foundation

/// Wire keys for the audience membership endpoint.
///
/// These mirror the exported Objective-C constants `kMPAudienceMembershipKey` and
/// `kMPAudienceIdKey` defined in `MPAudience.m`. Objective-C keeps those globals because Swift
/// cannot export C constants; the values here must stay identical to them.
enum AudienceKeys {
    static let membership = "audience_memberships"
    static let audienceID = "audience_id"
}

/// Result of decoding an audience membership response body.
///
/// Objective-C turns `audienceIDs` into `MPAudience` objects; this type never sees an SDK type.
@objc(MPAudienceResponsePRIVATE)
public final class MPAudienceResponsePRIVATE: NSObject {
    /// Whether the request both succeeded at the HTTP level and produced a decodable body.
    @objc public let isSuccess: Bool

    /// The decoded audience identifiers, in response order. Empty means "no audiences".
    @objc public let audienceIDs: [NSNumber]

    /// The error to hand back to the caller, if the response warrants one.
    @objc public let error: NSError?

    init(isSuccess: Bool, audienceIDs: [NSNumber], error: NSError?) {
        self.isSuccess = isSuccess
        self.audienceIDs = audienceIDs
        self.error = error
        super.init()
    }

    /// Decodes an audience response, logging the same messages the Objective-C implementation did.
    @objc(responseFromData:statusCode:logger:)
    public static func response(from data: Data?, statusCode: Int, logger: MPLog) -> MPAudienceResponsePRIVATE {
        guard let data else {
            return MPAudienceResponsePRIVATE(
                isSuccess: false,
                audienceIDs: [],
                error: audienceError(code: statusCode, message: "Audiences may not be enabled for this org.")
            )
        }

        var isSuccess = (statusCode == HTTPStatusCode.success.rawValue
            || statusCode == HTTPStatusCode.accepted.rawValue)
            && !data.isEmpty
        var audienceIDs: [NSNumber] = []

        if isSuccess {
            var memberships: [Any] = []
            do {
                let body = try JSONSerialization.jsonObject(with: data)
                if let dictionary = body as? [String: Any] {
                    memberships = dictionary[AudienceKeys.membership] as? [Any] ?? []
                }
            } catch {
                isSuccess = false
                logger.error("Audiences Error: \(error.localizedDescription)")
            }

            audienceIDs = decodedAudienceIDs(from: memberships, logger: logger)

            if audienceIDs.isEmpty {
                logger.warning("Audiences Error - Response Code: \(statusCode)")
            } else {
                logger.verbose("Audiences Response Code: \(statusCode)")
            }
        }

        var error: NSError?
        if statusCode == HTTPStatusCode.forbidden.rawValue {
            error = audienceError(code: statusCode, message: "Audiences not enabled for this org.")
        }

        return MPAudienceResponsePRIVATE(isSuccess: isSuccess, audienceIDs: audienceIDs, error: error)
    }

    /// Keeps only numeric identifiers. `MPAudience.audienceId` is a `nonnull NSNumber`, so a
    /// string or null identifier from the server would otherwise produce an object whose property
    /// does not hold the declared type.
    private static func decodedAudienceIDs(from memberships: [Any], logger: MPLog) -> [NSNumber] {
        var audienceIDs: [NSNumber] = []
        for membership in memberships {
            guard let dictionary = membership as? [String: Any] else {
                logger.warning("Audiences Error - Skipping malformed audience entry.")
                continue
            }
            guard let audienceID = dictionary[AudienceKeys.audienceID] as? NSNumber else {
                logger.warning("Audiences Error - Skipping audience with a non-numeric identifier.")
                continue
            }
            audienceIDs.append(audienceID)
        }
        return audienceIDs
    }

    private static func audienceError(code: Int, message: String) -> NSError {
        NSError(domain: "mParticle Audiences", code: code, userInfo: ["message": message])
    }
}
