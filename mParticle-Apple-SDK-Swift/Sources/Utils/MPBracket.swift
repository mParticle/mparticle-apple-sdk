import Foundation

@objc public final class MPBracketPRIVATE: NSObject {
    @objc public static func shouldForward(mpId: Int64, low: Int16, high: Int16) -> Bool {
        guard mpId != 0, high != 0 else {
            return false
        }

        let shiftedMpId = mpId >> 8
        let absoluteValue = shiftedMpId < 0 ? -shiftedMpId : shiftedMpId
        let userBucket = absoluteValue % 100
        return userBucket >= Int64(low) && userBucket < Int64(high)
    }
}
