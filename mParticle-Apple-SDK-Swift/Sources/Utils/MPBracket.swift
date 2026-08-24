import Foundation

@objc public final class MPBracketPRIVATE: NSObject {
    @objc public var mpId: Int64
    @objc public var low: Int16
    @objc public var high: Int16

    @objc public override init() {
        mpId = 0
        low = 0
        high = 100
        super.init()
    }

    @objc public init(mpId: Int64, low: Int16, high: Int16) {
        self.mpId = mpId
        self.low = low
        self.high = high
        super.init()
    }

    @objc public func shouldForward() -> Bool {
        guard mpId != 0, high != 0 else {
            return false
        }

        let shiftedMpId = mpId >> 8
        let absoluteValue = shiftedMpId < 0 ? -shiftedMpId : shiftedMpId
        let userBucket = absoluteValue % 100
        return userBucket >= Int64(low) && userBucket < Int64(high)
    }

    @objc(isEqualToBracket:)
    public func isEqual(to bracket: MPBracketPRIVATE?) -> Bool {
        guard let bracket else {
            return false
        }

        return mpId == bracket.mpId &&
            low == bracket.low &&
            high == bracket.high
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let bracket = object as? MPBracketPRIVATE else {
            return false
        }

        return isEqual(to: bracket)
    }

    override public var hash: Int {
        Int(truncatingIfNeeded: mpId ^ Int64(low) ^ Int64(high))
    }

    override public var description: String {
        "<MPBracket: mpId=\(mpId), low=\(low), high=\(high)>"
    }
}
