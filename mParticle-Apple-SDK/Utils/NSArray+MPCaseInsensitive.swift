//
//  NSArray+MPCaseInsensitive.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 10/7/24.
//

import Foundation

extension NSArray {
    
    @objc public func caseInsensitiveContainsObject(_ object: String) -> Bool {
        var result = false
        self.forEach {obj in
            if let stringObj = obj as? String {
                if (stringObj.caseInsensitiveCompare(object) == ComparisonResult.orderedSame) {
                    result = true
                    return
                }
            }
        }

        return result;
    }
}
