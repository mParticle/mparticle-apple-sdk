//
//  NSString+MPPercentEscape.swift
//  mParticle-Apple-SDK
//
//  Created by Brandon Stalnaker on 10/15/24.
//

import Foundation

public extension NSString {
    @objc func percentEscape() -> String? {
        var allowed = CharacterSet()
        allowed.insert(charactersIn: "; ")
        allowed = allowed.inverted
        return addingPercentEncoding(withAllowedCharacters: allowed)
    }
}

public extension String {
    func percentEscape() -> String? {
        return (self as NSString).percentEscape()
    }
}
