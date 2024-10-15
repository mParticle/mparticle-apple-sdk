//
//  NSDictionary+MPCaseInsensitive.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 10/9/24.
//

import Foundation

extension NSDictionary {

    
    @objc public func caseInsensitiveKey(_ key: String) -> String? {
        var resultKey: String?
        self.allKeys.forEach {obj in
            if let stringObj = obj as? String {
                if (stringObj.caseInsensitiveCompare(key) == ComparisonResult.orderedSame) {
                    resultKey = stringObj
                    return
                }
            }
        }
        
        if (resultKey == nil) {
            resultKey = key
        }
        
        return resultKey
    }

    @objc public func value(forCaseInsensitiveKey key: String) -> Any? {
        var resultValue: Any?
        self.allKeys.forEach {obj in
            if let stringObj = obj as? String {
                if (stringObj.caseInsensitiveCompare(key) == ComparisonResult.orderedSame) {
                    resultValue = self[stringObj]
                    return
                }
            }
        }
        
        return resultValue
    }

    @objc public func transformValuesToString() -> [String : Any] {
        let originalDictionary = self
        var transformedDictionary = [String: Any]()
        
        originalDictionary.allKeys.forEach {key in
            if let key = key as? String {
                if let stringValue = originalDictionary[key] as? String {
                    transformedDictionary[key] = stringValue
                } else if let numberValue = originalDictionary[key] as? NSNumber {
                    transformedDictionary[key] = numberValue.stringValue
                } else if let boolValue = originalDictionary[key] as? Bool {
                    if boolValue {
                        transformedDictionary[key] = "true"
                    } else {
                        transformedDictionary[key] = "false"
                    }
                } else if let dateValue = originalDictionary[key] as? Date {
                    transformedDictionary[key] = MPDateFormatter.string(fromDateRFC3339: dateValue)
                } else if let dictionaryValue = originalDictionary[key] as? NSDictionary {
                    transformedDictionary[key] = dictionaryValue.description
                } else if let mutDictionaryValue = originalDictionary[key] as? NSMutableDictionary {
                    transformedDictionary[key] = mutDictionaryValue.description
                } else if let arrayValue = originalDictionary[key] as? [Any] {
                    transformedDictionary[key] = arrayValue.description
                } else if let mutArrayValue = originalDictionary[key] as? NSMutableArray {
                    transformedDictionary[key] = mutArrayValue.description
                } else if let nullValue = originalDictionary[key] as? NSNull {
                    transformedDictionary[key] = nullValue
                } else if let obj = originalDictionary[key] {
                    let type = type(of: obj)
                    MPLogger.MPLogError(format: "Data type is not supported as an attribute value: \(obj) - \(type)")
                }
            }
        }
        
        return transformedDictionary
    }
}
