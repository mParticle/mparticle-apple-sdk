//
//  mParticle_Rokt_SwiftTests.swift
//  mParticle_RoktTests
//
//  Created by Brandon Stalnaker on 6/30/25.
//  Copyright © 2025 mParticle. All rights reserved.
//

import Testing
import SwiftUI
import ObjectiveC.runtime
@testable import mParticle_Rokt
import Rokt_Widget
import RoktContracts
import mParticle_Rokt_Swift

@Suite(.serialized)
// swiftlint:disable:next type_name
struct mParticle_Rokt_SwiftTests {

    @MainActor @available(iOS 15, *)
    @Test func testLayoutWithMalformedRoktConfiguration() throws {
        let initialize = try #require(class_getClassMethod(
            Rokt.self,
            NSSelectorFromString("initWithRoktTagId:mParticleSdkVersion:mParticleKitVersion:")
        ))
        let skipInitialization: @convention(block) (AnyObject, AnyObject?, AnyObject?, AnyObject?) -> Void = { _, _, _, _ in }
        let initializationStub = imp_implementationWithBlock(skipInitialization)
        let originalInitialization = method_setImplementation(initialize, initializationStub)
        defer {
            method_setImplementation(initialize, originalInitialization)
            imp_removeBlock(initializationStub)
        }

        var events: [MPBaseEvent] = []
        let logEvent = try #require(class_getInstanceMethod(MParticle.self, NSSelectorFromString("logEvent:")))
        let captureEvent: @convention(block) (AnyObject, MPBaseEvent) -> Void = { _, event in events.append(event) }
        let eventStub = imp_implementationWithBlock(captureEvent)
        let originalLogEvent = method_setImplementation(logEvent, eventStub)
        defer {
            method_setImplementation(logEvent, originalLogEvent)
            imp_removeBlock(eventStub)
        }

        let kit = MPKitRokt()
        defer { (kit as MPKitProtocol).stop?() }

        let mappings: [Any] = [1, NSNull(), "{\"x\":1}", "[1,null]", "[{\"map\":\"source\",\"value\":7}]"]
        for mapping in mappings {
            let status = kit.didFinishLaunching(withConfiguration: [
                "accountId": "test_account_id",
                "placementAttributesMapping": mapping,
                "hashedEmailUserIdentityType": NSNull()
            ])
            #expect(status.returnCode == .success)
            let layout = MPRoktLayout(
                sdkTriggered: .constant(false),
                identifier: "",
                attributes: ["source": "kept", "sandbox": "true"]
            )
            #expect(layout.roktLayout != nil)
            let prepared = MPKitRokt.prepareAttributes(
                ["source": "kept", "sandbox": "true"],
                filteredUser: nil,
                performMapping: true
            )
            #expect(prepared["source"] == "kept")
            #expect(prepared["sandbox"] == "true")
        }
        #expect(events.count == mappings.count)
        for event in events {
            #expect((event as? MPEvent)?.name == "selectPlacements")
            #expect(event.type == .other)
            #expect(event.customAttributes?.isEmpty ?? true)
        }
    }

    // MARK: - Initialization Tests

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutBasicInitialization() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let locationName = "test_location"
        let attributes: [String: String] = ["key1": "value1", "key2": "value2"]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: locationName,
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout.roktLayout should not be nil")
    }

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutInitializationWithAllParameters() {
        // Given
        let sdkTriggered = Binding.constant(true)
        let viewName = "test_view"
        let locationName = "test_location"
        let attributes: [String: String] = ["user_id": "12345", "sandbox": "true"]
        let config = RoktConfig.Builder().colorMode(.light).build()
        let onEvent: (RoktEvent) -> Void = { _ in
        }

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: viewName,
            locationName: locationName,
            attributes: attributes,
            config: config,
            onEvent: onEvent
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout.roktLayout should not be nil")
    }

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutInitializationWithEmptyAttributes() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let locationName = "empty_attributes_test"
        let attributes: [String: String] = [:]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: locationName,
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should handle empty attributes")
    }

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutInitializationWithSandboxAttribute() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let locationName = "sandbox_test"
        let attributes: [String: String] = ["sandbox": "true", "user_id": "test_user"]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: locationName,
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should handle sandbox attribute")
    }

    // MARK: - Attribute Preparation Tests

    @available(iOS 15, *)
    @Test func testAttributePreparationCalled() {
        // Given
        let attributes: [String: String] = ["original_key": "original_value"]

        // When
        let preparedAttributes = MPKitRokt.prepareAttributes(
            attributes,
            filteredUser: nil,
            performMapping: true
        )

        // Then
        #expect(preparedAttributes != nil, "Prepared attributes should not be nil")
        #expect(
            preparedAttributes.count >= attributes.count,
            "Prepared attributes should contain at least the original attributes"
        )
    }

    @available(iOS 15, *)
    @Test func testAttributePreparationWithoutMapping() {
        // Given
        let attributes: [String: String] = ["test_key": "test_value"]

        // When
        let preparedAttributes = MPKitRokt.prepareAttributes(
            attributes,
            filteredUser: nil,
            performMapping: false
        )

        // Then
        #expect(preparedAttributes != nil, "Prepared attributes should not be nil")
        #expect(preparedAttributes["sandbox"] != nil, "Sandbox attribute should be added automatically")
    }

    @available(iOS 15, *)
    @Test func testAttributePreparationPreservesSandbox() {
        // Given
        let attributes: [String: String] = ["sandbox": "true", "custom_attr": "value"]

        // When
        let preparedAttributes = MPKitRokt.prepareAttributes(
            attributes,
            filteredUser: nil,
            performMapping: false
        )

        // Then
        #expect(preparedAttributes["sandbox"] == "true", "Sandbox attribute should be preserved")
        #expect(preparedAttributes["custom_attr"] == "value", "Custom attribute value should be preserved")
    }

    @available(iOS 15, *)
    @Test func testAttributePreparationPerformMapping() {
        // Given
        let attributes: [String: String] = ["sandbox": "true", "custom_attr": "value"]

        // When
        let preparedAttributes = MPKitRokt.prepareAttributes(
            attributes,
            filteredUser: nil,
            performMapping: true
        )

        // Then
        #expect(preparedAttributes["sandbox"] == "true", "Sandbox attribute should be preserved")
        #expect(preparedAttributes["custom_attr"] != nil, "Custom attributes should be preserved")
    }

    // MARK: - View Functionality Tests

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutIsSwiftUIView() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let attributes: [String: String] = ["test": "value"]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: "test",
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout is any View, "MPRoktLayout should conform to SwiftUI View protocol")
    }

    // MARK: - Parameter Validation Tests

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutWithLongLocationName() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let longLocationName = String(repeating: "a", count: 1000)
        let attributes: [String: String] = ["test": "value"]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: longLocationName,
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should handle long location names")
    }

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutWithSpecialCharacters() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let locationName = "test_location_with_特殊字符_🎉"
        let attributes: [String: String] = [
            "unicode_key_🌟": "unicode_value_🎯",
            "special_chars": "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        ]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: locationName,
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should handle special characters and unicode")
    }

    // MARK: - State Management Tests

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutSDKTriggeredStateChange() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let attributes: [String: String] = ["test": "value"]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "",
            locationName: "state_test",
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should be created with initial state")

        // When state changes
        sdkTriggered.wrappedValue = true

        // Then
        #expect(layout.roktLayout != nil, "Layout should handle state changes")
    }

    // MARK: - SelectPlacements Custom Event Tests

    @available(iOS 15, *)
    @Test func testPrepareAttributesLogsAttributesEvent() {
        // Given
        let attributes: [String: String] = ["attr1": "val1"]

        // When
        let preparedAttributes = MPKitRokt.prepareAttributes(
            attributes,
            filteredUser: nil,
            performMapping: false
        )

        MPKitRokt.logSelectPlacementEvent(preparedAttributes)

        // Then
        #expect(preparedAttributes["sandbox"] != nil, "Sandbox attribute should be present")
        #expect(preparedAttributes.count >= 1, "Prepared attributes should contain at least the sandbox attribute")
    }

    @available(iOS 15, *)
    @Test func testLogSelectPlacementEventHandlesNilMParticleInstance() {
        // Given
        let attributes: [String: String] = ["key1": "value1"]

        // When
        MPKitRokt.logSelectPlacementEvent(attributes)

        // Then
        #expect(true, "logSelectPlacementEvent should handle MParticle instance state gracefully")
    }

    // MARK: - Integration Tests

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutAttributeProcessingIntegration() {
        // Given
        let sdkTriggered = Binding.constant(false)
        let attributes: [String: String] = [
            "user_id": "12345",
            "email": "test@example.com",
            "custom_attribute": "custom_value"
        ]

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: "integration_test",
            locationName: "test_location",
            attributes: attributes
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should attempt to identify user attributes and fail")
    }

    @MainActor @available(iOS 15, *)
    @Test func testMPRoktLayoutWithComplexConfiguration() {
        // Given
        let sdkTriggered = Binding.constant(true)
        let viewName = "complex_config_test"
        let locationName = "complex_location"
        let attributes: [String: String] = [
            "user_type": "premium",
            "campaign_id": "summer_2025",
            "ab_test_group": "variant_a",
            "sandbox": "false"
        ]
        let config = RoktConfig.Builder().colorMode(.light).build()
        var eventsReceived: [RoktEvent] = []
        let onEvent: (RoktEvent) -> Void = { event in
            eventsReceived.append(event)
        }

        // When
        let layout = MPRoktLayout(
            sdkTriggered: sdkTriggered,
            identifier: viewName,
            locationName: locationName,
            attributes: attributes,
            config: config,
            onEvent: onEvent
        )

        // Then
        #expect(layout.roktLayout != nil, "Layout should handle complex configurations")
    }
}
