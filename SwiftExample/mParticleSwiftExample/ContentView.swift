// swiftlint:disable file_length
import SwiftUI
import mParticle_Apple_SDK
import AdSupport
import AppTrackingTransparency

struct ContentView: View {
    @State private var email: String = ""
    @State private var customerId: String = ""
    @State private var roktViewHeight: CGFloat = 0

    private let actions: [(title: String, action: () -> Void)] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input fields
                VStack(spacing: 8) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)

                    TextField("Customer ID", text: $customerId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                }
                .padding()

                // Rokt embedded view placeholder
                if roktViewHeight > 0 {
                    RoktEmbeddedViewWrapper(height: $roktViewHeight)
                        .frame(height: roktViewHeight)
                }

                // Actions list
                List {
                    Section(header: Text("Events")) {
                        ActionButton(title: "Log Simple Event", action: logSimpleEvent)
                        ActionButton(title: "Log Event", action: logEvent)
                        ActionButton(title: "Log Screen", action: logScreen)
                        ActionButton(title: "Log Commerce Event", action: logCommerceEvent)
                        ActionButton(title: "Log Timed Event", action: logTimedEvent)
                        ActionButton(title: "Log Error", action: logError)
                        ActionButton(title: "Log Exception", action: logException)
                    }

                    Section(header: Text("User Attributes")) {
                        ActionButton(title: "Set User Attribute", action: setUserAttribute)
                        ActionButton(title: "Increment User Attribute", action: incrementUserAttribute)
                    }

                    Section(header: Text("Session Attributes")) {
                        ActionButton(title: "Set Session Attribute", action: setSessionAttribute)
                        ActionButton(title: "Increment Session Attribute", action: incrementSessionAttribute)
                    }

                    Section(header: Text("Identity")) {
                        ActionButton(title: "Login") { login(email: email, customerId: customerId) }
                        ActionButton(title: "Logout", action: logout)
                        ActionButton(title: "Set IDFA", action: modifyIDFA)
                        ActionButton(title: "Request & Set IDFA", action: requestIDFA)
                    }

                    Section(header: Text("Consent")) {
                        ActionButton(title: "Toggle CCPA Consent", action: toggleCCPAConsent)
                        ActionButton(title: "Toggle GDPR Consent", action: toggleGDPRConsent)
                    }

                    Section(header: Text("Other")) {
                        ActionButton(title: "Register Remote", action: registerRemote)
                        ActionButton(title: "Get Audience", action: getAudience)
                        ActionButton(title: "Decrease Upload Timer", action: decreaseUploadInterval)
                        ActionButton(title: "Increase Upload Timer", action: increaseUploadInterval)
                    }

                    Section(header: Text("Rokt")) {
                        ActionButton(title: "Display Rokt Overlay Placement", action: selectOverlayPlacement)
                        ActionButton(title: "Display Rokt Dark Mode Overlay", action: selectDarkOverlayPlacement)
                        ActionButton(title: "Display Rokt Embedded Placement") {
                            selectEmbeddedPlacement(heightBinding: $roktViewHeight) }
                        ActionButton(
                            title: "Display Rokt Overlay (auto close)",
                            action: selectOverlayPlacementAutoClose
                        )
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("mParticle Swift Example")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.primary)
        }
    }
}

struct RoktEmbeddedViewWrapper: UIViewRepresentable {
    @Binding var height: CGFloat

    func makeUIView(context: Context) -> MPRoktEmbeddedView {
        return MPRoktEmbeddedView()
    }

    func updateUIView(_ uiView: MPRoktEmbeddedView, context: Context) {
        // Update the view if needed
    }
}

// MARK: - mParticle Actions

func logSimpleEvent() {
    MParticle.sharedInstance().logEvent(
        "Simple Event Name",
        eventType: .other,
        eventInfo: ["SimpleKey": "SimpleValue"]
    )
}

func logEvent() {
    let event = MPEvent(name: "Event Name", type: .transaction)

    let currentDate = Date()
    event?.customAttributes = [
        "A_String_Key": "A String Value",
        "A Number Key": 42,
        "A Date Key": Date(),
        "test Dictionary": ["test1": "test", "test2": 2, "test3": currentDate]
    ]

    event?.addCustomFlag("Top Secret", withKey: "Not_forwarded_to_providers")

    if let event = event {
        MParticle.sharedInstance().logEvent(event)
    }
}

func logScreen() {
    MParticle.sharedInstance().logScreen("Home Screen", eventInfo: nil)
}

func logCommerceEvent() {
    let product = MPProduct(name: "Awesome Book", sku: "1234567890", quantity: 1, price: 9.99)
    product.brand = "A Publisher"
    product.category = "Fiction"
    product.couponCode = "XYZ123"
    product.position = 1
    product["custom key"] = "custom value"

    let commerceEvent = MPCommerceEvent(action: .purchase, product: product)
    commerceEvent.checkoutOptions = "Credit Card"
    commerceEvent.screenName = "Timeless Books"
    commerceEvent.checkoutStep = 4
    commerceEvent.customAttributes = ["an_extra_key": "an_extra_value"]

    let transactionAttributes = MPTransactionAttributes()
    transactionAttributes.affiliation = "Book seller"
    transactionAttributes.shipping = 1.23
    transactionAttributes.tax = 0.87
    transactionAttributes.revenue = 12.09
    transactionAttributes.transactionId = "zyx098"
    commerceEvent.transactionAttributes = transactionAttributes

    MParticle.sharedInstance().logEvent(commerceEvent)
}

func logTimedEvent() {
    let mParticle = MParticle.sharedInstance()
    let eventName = "Timed Event"

    if let timedEvent = MPEvent(name: eventName, type: .transaction) {
        mParticle.beginTimedEvent(timedEvent)

        let delay = Double.random(in: 1.0...5.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if let retrievedEvent = mParticle.event(withName: eventName) {
                mParticle.endTimedEvent(retrievedEvent)
            }
        }
    }
}

func logError() {
    let eventInfo = ["cause": "slippery floor"]
    MParticle.sharedInstance().logError("Oops", eventInfo: eventInfo)
}

func logException() {
    let exception = NSException(
        name: NSExceptionName("TestException"),
        reason: "Testing exception logging",
        userInfo: nil
    )
    MParticle.sharedInstance().logException(exception)
}

func setUserAttribute() {
    let mParticle = MParticle.sharedInstance()

    let age = String(Int.random(in: 21...100))
    mParticle.identity.currentUser?.setUserAttribute(mParticleUserAttributeAge, value: age)

    let gender = Bool.random() ? "m" : "f"
    mParticle.identity.currentUser?.setUserAttribute(mParticleUserAttributeGender, value: gender)

    mParticle.identity.currentUser?.setUserAttribute("Achieved Level", value: 4)
}

func incrementUserAttribute() {
    MParticle.sharedInstance().identity.currentUser?.incrementUserAttribute("Achieved Level", byValue: 1)
}

func setSessionAttribute() {
    let mParticle = MParticle.sharedInstance()
    mParticle.setSessionAttribute("Station", value: "Classic Rock")
    mParticle.setSessionAttribute("Song Count", value: 1)
}

func incrementSessionAttribute() {
    MParticle.sharedInstance().incrementSessionAttribute("Song Count", byValue: 1)
}

func registerRemote() {
    UIApplication.shared.registerForRemoteNotifications()
}

func getAudience() {
    let mParticle = MParticle.sharedInstance()

    mParticle.identity.currentUser?.getAudiencesWithCompletionHandler({ audiences, error in
        if let error = error {
            print("Failed to retrieve Audience: \(error)")
        } else {
            let userId = mParticle.identity.currentUser?.userId ?? 0
            print("Successfully retrieved Audience for user: \(userId) with audiences: \(audiences)")
        }
    })
}

func toggleCCPAConsent() {
    guard let currentUser = MParticle.sharedInstance().identity.currentUser else { return }

    let currentConsent = currentUser.consentState()?.ccpaConsentState()?.consented ?? false

    let ccpaConsent = MPCCPAConsent()
    ccpaConsent.consented = !currentConsent
    ccpaConsent.document = "ccpa_consent_agreement_v3"
    ccpaConsent.timestamp = Date()
    ccpaConsent.location = "17 Cherry Tree Lane"
    ccpaConsent.hardwareId = "IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"

    let newConsentState = MPConsentState()
    newConsentState.setCCPA(ccpaConsent)
    if let gdprState = currentUser.consentState()?.gdprConsentState() {
        newConsentState.setGDPR(gdprState)
    }

    currentUser.setConsentState(newConsentState)
}

func toggleGDPRConsent() {
    guard let currentUser = MParticle.sharedInstance().identity.currentUser else { return }

    let currentConsent = currentUser.consentState()?.gdprConsentState()?["my gdpr purpose"]?.consented ?? false

    let gdprConsent = MPGDPRConsent()
    gdprConsent.consented = !currentConsent
    gdprConsent.document = "location_collection_agreement_v4"
    gdprConsent.timestamp = Date()
    gdprConsent.location = "17 Cherry Tree Lane"
    gdprConsent.hardwareId = "IDFA:a5d934n0-232f-4afc-2e9a-3832d95zc702"

    let newConsentState = MPConsentState()
    newConsentState.addGDPRConsentState(gdprConsent, purpose: "My GDPR Purpose")
    if let ccpaState = currentUser.consentState()?.ccpaConsentState() {
        newConsentState.setCCPA(ccpaState)
    }

    currentUser.setConsentState(newConsentState)
}

func requestIDFA() {
    if #available(iOS 14, *) {
        ATTrackingManager.requestTrackingAuthorization { status in
            switch status {
            case .authorized:
                print("Authorized")
                MParticle.sharedInstance().setATTStatus(.authorized, withATTStatusTimestampMillis: nil)
                logIDFA(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
            case .denied:
                print("Denied")
                MParticle.sharedInstance().setATTStatus(.denied, withATTStatusTimestampMillis: nil)
            case .notDetermined:
                print("Not Determined")
                MParticle.sharedInstance().setATTStatus(.notDetermined, withATTStatusTimestampMillis: nil)
            case .restricted:
                print("Restricted")
                MParticle.sharedInstance().setATTStatus(.restricted, withATTStatusTimestampMillis: nil)
            @unknown default:
                break
            }
        }
    } else {
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            logIDFA(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
        }
    }
}

func logIDFA(_ advertiserId: String) {
    guard let currentUser = MParticle.sharedInstance().identity.currentUser else { return }

    let identityRequest = MPIdentityApiRequest(user: currentUser)
    identityRequest.setIdentity(advertiserId, identityType: .iosAdvertiserId)

    MParticle.sharedInstance().identity.modify(identityRequest) { result, error in
        if let error = error {
            print("Failed to update IDFA: \(error)")
        } else {
            print("Update IDFA: \(result?.identityChanges ?? [])")
        }
    }
}

func modifyIDFA() {
    logIDFA("C56A4180-65AA-42EC-A945-5FD21DEC0538")
}

func logout() {
    let identityRequest = MPIdentityApiRequest.withEmptyUser()

    MParticle.sharedInstance().identity.logout(identityRequest) { _, error in
        if let error = error {
            print("Failed to logout: \(error)")
        } else {
            print("Logout Successful")
        }
    }
}

func login(email: String, customerId: String) {
    let identityRequest = MPIdentityApiRequest.withEmptyUser()

    if !email.isEmpty {
        identityRequest.email = email
    }
    if !customerId.isEmpty {
        identityRequest.customerId = customerId
    }

    MParticle.sharedInstance().identity.login(identityRequest) { _, error in
        if let error = error {
            print("Failed to login: \(error)")
        } else {
            print("Login Successful")
        }
    }
}

func decreaseUploadInterval() {
    MParticle.sharedInstance().uploadInterval = 1.0
}

func increaseUploadInterval() {
    MParticle.sharedInstance().uploadInterval = 1200.0
}

// MARK: - Rokt Actions

func selectOverlayPlacement() {
    let customAttributes: [String: String] = [
        "email": "j.smit@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]

    MParticle.sharedInstance().rokt.selectPlacements("RoktLayout", attributes: customAttributes)
}

func selectDarkOverlayPlacement() {
    let customAttributes: [String: String] = [
        "email": "j.smit@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]

    let roktConfig = MPRoktConfig()
    roktConfig.colorMode = .dark

    MParticle.sharedInstance().rokt.selectPlacements(
        "RoktLayout",
        attributes: customAttributes,
        embeddedViews: nil,
        config: roktConfig,
        callbacks: nil
    )
}

func selectEmbeddedPlacement(heightBinding: Binding<CGFloat>) {
    let customAttributes: [String: String] = [
        "email": "j.smit@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]

    let callbacks = MPRoktEventCallback()
    callbacks.onLoad = {
        // Optional callback for when the Rokt placement loads
    }
    callbacks.onUnLoad = {
        // Optional callback for when the Rokt placement unloads
    }
    callbacks.onShouldShowLoadingIndicator = {
        // Optional callback to show a loading indicator
    }
    callbacks.onShouldHideLoadingIndicator = {
        // Optional callback to hide a loading indicator
    }
    callbacks.onEmbeddedSizeChange = { _, size in
        DispatchQueue.main.async {
            heightBinding.wrappedValue = size
        }
    }

    let roktView = MPRoktEmbeddedView()
    let embeddedViews: [String: MPRoktEmbeddedView] = ["Location1": roktView]

    MParticle.sharedInstance().rokt.selectPlacements(
        "testiOS",
        attributes: customAttributes,
        embeddedViews: embeddedViews,
        config: nil,
        callbacks: callbacks
    )
}

func selectOverlayPlacementAutoClose() {
    selectOverlayPlacement()

    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        MParticle.sharedInstance().rokt.close()
    }
}

#Preview {
    ContentView()
}
