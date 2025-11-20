import Foundation
import mParticle_Apple_SDK

// Listener для отслеживания upload событий
class MyUploadListener: NSObject, MPListenerProtocol {
    private var uploadCompletedSemaphore: DispatchSemaphore?
    var mparticle = MParticle.sharedInstance()

    @discardableResult
    func wait(timeout: Int = 10) -> Bool {
        mparticle.upload()
        let semaphore = DispatchSemaphore(value: 0)
        uploadCompletedSemaphore = semaphore
        
        let timeoutTime = DispatchTime.now() + .seconds(timeout)
        let result = semaphore.wait(timeout: timeoutTime)
        
        uploadCompletedSemaphore = nil
        
        return result == .success
    }
    
    func onNetworkRequestFinished(_ type: MPEndpoint, 
                                  url: String, 
                                  body: NSObject, 
                                  responseCode: Int) {
        if type == .events {
            uploadCompletedSemaphore?.signal()
        }
    }
    
    func onNetworkRequestStarted(_ type: MPEndpoint, url: String, body: NSObject) {}
}

var options = MParticleOptions(
    key: "",
    secret: ""
)

var identityRequest = MPIdentityApiRequest.withEmptyUser()
identityRequest.email = "foo@example.com"
identityRequest.customerId = "123456"
options.identifyRequest = identityRequest

options.onIdentifyComplete = { apiResult, error in
    if let apiResult {
        apiResult.user.setUserAttribute("example attribute key", value: "example attribute value")
    }
}
options.logLevel = .verbose

var networkOptions = MPNetworkOptions()
networkOptions.configHost = "127.0.0.1" // config2.mparticle.com
networkOptions.eventsHost = "127.0.0.1" // nativesdks.mparticle.com
networkOptions.identityHost = "127.0.0.1" // identity.mparticle.com
networkOptions.pinningDisabled = true;

options.networkOptions = networkOptions

// Регистрация listener для отслеживания upload событий
let listener = MyUploadListener()
MPListenerController.sharedInstance().addSdkListener(listener)

let mparticle = MParticle.sharedInstance()
mparticle.start(with: options)

sleep(1)

// Test 1: Simple Event
mparticle.logEvent("Simple Event Name", eventType: .other, eventInfo: ["SimpleKey": "SimpleValue"])
listener.wait()