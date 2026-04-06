// trunk-ignore-all(mparticle-api-key-check): To be removed and set via
// env vars in the integration tests CI job
import Foundation
import mParticle_Apple_SDK

func wait(timeout: UInt32 = 5) {
    mparticle.upload()
    sleep(timeout)
}

// Test 1: Simple Event
func testSimpleEvent(mparticle: MParticle) {
    mparticle.logEvent("Simple Event Name", eventType: .other, eventInfo: ["SimpleKey": "SimpleValue"])
    wait()
}

// Test 2: Log Event with Custom Attributes and Custom Flags
// Based on ViewController.m logEvent method
func testEventWithCustomAttributesAndFlags(mparticle: MParticle) {
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
    wait()
}

// Test 3: Log Screen
// Based on ViewController.m logScreen method
func testLogScreen(mparticle: MParticle) {
    mparticle.logScreen("Home Screen", eventInfo: nil)
    wait()
}

// Test 4: Log Commerce Event with Product and Transaction
// Based on ViewController.m logCommerceEvent method
func testCommerceEvent(mparticle: MParticle) {
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
    wait()
}

// Test 5: Rokt Select Overlay Placement
// Based on ViewController.m selectOverlayPlacement method
// Tests Rokt SDK integration through mParticle for selecting placements with custom attributes
func testRoktSelectPlacement(mparticle: MParticle) {
    let roktAttributes: [String: String] = [
        "email": "j.smit@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]

    // Select Rokt placement with identifier and attributes
    mparticle.rokt.selectPlacements("RoktLayout", attributes: roktAttributes)
    wait()
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
func testLogTimedEvent(mparticle: MParticle) {
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

    wait()
}

// Test 8: Log Error
// Based on ViewController.m logError method
// Tests logging errors with custom event info dictionary
func testLogError(mparticle: MParticle) {
    // Log an error with event info - exactly as in ViewController.m
    let eventInfo = ["cause": "slippery floor"]
    mparticle.logError("Oops", eventInfo: eventInfo)

    wait()
}

// Test 9: Log Exception
// Based on ViewController.m logException method
// Tests logging NSException with topmost context information
func testLogException(mparticle: MParticle) {
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

    wait()
}

// Test 10: Set User Attributes
// Based on ViewController.m setUserAttribute method
// Tests setting predefined and custom user attributes on the current user
func testSetUserAttributes(mparticle: MParticle) {
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

    wait()
}

// Test 11: Increment User Attribute
// Based on ViewController.m incrementUserAttribute method
// Tests incrementing a numeric user attribute by a specified value
func testIncrementUserAttribute(mparticle: MParticle) {
    guard let currentUser = mparticle.identity.currentUser else {
        print("No current user available")
        return
    }

    // First, set an initial value for the attribute to ensure it exists
    // Using static value 10 for deterministic testing
    currentUser.setUserAttribute("Achieved Level", value: 10)

    // Wait for the initial set to be uploaded
    wait()

    // Now increment the attribute by 1 - exactly as in ViewController.m
    currentUser.incrementUserAttribute("Achieved Level", byValue: NSNumber(value: 1))

    // Wait for the increment to be uploaded
    wait()
}

// Test 12: Set Session Attribute
// Based on ViewController.m setSessionAttribute method
// Tests setting a session attribute - session attributes are sent when session ends
func testSetSessionAttribute(mparticle: MParticle) {
    // Set a session attribute - this will be included in the session end message
    mparticle.setSessionAttribute("Station", value: "Classic Rock")

    // End the session to trigger sending the session attribute
    // Session attributes are sent in the session end message (dt: "se")
    mparticle.endSession()

    wait()
}

// Test 13: Increment Session Attribute
// Based on ViewController.m incrementSessionAttribute method (lines 348-351)
// Tests incrementing a numeric session attribute - session attributes are sent when session ends
func testIncrementSessionAttribute(mparticle: MParticle) {
    // Start a new session since the previous test ended the session
    mparticle.beginSession()

    // Wait for session start to be uploaded (ensures separate request from session end)
    wait()

    // First set an initial numeric value for the session attribute
    mparticle.setSessionAttribute("Song Count", value: 5)

    // Increment the session attribute by 1 - exactly as in ViewController.m
    mparticle.incrementSessionAttribute("Song Count", byValue: 1)

    // End the session to trigger sending the session attribute
    // Session attributes are sent in the session end message (dt: "se")
    mparticle.endSession()

    wait()
}

// Test 14: Toggle CCPA Consent
// Based on ViewController.m toggleCCPAConsent method (lines 357-386)
// Tests setting CCPA consent state on the current user and verifying it's transmitted
func testToggleCCPAConsent(mparticle: MParticle) {
    guard let currentUser = mparticle.identity.currentUser else {
        print("No current user available")
        return
    }

    // Use static timestamp for deterministic testing
    let staticTimestamp = Date(timeIntervalSince1970: 1700000000) // Fixed timestamp: 2023-11-14 22:13:20 UTC

    // Create CCPA consent with consented = YES
    let ccpaConsent = MPCCPAConsent()
    ccpaConsent.consented = true
    ccpaConsent.document = "ccpa_consent_agreement_v3"
    ccpaConsent.timestamp = staticTimestamp
    ccpaConsent.location = "17 Cherry Tree Lane"
    ccpaConsent.hardwareId = "IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"

    // Create new consent state and set CCPA consent
    let newConsentState = MPConsentState()
    newConsentState.setCCPA(ccpaConsent)

    // Preserve existing GDPR consent state if any
    if let existingGDPR = currentUser.consentState()?.gdprConsentState() {
        newConsentState.setGDPR(existingGDPR)
    }

    // Set consent state on current user
    currentUser.setConsentState(newConsentState)

    // Log an event to trigger upload that includes the CCPA consent state
    // The consent state is included in the request body ("con" field) with event uploads
    mparticle.logEvent("CCPA Consent Updated", eventType: .other, eventInfo: ["consent_status": "opted_in"])

    wait()
}

// Test 15: Toggle GDPR Consent
// Based on ViewController.m toggleGDPRConsent method (lines 388-416)
// Tests setting GDPR consent state on the current user and verifying it's transmitted
func testToggleGDPRConsent(mparticle: MParticle) {
    guard let currentUser = mparticle.identity.currentUser else {
        print("No current user available")
        return
    }

    // Use static timestamp for deterministic testing
    let staticTimestamp = Date(timeIntervalSince1970: 1700000000) // Fixed timestamp: 2023-11-14 22:13:20 UTC

    // Create GDPR consent with consented = YES (testing the "else" branch from ViewController.m)
    let gdprConsent = MPGDPRConsent()
    gdprConsent.consented = true
    gdprConsent.document = "location_collection_agreement_v4"
    gdprConsent.timestamp = staticTimestamp
    gdprConsent.location = "17 Cherry Tree Lane"
    gdprConsent.hardwareId = "IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"

    // Create new consent state and add GDPR consent with purpose
    let newConsentState = MPConsentState()
    newConsentState.addGDPRConsentState(gdprConsent, purpose: "My GDPR Purpose")

    // Preserve existing CCPA consent state if any
    if let existingCCPA = currentUser.consentState()?.ccpaConsentState() {
        newConsentState.setCCPA(existingCCPA)
    }

    // Set consent state on current user
    currentUser.setConsentState(newConsentState)

    // Log an event to trigger upload that includes the GDPR consent state
    // The consent state is included in the request body ("con" field) with event uploads
    mparticle.logEvent("GDPR Consent Updated", eventType: .other, eventInfo: ["consent_status": "opted_in"])

    wait()
}

// Test 16: Log IDFA (iOS Advertiser ID)
// Based on ViewController.m logIDFA method (lines 418-429)
// Tests modifying user identity to add/update the iOS Advertiser ID via Identity API
func testLogIDFA(mparticle: MParticle) {
    // Get current user from identity API
    guard let currentUser = mparticle.identity.currentUser else {
        print("No current user available")
        return
    }

    // Create identity request with current user
    let identityRequest = MPIdentityApiRequest(user: currentUser)

    // Use static IDFA for deterministic testing
    // Format: UUID-style string typical for iOS Advertiser IDs
    let staticIDFA = "A5D934N0-232F-4AFC-2E9A-3832D95ZC702"

    // Set the iOS Advertiser ID identity
    identityRequest.setIdentity(staticIDFA, identityType: MPIdentity.iosAdvertiserId)

    // Modify the user identity
    mparticle.identity.modify(identityRequest) { _, _ in }

    wait()
}

// Test 17: Set ATT Status (App Tracking Transparency)
// Based on ViewController.m requestIDFA method (lines 431-476)
// Tests setting the ATT authorization status which is sent with device info on uploads
func testSetATTStatus(mparticle: MParticle) {
    // Use static timestamp in milliseconds for deterministic testing
    let staticTimestampMillis = NSNumber(value: 1700000000000) // Fixed timestamp: 2023-11-14 22:13:20 UTC in milliseconds

    // Set ATT status to Authorized (simulating user granting tracking permission)
    // This corresponds to the ATTrackingManagerAuthorizationStatusAuthorized case in ViewController.m
    mparticle.setATTStatus(MPATTAuthorizationStatus.authorized, withATTStatusTimestampMillis: staticTimestampMillis)

    // Log an event to trigger upload that includes the ATT status in device info
    // ATT status is sent in the "att" field within device_info ("di") section
    mparticle.logEvent("ATT Status Updated", eventType: .other, eventInfo: ["att_status": "authorized"])

    wait()
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

options.onIdentifyComplete = { apiResult, _ in
    if let apiResult {
        apiResult.user.setUserAttribute("example attribute key", value: "example attribute value")
    }
}
options.logLevel = .verbose

var networkOptions = MPNetworkOptions()
networkOptions.configHost = "127.0.0.1" // config2.mparticle.com
networkOptions.eventsHost = "127.0.0.1" // nativesdks.mparticle.com
networkOptions.identityHost = "127.0.0.1" // identity.mparticle.com
networkOptions.pinningDisabled = true

options.networkOptions = networkOptions

let mparticle = MParticle.sharedInstance()
mparticle.start(with: options)

sleep(1)

// Run tests
testSimpleEvent(mparticle: mparticle)
testEventWithCustomAttributesAndFlags(mparticle: mparticle)
testLogScreen(mparticle: mparticle)
testCommerceEvent(mparticle: mparticle)
testRoktSelectPlacement(mparticle: mparticle)
testGetUserAudiences(mparticle: mparticle)
testLogTimedEvent(mparticle: mparticle)
testLogError(mparticle: mparticle)
testLogException(mparticle: mparticle)
testSetUserAttributes(mparticle: mparticle)
testIncrementUserAttribute(mparticle: mparticle)
testSetSessionAttribute(mparticle: mparticle)
testIncrementSessionAttribute(mparticle: mparticle)
testToggleCCPAConsent(mparticle: mparticle)
testToggleGDPRConsent(mparticle: mparticle)
testLogIDFA(mparticle: mparticle)
testSetATTStatus(mparticle: mparticle)
