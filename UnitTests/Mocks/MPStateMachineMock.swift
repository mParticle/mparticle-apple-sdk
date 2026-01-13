import XCTest
import mParticle_Apple_SDK_NoLocation

class MPStateMachineMock: MPStateMachineProtocol {
    var optOut: Bool = false

    var logLevel: MPILogLevel = .none

    var consumerInfo: MPConsumerInfo = .init()

    var automaticSessionTracking: Bool = false

    var currentSession: MPSession? = nil

    var attAuthorizationStatus: NSNumber? = nil

    var attAuthorizationTimestamp: NSNumber? = nil

    var apiKey: String = "apiKey"

    var secret: String = "secret"
}
