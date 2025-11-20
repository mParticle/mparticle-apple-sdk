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

// Test 2: Log Event with Custom Attributes and Custom Flags
// Based on ViewController.m logEvent method (lines 131-147)
let event = MPEvent(name: "Event Name", type: .transaction)

// Use static date instead of Date() for deterministic testing
let staticDate = Date(timeIntervalSince1970: 1700000000) // Fixed timestamp: 2023-11-14 22:13:20 UTC

// Add custom attributes including string, number, date, and nested dictionary
event?.customAttributes = [
    "A_String_Key": "A String Value",
    "A Number Key": 42,
    "A Date Key": staticDate,
    "test Dictionary": [
        "test1": "test",
        "test2": 2,
        "test3": staticDate
    ]
]

// Custom flags - sent to mParticle but not forwarded to other providers
event?.addCustomFlag("Top Secret", withKey: "Not_forwarded_to_providers")

// Log the event
if let event = event {
    mparticle.logEvent(event)
}
listener.wait()

// Test 3: Log Screen
// Based on ViewController.m logScreen method (lines 149-151)
mparticle.logScreen("Home Screen", eventInfo: nil)
listener.wait()