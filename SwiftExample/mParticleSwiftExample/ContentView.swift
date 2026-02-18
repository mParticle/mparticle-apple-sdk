// swiftlint:disable file_length
import SwiftUI
import mParticle_Apple_SDK
import mParticle_Rokt_Swift
import Rokt_Widget
import AdSupport
import AppTrackingTransparency

struct ContentView: View {
    @State private var email: String = ""
    @State private var customerId: String = ""
    @State private var roktViewHeight: CGFloat = 0
    @State private var showingUserInfo: Bool = false
    @State private var showingKitStatus: Bool = false

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
                        ActionButton(title: "Set User Attribute List", action: setUserAttributeList)
                        ActionButton(title: "Remove User Attribute", action: removeUserAttribute)
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

                    Section(header: Text("Debug & Info")) {
                        ActionButton(title: "Display Current User") {
                            showingUserInfo = true
                        }
                        ActionButton(title: "Force Upload", action: forceUpload)
                        ActionButton(title: "Check Kit Status") {
                            showingKitStatus = true
                        }
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
                        ActionButton(
                            title: "Display Rokt with Event Subscription",
                            action: selectPlacementWithEventSubscription
                        )
                        NavigationLink("MPRoktLayout SwiftUI Example") {
                            RoktLayoutExampleView()
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("mParticle Swift Example")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingUserInfo) {
                UserInfoSheet()
            }
            .sheet(isPresented: $showingKitStatus) {
                KitStatusSheet()
            }
        }
    }
}

struct UserInfoSheet: View {
    @State private var infoText: String = "Loading..."
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(infoText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Current User Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        infoText = getCurrentUserInfo()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                // Small delay to ensure SDK data is loaded
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    infoText = getCurrentUserInfo()
                }
            }
        }
    }
}

struct KitStatusSheet: View {
    @State private var statusText: String = "Loading..."
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(statusText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Kit Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Refresh") {
                        statusText = getKitStatus()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    statusText = getKitStatus()
                }
            }
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

// MARK: - MPRoktLayout SwiftUI Example

struct RoktLayoutExampleView: View {
    @State private var sdkTriggered = false
    @State private var eventLog: [String] = []

    let attributes: [String: String] = [
        "email": "j.smith@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "billingzipcode": "07762",
        "confirmationref": "54321",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("MPRoktLayout Example")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)

                Text("This demonstrates the SwiftUI-native MPRoktLayout component for embedding Rokt placements declaratively.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                // Trigger button
                Button {
                    sdkTriggered = true
                    eventLog.append("[\(formattedTime())] Triggered placement")
                } label: {
                    Text(sdkTriggered ? "Placement Triggered" : "Trigger Rokt Placement")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(sdkTriggered ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(sdkTriggered)
                .padding(.horizontal)

                // Reset button
                if sdkTriggered {
                    Button {
                        sdkTriggered = false
                        eventLog.append("[\(formattedTime())] Reset placement")
                    } label: {
                        Text("Reset")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }

                // Rokt Layout - Embedded Placement
                if sdkTriggered {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Embedded Placement")
                            .font(.headline)
                            .padding(.horizontal)

                        MPRoktLayout(
                            sdkTriggered: $sdkTriggered,
                            viewName: "RoktExperience",
                            locationName: "RoktEmbedded1",
                            attributes: attributes,
                            config: createRoktConfig(),
                            onEvent: { roktEvent in
                                handleRoktEvent(roktEvent)
                            }
                        ).roktLayout
                            .frame(minHeight: 100)
                            .padding(.horizontal)
                    }
                }

                // Event Log
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Log")
                        .font(.headline)
                        .padding(.horizontal)

                    if eventLog.isEmpty {
                        Text("No events yet. Trigger the placement to see events.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(eventLog.reversed(), id: \.self) { event in
                            Text(event)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("MPRoktLayout")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func createRoktConfig() -> RoktConfig {
        return RoktConfig.Builder().build()
    }

    private func handleRoktEvent(_ event: RoktEvent) {
        let timestamp = formattedTime()

        switch event {
        case is RoktEvent.ShowLoadingIndicator:
            eventLog.append("[\(timestamp)] Show Loading Indicator")

        case is RoktEvent.HideLoadingIndicator:
            eventLog.append("[\(timestamp)] Hide Loading Indicator")

        case let placementReady as RoktEvent.PlacementReady:
            eventLog.append("[\(timestamp)] Placement Ready - ID: \(placementReady.placementId ?? "unknown")")

        case let placementInteractive as RoktEvent.PlacementInteractive:
            eventLog.append("[\(timestamp)] Placement Interactive - ID: \(placementInteractive.placementId ?? "unknown")")

        case let offerEngagement as RoktEvent.OfferEngagement:
            eventLog.append("[\(timestamp)] Offer Engagement - ID: \(offerEngagement.placementId ?? "unknown")")

        case let positiveEngagement as RoktEvent.PositiveEngagement:
            eventLog.append("[\(timestamp)] Positive Engagement - ID: \(positiveEngagement.placementId ?? "unknown")")

        case let firstPositiveEngagement as RoktEvent.FirstPositiveEngagement:
            eventLog.append("[\(timestamp)] First Positive Engagement - ID: \(firstPositiveEngagement.placementId ?? "unknown")")

        case let openUrl as RoktEvent.OpenUrl:
            eventLog.append("[\(timestamp)] Open URL - \(openUrl.url)")

        case let placementClosed as RoktEvent.PlacementClosed:
            eventLog.append("[\(timestamp)] Placement Closed - ID: \(placementClosed.placementId ?? "unknown")")

        case let placementCompleted as RoktEvent.PlacementCompleted:
            eventLog.append("[\(timestamp)] Placement Completed - ID: \(placementCompleted.placementId ?? "unknown")")

        case let placementFailure as RoktEvent.PlacementFailure:
            eventLog.append("[\(timestamp)] Placement Failure - ID: \(placementFailure.placementId ?? "unknown")")

        case let cartItem as RoktEvent.CartItemInstantPurchase:
            eventLog.append("[\(timestamp)] Cart Item Purchase - \(cartItem.name ?? "unknown")")

        default:
            eventLog.append("[\(timestamp)] Event: \(type(of: event))")
        }
    }

    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
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

func setUserAttributeList() {
    let mParticle = MParticle.sharedInstance()

    // Set a user attribute with an array/list value
    let favoriteColors = ["Blue", "Green", "Red"]
    mParticle.identity.currentUser?.setUserAttributeList("Favorite Colors", values: favoriteColors)

    // Set another list attribute
    let interests = ["Gaming", "Music", "Travel", "Technology"]
    mParticle.identity.currentUser?.setUserAttributeList("Interests", values: interests)

    print("Set user attribute lists: Favorite Colors and Interests")
}

func removeUserAttribute() {
    let mParticle = MParticle.sharedInstance()

    // Remove a specific user attribute
    mParticle.identity.currentUser?.removeAttribute("Achieved Level")

    print("Removed user attribute: Achieved Level")
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

// MARK: - Debug & Info Actions

func getCurrentUserInfo() -> String {
    let mParticle = MParticle.sharedInstance()
    guard let currentUser = mParticle.identity.currentUser else {
        return "No current user found"
    }

    var info = "=== CURRENT USER INFO ===\n\n"

    // MPID
    info += "MPID: \(currentUser.userId)\n\n"

    // Device Application Stamp
    info += "Device App Stamp: \(mParticle.identity.deviceApplicationStamp)\n\n"

    // User Identities
    info += "--- IDENTITIES ---\n"
    if currentUser.identities.isEmpty {
        info += "(none)\n"
    } else {
        for (typeNum, value) in currentUser.identities {
            let typeName = identityTypeName(for: MPIdentity(rawValue: typeNum.uintValue) ?? .other)
            info += "\(typeName): \(value)\n"
        }
    }

    info += "\n"

    // User Attributes
    info += "--- USER ATTRIBUTES ---\n"
    if currentUser.userAttributes.isEmpty {
        info += "(none)\n"
    } else {
        for (key, value) in currentUser.userAttributes.sorted(by: { $0.key < $1.key }) {
            if let arrayValue = value as? [Any] {
                info += "\(key): \(arrayValue)\n"
            } else {
                info += "\(key): \(value)\n"
            }
        }
    }
    info += "\n"

    // Consent State
    info += "--- CONSENT STATE ---\n"
    if let consentState = currentUser.consentState() {
        if let ccpa = consentState.ccpaConsentState() {
            info += "CCPA Consented: \(ccpa.consented)\n"
        } else {
            info += "CCPA: (not set)\n"
        }

        if let gdpr = consentState.gdprConsentState(), !gdpr.isEmpty {
            for (purpose, consent) in gdpr {
                info += "GDPR [\(purpose)]: \(consent.consented)\n"
            }
        } else {
            info += "GDPR: (not set)\n"
        }
    } else {
        info += "(no consent state)\n"
    }

    return info
}

func identityTypeName(for type: MPIdentity) -> String {
    switch type {
    case .other: return "Other"
    case .customerId: return "Customer ID"
    case .facebook: return "Facebook"
    case .twitter: return "Twitter"
    case .google: return "Google"
    case .microsoft: return "Microsoft"
    case .yahoo: return "Yahoo"
    case .email: return "Email"
    case .alias: return "Alias"
    case .facebookCustomAudienceId: return "Facebook Custom Audience ID"
    case .other2: return "Other 2"
    case .other3: return "Other 3"
    case .other4: return "Other 4"
    case .other5: return "Other 5"
    case .other6: return "Other 6"
    case .other7: return "Other 7"
    case .other8: return "Other 8"
    case .other9: return "Other 9"
    case .other10: return "Other 10"
    case .mobileNumber: return "Mobile Number"
    case .phoneNumber2: return "Phone Number 2"
    case .phoneNumber3: return "Phone Number 3"
    case .iosAdvertiserId: return "iOS Advertiser ID (IDFA)"
    case .iosVendorId: return "iOS Vendor ID (IDFV)"
    case .pushToken: return "Push Token"
    case .deviceApplicationStamp: return "Device Application Stamp"
    @unknown default: return "Unknown (\(type.rawValue))"
    }
}

func forceUpload() {
    MParticle.sharedInstance().upload()
    print("Force upload triggered")
}

func getKitStatus() -> String {
    let mParticle = MParticle.sharedInstance()

    var status = "=== KIT STATUS ===\n\n"

    // Common kit codes - add more as needed
    let commonKits: [(code: NSNumber, name: String)] = [
        (NSNumber(value: 20), "Adjust"),
        (NSNumber(value: 119), "Adobe Analytics"),
        (NSNumber(value: 28), "Appboy/Braze"),
        (NSNumber(value: 92), "AppsFlyer"),
        (NSNumber(value: 31), "Amplitude"),
        (NSNumber(value: 39), "Branch"),
        (NSNumber(value: 134), "Facebook"),
        (NSNumber(value: 64), "Firebase"),
        (NSNumber(value: 160), "Google Analytics 4"),
        (NSNumber(value: 37), "Kochava"),
        (NSNumber(value: 49), "Leanplum"),
        (NSNumber(value: 128), "Segment"),
        (NSNumber(value: 170), "Singular")
    ]

    status += "--- COMMON KITS ---\n"
    for kit in commonKits {
        let isActive = mParticle.isKitActive(kit.code)
        let statusEmoji = isActive ? "✅" : "❌"
        status += "\(statusEmoji) \(kit.name) (\(kit.code)): \(isActive ? "Active" : "Inactive")\n"
    }

    status += "\n--- ACTIVE KITS ---\n"
    // Get all active kits
    var hasActiveKits = false
    for kit in commonKits where mParticle.isKitActive(kit.code) {
        hasActiveKits = true
        status += "• \(kit.name)\n"
    }

    if !hasActiveKits {
        status += "(no kits currently active)\n"
    }

    status += "\n--- NOTE ---\n"
    status += "Kits become active after receiving\nconfiguration from mParticle server.\n"
    status += "Ensure you have kits enabled in\nyour mParticle workspace."

    return status
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

func selectPlacementWithEventSubscription() {
    let customAttributes: [String: String] = [
        "email": "j.smit@example.com",
        "firstname": "Jenny",
        "lastname": "Smith",
        "sandbox": "true",
        "mobile": "(555)867-5309"
    ]

    let placementIdentifier = "RoktLayout"

    // Subscribe to Rokt events for this placement
    MParticle.sharedInstance().rokt.events(placementIdentifier) { event in
        switch event {
        case let initComplete as MPRoktEvent.MPRoktInitComplete:
            print("Rokt Init Complete - Success: \(initComplete.success)")

        case is MPRoktEvent.MPRoktShowLoadingIndicator:
            print("Rokt: Show Loading Indicator")

        case is MPRoktEvent.MPRoktHideLoadingIndicator:
            print("Rokt: Hide Loading Indicator")

        case let placementReady as MPRoktEvent.MPRoktPlacementReady:
            print("Rokt Placement Ready - ID: \(placementReady.placementId ?? "unknown")")

        case let placementInteractive as MPRoktEvent.MPRoktPlacementInteractive:
            print("Rokt Placement Interactive - ID: \(placementInteractive.placementId ?? "unknown")")

        case let offerEngagement as MPRoktEvent.MPRoktOfferEngagement:
            print("Rokt Offer Engagement - ID: \(offerEngagement.placementId ?? "unknown")")

        case let positiveEngagement as MPRoktEvent.MPRoktPositiveEngagement:
            print("Rokt Positive Engagement - ID: \(positiveEngagement.placementId ?? "unknown")")

        case let firstPositiveEngagement as MPRoktEvent.MPRoktFirstPositiveEngagement:
            print("Rokt First Positive Engagement - ID: \(firstPositiveEngagement.placementId ?? "unknown")")

        case let openUrl as MPRoktEvent.MPRoktOpenUrl:
            print("Rokt Open URL - ID: \(openUrl.placementId ?? "unknown"), URL: \(openUrl.url)")

        case let placementClosed as MPRoktEvent.MPRoktPlacementClosed:
            print("Rokt Placement Closed - ID: \(placementClosed.placementId ?? "unknown")")

        case let placementCompleted as MPRoktEvent.MPRoktPlacementCompleted:
            print("Rokt Placement Completed - ID: \(placementCompleted.placementId ?? "unknown")")

        case let placementFailure as MPRoktEvent.MPRoktPlacementFailure:
            print("Rokt Placement Failure - ID: \(placementFailure.placementId ?? "unknown")")

        case let cartItem as MPRoktEvent.MPRoktCartItemInstantPurchase:
            print("Rokt Cart Item Instant Purchase:")
            print("  - Placement ID: \(cartItem.placementId)")
            print("  - Catalog Item ID: \(cartItem.catalogItemId)")
            print("  - Cart Item ID: \(cartItem.cartItemId)")
            print("  - Name: \(cartItem.name ?? "unknown")")
            print("  - Currency: \(cartItem.currency)")
            print("  - Unit Price: \(cartItem.unitPrice ?? 0)")
            print("  - Total Price: \(cartItem.totalPrice ?? 0)")
            print("  - Quantity: \(cartItem.quantity ?? 0)")

        default:
            print("Rokt: Unknown event type - \(type(of: event))")
        }
    }

    // Select the placement (this will trigger events)
    MParticle.sharedInstance().rokt.selectPlacements(placementIdentifier, attributes: customAttributes)
}

#Preview {
    ContentView()
}
