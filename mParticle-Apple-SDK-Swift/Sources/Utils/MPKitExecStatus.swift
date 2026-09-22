import Foundation

// Operates on the raw NSUInteger value of MPKitReturnCode (defined in the public
// MPKitExecStatus.h, which this Foundation-only module cannot import):
// 0 = Success, 1 = Fail, 2 = CannotExecute, 3 = Unavailable,
// 4 = IncorrectProductVersion, 5 = RequirementsNotMet.
@objc(MPKitExecStatusPRIVATE) public class MPKitExecStatusPRIVATE: NSObject {
    @objc public static func isValidReturnCode(_ raw: UInt) -> Bool {
        raw <= 5
    }

    @objc public static func isSuccess(_ raw: UInt) -> Bool {
        raw == 0
    }

    @objc public static func defaultForwardCount(forReturnCode raw: UInt) -> UInt {
        raw == 0 ? 1 : 0
    }
}
