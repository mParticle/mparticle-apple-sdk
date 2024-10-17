//
//  NSString+MPPercentEscape.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 10/15/24.
//

import Foundation

extension NSString {
    @objc public func percentEscape() -> String? {
        var allowed = CharacterSet()
        allowed.insert(charactersIn: "; ")
        allowed = allowed.inverted
        return self.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}

extension String {
    public func percentEscape() -> String? {
        return (self as NSString).percentEscape()
    }
}
