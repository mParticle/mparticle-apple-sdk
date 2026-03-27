//
//  MPRoktLayout.swift
//  mParticle-Rokt
//
//  Copyright 2025 Rokt Pte Ltd
//
//  Licensed under the Rokt Software Development Kit (SDK) Terms of Use
//  Version 2.0 (the "License");
//
//  You may not use this file except in compliance with the License.
//
//  You may obtain a copy of the License at https://rokt.com/sdk-license-2-0/

import SwiftUI
import Rokt_Widget
import mParticle_Apple_SDK
import mParticle_Rokt

@available(iOS 15, *)
public class MPRoktLayout {
    public var roktLayout: RoktLayout?
    let mparticle = MParticle.sharedInstance()

    public init(
        sdkTriggered: Binding<Bool>,
        identifier: String,
        locationName: String = "",
        attributes: [String: String],
        config: RoktConfig? = nil,
        onEvent: ((RoktEvent) -> Void)? = nil
    ) {
        // Capture the timestamp when the SwiftUI component is rendered
        let options = RoktPlacementOptions(timestamp: Int64(Date().timeIntervalSince1970 * 1000))

        MPRoktLayout
            .mpLog(
                "Initializing MPRoktLayout with arguments " +
                    "sdkTriggered:\(sdkTriggered.wrappedValue), " +
                    "viewName:\(identifier), " +
                    "locationName:\(locationName), " +
                    "attributes:\(attributes)"
            )
        confirmUser(attributes: attributes) { identifyCalled in
            let preparedAttributes = MPKitRokt.prepareAttributes(
                attributes,
                filteredUser: Optional<FilteredMParticleUser>.none,
                performMapping: true
            )

            // Log custom event for selectPlacements call
            MPKitRokt.logSelectPlacementEvent(preparedAttributes)

            MPRoktLayout
                .mpLog(
                    "Initializing RoktLayout with arguments " +
                        "sdkTriggered:\(sdkTriggered.wrappedValue), " +
                        "viewName: \(identifier), " +
                        "locationName:\(locationName), " +
                        "attributes:\(preparedAttributes)"
                )

            self.roktLayout = RoktLayout.init(
                sdkTriggered: sdkTriggered,
                identifier: identifier,
                location: locationName,
                attributes: preparedAttributes,
                config: config,
                placementOptions: options,
                onEvent: onEvent
            )
            // The Binding variable provided by the client allows us to trigger a re-render of the UI but we only want to do this if the value was true to start
            if identifyCalled && sdkTriggered.wrappedValue {
                MPRoktLayout.mpLog("Triggering Rokt Swift UI re-render")
                DispatchQueue.main.async {
                    sdkTriggered.wrappedValue = false
                    sdkTriggered.wrappedValue = true
                }
            }
        }
    }

    func confirmUser(
        attributes: [String: String]?,
        completion: @escaping (Bool) -> Void
    ) {
        guard let user = mparticle.identity.currentUser else {
            completion(false)
            return
        }
        let email = attributes?["email"]
        let hashedEmail = attributes?["emailsha256"]
        let hashedEmailIdentity = MPKitRokt.getHashedEmailUserIdentityType()

        let userEmailIdentity = user.identities[NSNumber(value: MPIdentity.email.rawValue)]

        let emailMismatch: Bool = {
            guard let email = email,
                  let userEmail = user.identities[NSNumber(value: MPIdentity.email.rawValue)] else {
                return false
            }
            return email != userEmail
        }()
        let hashedEmailMismatch: Bool = {
            guard let hashedEmail = hashedEmail,
                  let hashedEmailIdentity = hashedEmailIdentity,
                  let userHashedEmail = user.identities[hashedEmailIdentity] else {
                return false
            }
            return hashedEmail != userHashedEmail
        }()

        if emailMismatch || hashedEmailMismatch {
            // If there is an existing email or hashed email but it doesn't match what was passed in, warn the customer
            if emailMismatch {
                MPRoktLayout
                    .mpLog(
                        "The existing email on the user " +
                            "(\(userEmailIdentity ?? "nil")) does not match the email " +
                            "passed in to `selectPlacements:` (\(email ?? "nil")). " +
                            "Please remember to sync the email identity to mParticle " +
                            "as soon as you receive it. " +
                            "We will now identify the user before creating the layout"
                    )
            }
            if hashedEmailMismatch {
                MPRoktLayout
                    .mpLog(
                        "The existing hashed email on the user " +
                            "(\(user.identities[hashedEmailIdentity ?? NSNumber(value: -1)] ?? "nil")) " +
                            "does not match the email passed in to " +
                            "`selectPlacements:` (\(hashedEmail ?? "nil")). " +
                            "Please remember to sync the hashed email identity to " +
                            "mParticle as soon as you receive it. " +
                            "We will now identify the user before creating the layout"
                    )
            }

            syncIdentities(user: user, email: email, hashedEmail: hashedEmail, hashedEmailKey: hashedEmailIdentity) {
                completion(true)
            }
        } else {
            completion(false)
        }
    }

    func syncIdentities(
        user: MParticleUser,
        email: String?,
        hashedEmail: String?,
        hashedEmailKey: NSNumber?,
        completion: @escaping () -> Void
    ) {
        let identityRequest = MPIdentityApiRequest(user: user)
        identityRequest.setIdentity(email, identityType: .email)
        if let hashedEmailKey = hashedEmailKey {
            identityRequest.setIdentity(hashedEmail, identityType: MPIdentity(rawValue: hashedEmailKey.uintValue) ?? .other)
        }

        mparticle.identity.identify(identityRequest) {apiResult, error in
            if let error = error {
                MPRoktLayout.mpLog("Failed to sync email from selectPlacement to user: \(error)")
                completion()
            } else {
                if let identities = apiResult?.user.identities {
                    MPRoktLayout.mpLog("Updated user identity based off selectPlacement's attributes: \(identities)")
                }
                completion()
            }
        }
    }

    static func mpLog(_ message: String) {
        let msg = "MPRokt -> \(message)"
        if MParticle.sharedInstance().environment == .development {
            print(msg)
        }
    }
}
