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
        if !(value == nil || value is [Any] || value is NSNull || value is String || value is NSNumber) {
            return nil
        }
        
        if userAttributes == nil && value == nil {
            return nil;
        }
        self.key = key
        self.value = value
        self.changed = true
        self.deleted = false
        self.isArray = value is [Any]
        self.valueToLog = self.value
        self.userAttributes = userAttributes
        super.init()
        
        if let existingValue = userAttributes?[key] {
            if (value is [Any] || existingValue is [Any]) {
                self.isArray = true
            }
            if let value = value {
                if existingValue is NSNull {
                    if value is NSNull {
                        self.changed = false
                    } else {
                        self.changed = true
                    }
                } else if value is NSNull {
                    self.changed = true
                } else {
                    self.changed = !self.equals(existingValue, value)
                }
            } else {
                self.changed = true
            }
        } else {
            if let value = value {
                self.changed = true
            } else {
                self.changed = false
            }
        }
    }
    
    func equals(_ x : Any, _ y : Any) -> Bool {
        guard let x = x as? AnyHashable,
              let y = y as? AnyHashable else { return false }
        return x == y
    }
}
