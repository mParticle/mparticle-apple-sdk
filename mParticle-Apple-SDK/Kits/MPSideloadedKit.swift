//
//  MPSideloadedKit.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 6/23/23.
//

import Foundation

@objc public class MPSideloadedKit: NSObject {
    @objc public var kitInstance: MPKitProtocol
    
    @objc public init(kitInstance: MPKitProtocol) {
        self.kitInstance = kitInstance
    }
}
