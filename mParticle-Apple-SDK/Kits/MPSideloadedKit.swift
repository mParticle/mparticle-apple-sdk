//
//  MPSideloadedKit.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/23/23.
//

import Foundation

@objc public class MPSideloadedKit: NSObject {
    @objc public var kitInstance: MPKitProtocol
    
    internal var eventTypeFilters: [String:Any] = [:]
    internal var eventNameFilters: [String:Any] = [:]
    internal var eventAttributeFilters: [String:Any] = [:]
    internal var messageTypeFilters: [String:Any] = [:]
    internal var screenNameFilters: [String:Any] = [:]
    internal var screenAttributeFilters: [String:Any] = [:]
    internal var userIdentityFilters: [String:Any] = [:]
    internal var userAttributeFilters: [String:Any] = [:]
    internal var commerceEventAttributeFilters: [String:Any] = [:]
    internal var commerceEventEntityTypeFilters: [String:Any] = [:]
    internal var commerceEventAppFamilyAttributeFilters: [String:Any] = [:]
    internal var attributeValueFiltering: [String:Any] = [:]
    
    // MUST also include the following keys with empty dictionaries as the values, or the SDK will crash
    internal var addEventAttributeList: [String:Any] = [:]
    internal var removeEventAttributeList: [String:Any] = [:]
    internal var singleItemEventAttributeList: [String:Any] = [:]
    
    // Consent Filtering being handled seperately
    internal var consentRegulationFilters: [String:Any] = [:]
    internal var consentPurposeFilters: [String:Any] = [:]
    
    @objc public init(kitInstance: MPKitProtocol) {
        self.kitInstance = kitInstance
    }
    
    @objc func addEventTypeFilter(eventType: MPEventType) {
        eventTypeFilters[MPIHasher.hashEventType(eventType)] = 0
    }
    
    @objc func addEventNameFilter(eventType: MPEventType, eventName: String) {
        eventNameFilters[MPIHasher.hashEventName(eventType, eventName: eventName, isLogScreen: false)] = 0
    }
    
    @objc func addScreenNameFilter(screenName: String) {
        eventNameFilters[MPIHasher.hashEventName(MPEventType.click, eventName: screenName, isLogScreen: true)] = 0
    }
    
    @objc func addEventAttributeFilter(eventType: MPEventType, eventName: String, customAttributeKey: String) {
        eventAttributeFilters[MPIHasher.hashEventAttributeKey(eventType, eventName: eventName, customAttributeName: customAttributeKey, isLogScreen: false)] = 0
    }
    
    @objc func addScreenAttributeFilter(screenName: String, customAttributeKey: String) {
        eventAttributeFilters[MPIHasher.hashEventAttributeKey(MPEventType.click, eventName: screenName, customAttributeName: customAttributeKey, isLogScreen: true)] = 0
    }
    
    @objc func addUserIdentityFilter(userIdentity: MPUserIdentity) {
        userIdentityFilters[MPIHasher.hashUserIdentity(userIdentity)] = 0
    }
    
    @objc func addUserAttributeFilter(userAttributeKey: String) {
        userAttributeFilters[MPIHasher.hashUserAttributeKey(userAttributeKey)] = 0
    }
    
    @objc func addCommerceEventAttributeFilter(eventType: MPEventType, eventAttributeKey: String) {
        commerceEventAttributeFilters[MPIHasher.hashCommerceEventAttribute(eventType, key: eventAttributeKey)] = 1
    }
    
    @objc func addCommerceEventEntityTypeFilter(commerceEventKind: MPCommerceEventKind) {
        commerceEventEntityTypeFilters[String(commerceEventKind.rawValue)] = 0
    }
    
    @objc func addCommerceEventAppFamilyAttributeFilter(attributeKey: String) {
        commerceEventAppFamilyAttributeFilters[MPIHasher.hashString(attributeKey.lowercased())] = 1
    }
    
    // Special filter case that can only have 1 at a time unlike the others
    // If `forward` is true, ONLY matching events are forwarded, if false, any matching events are blocked
    // NOTE: This is iOS/Android only, web has a different signature
    // Attribute value filtering
    func setEventAttributeConditionalForwarding(attributeName: String, attributeValue: String, onlyForward: Bool) {
        self.attributeValueFiltering["a"] = MPIHasher.hashUserAttributeKey(attributeName)
        self.attributeValueFiltering["v"] = MPIHasher.hashUserAttributeValue(attributeValue)
        self.attributeValueFiltering["i"] = onlyForward;
    }
    
    // Please use the constants starting on line 393 of MPIConstants.h
    func addMessageTypeFilter(messageTypeConstant: String) {
        self.messageTypeFilters[messageTypeConstant] = 0
    }
    
    @objc func getKitConfiguration() -> [String:Any] {
        var kitConfig: [String:Any] = [:]
        kitConfig["et"] = self.eventTypeFilters
        kitConfig["ec"] = self.eventNameFilters
        kitConfig["ea"] = self.eventAttributeFilters
        kitConfig["mt"] = self.messageTypeFilters
        kitConfig["svec"] = self.screenNameFilters
        kitConfig["svea"] = self.screenAttributeFilters
        kitConfig["uid"] = self.userIdentityFilters
        kitConfig["ua"] = self.userAttributeFilters
        kitConfig["cea"] = self.commerceEventAttributeFilters
        kitConfig["ent"] = self.commerceEventEntityTypeFilters
        kitConfig["afa"] = self.commerceEventAppFamilyAttributeFilters
        kitConfig["avf"] = self.attributeValueFiltering
        
        kitConfig["eaa"] = self.addEventAttributeList
        kitConfig["ear"] = self.removeEventAttributeList
        kitConfig["eas"] = self.singleItemEventAttributeList
        
        kitConfig["reg"] = self.consentRegulationFilters
        kitConfig["pur"] = self.consentPurposeFilters
        
        return kitConfig
    }
}
