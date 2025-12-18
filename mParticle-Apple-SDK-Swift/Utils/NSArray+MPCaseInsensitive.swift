//
//  NSArray+MPCaseInsensitive.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 10/7/24.
//

import Foundation

public extension NSArray {
    @objc func caseInsensitiveContainsObject(_ object: String) -> Bool {
        return contains { item in
            guard let item = item as? String else {
                return false
            }
            return item.caseInsensitiveCompare(object) == .orderedSame
        }
    }
}

public extension Array {
    func caseInsensitiveContainsObject(_ object: String) -> Bool {
        return (self as NSArray).caseInsensitiveContainsObject(object)
    }
}
