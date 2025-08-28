import XCTest
#if MPARTICLE_LOCATION_DISABLE
import mParticle_Apple_SDK_NoLocation
#else
import mParticle_Apple_SDK
#endif

class MPStateMachineMock: MPStateMachineProtocol {
#if !MPARTICLE_LOCATION_DISABLE
    var location: CLLocation? = nil
    
    var locationManager: mParticle_Apple_SDK.MPLocationManager_PRIVATE?
#endif
    var optOut: Bool = false
    
    var logLevel: MPILogLevel = .none
    
    var consumerInfo: MPConsumerInfo = MPConsumerInfo()
    
    var automaticSessionTracking: Bool = false
    
    var currentSession: MPSession? = nil
    
    var attAuthorizationStatus: NSNumber? = nil
    
    var attAuthorizationTimestamp: NSNumber? = nil
    
    var apiKey: String = "apiKey"
    
    var secret: String = "secret"
}
