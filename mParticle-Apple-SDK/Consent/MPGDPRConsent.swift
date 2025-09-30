//
//  MPGDPRConsent.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 9/19/24.
//

import Foundation

/**
 * Record of consent under the GDPR.
 */
@objc public class MPGDPRConsent : NSObject, NSCopying {

    
    /**
    * Whether the user consented to data collection
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
        let copy = MPGDPRConsent()
        copy.consented = consented
        copy.document = document
        copy.timestamp = timestamp
        copy.location = location
        copy.hardwareId = hardwareId
        return copy
    }
}

