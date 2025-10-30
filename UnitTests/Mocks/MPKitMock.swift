import XCTest
#if MPARTICLE_LOCATION_DISABLE
    import mParticle_Apple_SDK_NoLocation
#else
    import mParticle_Apple_SDK
#endif

class MPKitMock: NSObject, MPKitProtocol {

    // MARK: - Required methods from protocol

    var started: Bool = false

    func didFinishLaunching(withConfiguration configuration: [AnyHashable : Any]) -> MPKitExecStatus {
        return MPKitExecStatus()
    }

    static func kitCode() -> NSNumber {
        return 1
    }

    // MARK: - Methods used in testing

    var logBatchCalled: Bool = false
    var logBatchParam: [AnyHashable: Any]?
    var logBatchReturnValue: [MPForwardRecord] = []


    func logBatch(_ batch: [AnyHashable : Any]) -> [MPForwardRecord] {
        logBatchCalled = true
        logBatchParam = batch
        return logBatchReturnValue
    }


}
