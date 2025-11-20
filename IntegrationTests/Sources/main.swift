import Foundation
import mParticle_Apple_SDK

// Listener for tracking upload events
class EventUploadWaiter: NSObject, MPListenerProtocol {
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

// Register listener for tracking upload events
let listener = EventUploadWaiter()
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

// Test 4: Log Commerce Event with Product and Transaction
// Based on ViewController.m logCommerceEvent method (lines 153-180)
let product = MPProduct(
    name: "Awesome Book",
    sku: "1234567890",
    quantity: NSNumber(value: 1),
    price: NSNumber(value: 9.99)
)
product.brand = "A Publisher"
product.category = "Fiction"
product.couponCode = "XYZ123"
product.position = 1
product["custom key"] = "custom value" // Product may contain custom key/value pairs

// Create a commerce event with purchase action
let commerceEvent = MPCommerceEvent(action: .purchase, product: product)
commerceEvent.checkoutOptions = "Credit Card"
commerceEvent.screenName = "Timeless Books"
commerceEvent.checkoutStep = 4
commerceEvent.customAttributes = ["an_extra_key": "an_extra_value"] // Commerce event may contain custom key/value pairs

// Create transaction attributes
let transactionAttributes = MPTransactionAttributes()
transactionAttributes.affiliation = "Book seller"
transactionAttributes.shipping = NSNumber(value: 1.23)
transactionAttributes.tax = NSNumber(value: 0.87)
transactionAttributes.revenue = NSNumber(value: 12.09)
transactionAttributes.transactionId = "zyx098"
commerceEvent.transactionAttributes = transactionAttributes

// Log the commerce event
mparticle.logEvent(commerceEvent)
listener.wait()

// Test 5: Rokt Select Overlay Placement
// Based on ViewController.m selectOverlayPlacement method (lines 182-192)
// Tests Rokt SDK integration through mParticle for selecting placements with custom attributes
let roktAttributes: [String: String] = [
    "email": "j.smit@example.com",
    "firstname": "Jenny",
    "lastname": "Smith",
    "sandbox": "true",
    "mobile": "(555)867-5309"
]

// Select Rokt placement with identifier and attributes
mparticle.rokt.selectPlacements("RoktLayout", attributes: roktAttributes)
listener.wait()