//
//  NSDictionary+MPCaseInsensitive.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 1/29/25.
//

import Foundation
public extension NSDictionary {

    @objc func caseInsensitiveKey(_ key: String) -> String? {
        var localKey = key
        
        self.allKeys.forEach { keyValue in
            if let stringKey = keyValue as? String, stringKey.caseInsensitiveCompare(key) == .orderedSame {
                localKey = stringKey
            }
        }
        return localKey
    }

    @objc func value(forCaseInsensitiveKey key: String) -> Any? {
        var value : Any?
        
        self.allKeys.forEach { keyValue in
            if let stringKey = keyValue as? String, stringKey.caseInsensitiveCompare(key) == .orderedSame {
                value = self[stringKey]
            }
        }
        
        return value
    }

    @objc func transformValuesToString() -> [String : Any] {
        let transformedDictionary: [String : Any] = self.reduce(into: [:]) { result, element in
            let key = element.key as! String
            if let stringValue = element.value as? String {
                result[key] = stringValue
            } else if let stringValue = element.value as? NSString {
                result[key] = stringValue
            } else if let numberValue = element.value as? NSNumber {
                result[key] = numberValue.stringValue
            } else if let boolValue = element.value as? Bool {
                result[key] = boolValue ? "true" : "false"
            } else if let dateValue = element.value as? Date {
                result[key] = MPDateFormatter.string(fromDateRFC1123: dateValue)
            } else if let dateValue = element.value as? NSDate {
                result[key] = MPDateFormatter.string(fromDateRFC1123: dateValue as Date)
            } else if let dataValue = element.value as? Data, dataValue.count > 0 {
                result[key] = String.init(data: dataValue, encoding: .utf8)
            } else if let dataValue = element.value as? NSData, dataValue.length > 0 {
                result[key] = String.init(data: dataValue as Data, encoding: .utf8)
            } else if let dictValue = element.value as? [String : Any] {
                result[key] = dictValue.description
            } else if let dictValue = element.value as? NSDictionary {
                result[key] = dictValue.description
            } else if let dictValue = element.value as? NSMutableDictionary {
                result[key] = dictValue.description
            } else if let arrayValue = element.value as? [Any] {
                result[key] = arrayValue.description
            } else if let arrayValue = element.value as? NSArray {
                result[key] = arrayValue.description
            } else if let arrayValue = element.value as? NSMutableArray {
                result[key] = arrayValue.description
            } else if element.value is NSNull {
                result[key] = "null"
            } else {
                MPLog.warning("Data type is not supported as an attribute value: \(type(of: element.value)) for key \(key)")
            }
        }
        
        return transformedDictionary
    }
}

extension Dictionary {

    public func caseInsensitiveKey(_ key: String) -> String? {
        var localKey = key
        
        self.keys.forEach { keyValue in
            if let stringKey = keyValue as? String, stringKey.caseInsensitiveCompare(key) == .orderedSame {
                localKey = stringKey
            }
        }
        return localKey
    }

    public func value(forCaseInsensitiveKey key: String) -> Any? {
        var value : Any?
        
        self.keys.forEach { keyValue in
            if let stringKey = keyValue as? String, stringKey.caseInsensitiveCompare(key) == .orderedSame {
                value = self[keyValue]
            }
        }
        
        return value
    }

    public func transformValuesToString() -> [String : Any] {
        let transformedDictionary: [String : Any] = self.reduce(into: [:]) { result, element in
            let key = element.key as! String
            if let stringValue = element.value as? String {
                result[key] = stringValue
            } else if let stringValue = element.value as? NSString {
                result[key] = stringValue
            } else if let numberValue = element.value as? NSNumber {
                result[key] = numberValue.stringValue
            } else if let boolValue = element.value as? Bool {
                result[key] = boolValue ? "true" : "false"
            } else if let dateValue = element.value as? Date {
                result[key] = MPDateFormatter.string(fromDateRFC1123: dateValue)
            } else if let dateValue = element.value as? NSDate {
                result[key] = MPDateFormatter.string(fromDateRFC1123: dateValue as Date)
            } else if let dataValue = element.value as? Data, dataValue.count > 0 {
                result[key] = String.init(data: dataValue, encoding: .utf8)
            } else if let dataValue = element.value as? NSData, dataValue.length > 0 {
                result[key] = String.init(data: dataValue as Data, encoding: .utf8)
            } else if let dictValue = element.value as? [String : Any] {
                result[key] = dictValue.description
            } else if let dictValue = element.value as? NSDictionary {
                result[key] = dictValue.description
            } else if let dictValue = element.value as? NSMutableDictionary {
                result[key] = dictValue.description
            } else if let arrayValue = element.value as? [Any] {
                result[key] = arrayValue.description
            } else if let arrayValue = element.value as? NSArray {
                result[key] = arrayValue.description
            } else if let arrayValue = element.value as? NSMutableArray {
                result[key] = arrayValue.description
            } else if element.value is NSNull {
                result[key] = "null"
            } else {
                MPLog.warning("Data type is not supported as an attribute value: \(type(of: element.value)) for key \(key)")
            }
        }
        
        return transformedDictionary
    }
}
