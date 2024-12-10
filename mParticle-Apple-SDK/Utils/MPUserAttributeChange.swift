//
//  MPUserAttributeChange.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 12/9/24.
//

import Foundation

@objc public class MPUserAttributeChange : NSObject {

    @objc public var key: String
    @objc public var timestamp: Date?
    @objc public var userAttributes: [String : Any]?
    @objc public var value: Any?
    @objc public var valueToLog: Any?
    @objc public private(set) var changed: Bool
    @objc public var deleted: Bool
    @objc public var isArray: Bool
    
    @objc public init?(userAttributes: [String : Any]? = nil, key: String, value: Any?) {
        guard value == nil || value is [Any] || value is NSNull || value is String || value is NSNumber else {
            return nil
        }
        
        if userAttributes == nil && value == nil {
            return nil
        }
        
        self.key = key
        self.value = value
        self.deleted = false
        self.valueToLog = value
        self.userAttributes = userAttributes
        
        let existingValue = userAttributes?[key]
        self.isArray = (value is [Any] || existingValue is [Any])
        self.changed = !equals(existingValue, value)
        super.init()
    }
}

fileprivate func equals(_ x : Any?, _ y : Any?) -> Bool {
    guard let x = x as? AnyHashable, let y = y as? AnyHashable else {
        return false
    }
    return x == y
}
