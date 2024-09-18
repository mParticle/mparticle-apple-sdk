//
//  MPCCPAConsent.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 9/17/24.
//

import Foundation

/**
 * Record of consent under the CCPA.
 */
@objc public final class MPCCPAConsent: NSObject, NSCopying {
    
    /**
    * Whether the user consented to data collection
    This should be set to false if the user has opted out of data sharing under the CCPA.
    */
    @objc public var consented = false
    
    /**
    * The data collection document to which the user consented or did not consent
    */
    @objc public var document: String?
    
    /**
    * Timestamp when the user was prompted for consent
    */
    @objc public var timestamp = Date()
    
    /**
    * Where the consent prompt took place. This can be a physical or digital location (e.g. URL)
    */
    @objc public var location: String?
    
    /**
    * The device ID associated with this consent record
    */
    @objc public var hardwareId: String?
    
    @objc public func copy(with zone: NSZone? = nil) -> Any {
        let copy = MPCCPAConsent()
        copy.consented = consented
        copy.document = document
        copy.timestamp = timestamp
        copy.location = location
        copy.hardwareId = hardwareId
        return copy
    }
}
