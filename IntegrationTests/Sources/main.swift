import Foundation
import mParticle_Apple_SDK

// Listener for tracking upload events
class EventUploadWaiter: NSObject, MPListenerProtocol {
    private var uploadCompletedSemaphore: DispatchSemaphore?
    var mparticle = MParticle.sharedInstance()

    @discardableResult
    func wait(timeout: Int = 5) -> Bool {
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

// Test 1: Simple Event
func testSimpleEvent(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    mparticle.logEvent("Simple Event Name", eventType: .other, eventInfo: ["SimpleKey": "SimpleValue"])
    uploadWaiter.wait()
}

// Test 2: Log Event with Custom Attributes and Custom Flags
// Based on ViewController.m logEvent method
func testEventWithCustomAttributesAndFlags(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
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
    uploadWaiter.wait()
}

// Test 3: Log Screen
// Based on ViewController.m logScreen method
func testLogScreen(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    mparticle.logScreen("Home Screen", eventInfo: nil)
    uploadWaiter.wait()
}

// Test 4: Log Commerce Event with Product and Transaction
// Based on ViewController.m logCommerceEvent method
func testCommerceEvent(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
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
    uploadWaiter.wait()
}

// Test 5: Rokt Select Overlay Placement
// Based on ViewController.m selectOverlayPlacement method
// Tests Rokt SDK integration through mParticle for selecting placements with custom attributes
func testRoktSelectPlacement(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    let roktAttributes: [String: String] = [
        "email": "j.smit@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]
    
    // Select Rokt placement with identifier and attributes
    mparticle.rokt.selectPlacements("RoktLayout", attributes: roktAttributes)
    uploadWaiter.wait()
}

// Test 6: Get User Audiences
// Based on ViewController.m getAudience method
// Tests retrieving audience memberships for the current user via Identity API
func testGetUserAudiences(mparticle: MParticle) {
    let semaphore = DispatchSemaphore(value: 0)
    
    // Get audiences for current user
    if let currentUser = mparticle.identity.currentUser {
        currentUser.getAudiencesWithCompletionHandler { audiences, error in
            if let error = error {
                print("Failed to retrieve Audience: \(error)")
            } else {
                print("Successfully retrieved Audience for user: \(currentUser.userId) with audiences: \(audiences)")
            }
            semaphore.signal()
        }
    } else {
        print("No current user available")
        semaphore.signal()
    }
    
    // Wait for async completion (timeout 10 seconds)
    let timeout = DispatchTime.now() + .seconds(10)
    let result = semaphore.wait(timeout: timeout)
    
    if result == .timedOut {
        print("Warning: getAudiencesWithCompletionHandler timed out")
    }
}

// Test 7: Log Timed Event
// Based on ViewController.m logTimedEvent method
// Tests logging timed events - begins a timed event, waits a fixed duration, then ends it
func testLogTimedEvent(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    // Begin a timed event
    let eventName = "Timed Event"
    let timedEvent = MPEvent(name: eventName, type: .transaction)
    
    if let event = timedEvent {
        mparticle.beginTimedEvent(event)
        
        // Use fixed delay instead of random (required for deterministic testing)
        // Original code uses arc4random_uniform(4000.0) / 1000.0 + 1.0 which is 1-5 seconds
        // We use fixed 2 seconds for consistent test behavior
        sleep(2)
        
        // Retrieve the timed event by name and end it
        if let retrievedTimedEvent = mparticle.event(withName: eventName) {
            mparticle.endTimedEvent(retrievedTimedEvent)
        }
    }
    
    uploadWaiter.wait()
}

// Test 8: Log Error
// Based on ViewController.m logError method
// Tests logging errors with custom event info dictionary
func testLogError(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    // Log an error with event info - exactly as in ViewController.m
    let eventInfo = ["cause": "slippery floor"]
    mparticle.logError("Oops", eventInfo: eventInfo)
    
    uploadWaiter.wait()
}

// Test 9: Log Exception
// Based on ViewController.m logException method
// Tests logging NSException with topmost context information
func testLogException(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    // Create an NSException similar to the one caught in ViewController.m
    // The original code tries to invoke a non-existing method which throws NSException
    let exception = NSException(
        name: NSExceptionName(rawValue: "NSInvalidArgumentException"),
        reason: "-[ViewController someMethodThatDoesNotExist]: unrecognized selector sent to instance",
        userInfo: nil
    )
    
    // Log the exception - mParticle SDK will capture exception details
    // Note: topmostContext parameter is not available in Swift API, 
    // so we use the simpler logException method
    mparticle.logException(exception)
    
    uploadWaiter.wait()
}

// Test 10: Set User Attributes
// Based on ViewController.m setUserAttribute method
// Tests setting predefined and custom user attributes on the current user
func testSetUserAttributes(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    guard let currentUser = mparticle.identity.currentUser else {
        print("No current user available")
        return
    }
    
    // Set 'Age' as a user attribute using predefined mParticle constant
    // Using static value instead of random for deterministic testing
    let age = "45" // Original: 21 + arc4random_uniform(80)
    currentUser.setUserAttribute(mParticleUserAttributeAge, value: age)
    
    // Set 'Gender' as a user attribute using predefined mParticle constant
    // Using static value instead of random for deterministic testing
    let gender = "m" // Original: arc4random_uniform(2) ? "m" : "f"
    currentUser.setUserAttribute(mParticleUserAttributeGender, value: gender)
    
    // Set a numeric user attribute using a custom key
    currentUser.setUserAttribute("Achieved Level", value: 4)
    
    uploadWaiter.wait()
}

// Test 11: Increment User Attribute
// Based on ViewController.m incrementUserAttribute method
// Tests incrementing a numeric user attribute by a specified value
func testIncrementUserAttribute(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    guard let currentUser = mparticle.identity.currentUser else {
        print("No current user available")
        return
    }
    
    // First, set an initial value for the attribute to ensure it exists
    // Using static value 10 for deterministic testing
    currentUser.setUserAttribute("Achieved Level", value: 10)
    
    // Wait for the initial set to be uploaded
    uploadWaiter.wait()
    
    // Now increment the attribute by 1 - exactly as in ViewController.m
    currentUser.incrementUserAttribute("Achieved Level", byValue: NSNumber(value: 1))
    
    // Wait for the increment to be uploaded
    uploadWaiter.wait()
}

// Test 12: Set Session Attribute
// Based on ViewController.m setSessionAttribute method
// Tests setting a session attribute - session attributes are sent when session ends
func testSetSessionAttribute(mparticle: MParticle, uploadWaiter: EventUploadWaiter) {
    // Set a session attribute - this will be included in the session end message
    mparticle.setSessionAttribute("Station", value: "Classic Rock")
    
    // End the session to trigger sending the session attribute
    // Session attributes are sent in the session end message (dt: "se")
    mparticle.endSession()
    
    uploadWaiter.wait()
}

// Read API key and secret from environment variables, or use fake keys for verification mode
// Fake keys must match the pattern us1-[a-f0-9]+ to work with WireMock mappings
let apiKey = ProcessInfo.processInfo.environment["MPARTICLE_API_KEY"] ?? "us1-00000000000000000000000000000000"
let apiSecret = ProcessInfo.processInfo.environment["MPARTICLE_API_SECRET"] ?? "fake-secret-for-integration-tests"

if ProcessInfo.processInfo.environment["MPARTICLE_API_KEY"] == nil {
    print("⚠️  MPARTICLE_API_KEY not set, using fake key for verification mode")
}

var options = MParticleOptions(
    key: apiKey,
    secret: apiSecret
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
let uploadWaiter = EventUploadWaiter()
MPListenerController.sharedInstance().addSdkListener(uploadWaiter)

let mparticle = MParticle.sharedInstance()
mparticle.start(with: options)

sleep(1)

// Run tests
testSimpleEvent(mparticle: mparticle, uploadWaiter: uploadWaiter)
testEventWithCustomAttributesAndFlags(mparticle: mparticle, uploadWaiter: uploadWaiter)
testLogScreen(mparticle: mparticle, uploadWaiter: uploadWaiter)
testCommerceEvent(mparticle: mparticle, uploadWaiter: uploadWaiter)
testRoktSelectPlacement(mparticle: mparticle, uploadWaiter: uploadWaiter)
testGetUserAudiences(mparticle: mparticle)
testLogTimedEvent(mparticle: mparticle, uploadWaiter: uploadWaiter)
testLogError(mparticle: mparticle, uploadWaiter: uploadWaiter)
testLogException(mparticle: mparticle, uploadWaiter: uploadWaiter)
testSetUserAttributes(mparticle: mparticle, uploadWaiter: uploadWaiter)
testIncrementUserAttribute(mparticle: mparticle, uploadWaiter: uploadWaiter)
testSetSessionAttribute(mparticle: mparticle, uploadWaiter: uploadWaiter)