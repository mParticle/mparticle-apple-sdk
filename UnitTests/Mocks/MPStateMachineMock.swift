import XCTest
import mParticle_Apple_SDK
internal import mParticle_Apple_SDK_Swift

class MPStateMachineMock: NSObject, MPStateMachineProtocolPRIVATE {
    var optOut: Bool = false

    var logLevel: UInt = 0

    var consumerInfo: MPConsumerInfoPRIVATE = .init()

    var automaticSessionTracking: Bool = false

    var currentSession: MPSessionPRIVATE? = nil

    var attAuthorizationStatus: NSNumber? = nil

    var attAuthorizationTimestamp: NSNumber? = nil

    var apiKey: String = "apiKey"

    var secret: String = "secret"
}
