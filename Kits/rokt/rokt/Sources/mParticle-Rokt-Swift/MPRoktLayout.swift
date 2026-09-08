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
import RoktContracts
import mParticle_Apple_SDK_ObjC
#if SWIFT_PACKAGE
import mParticle_Rokt
import mParticle_Rokt_Internal
#endif

@available(iOS 15, *)
public class MPRoktLayout {
    public var roktLayout: RoktLayout?

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
        MPRoktKitImplementation.prepareAttributesForLayout(attributes) { preparedAttributes, identifyCalled in

            // Log custom event for selectPlacements call
            MPRoktKitImplementation.logSelectPlacementEvent(preparedAttributes)

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

    static func mpLog(_ message: String) {
        let msg = "MPRokt -> \(message)"
        if MParticle.sharedInstance().environment == .development {
            print(msg)
        }
    }
}
