//
//  NSNumber+MPFormatter.swift
//  mParticle-Apple-SDK
//
//  Created by Ben Baron on 3/9/23.
//  Copyright © 2023 mParticle, Inc. All rights reserved.
//

import Foundation

@objc public extension NSNumber {
    @objc func formatWithNonScientificNotation() -> NSNumber {
        let minThreshold = 1.0E-5
        let selfAbsoluteValue = fabs(self.doubleValue)
        var formattedNumber: NSNumber = 0
        
        if selfAbsoluteValue >= minThreshold {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            numberFormatter.maximumFractionDigits = 2
            if let stringRepresentation = numberFormatter.string(from: self) {
                formattedNumber = numberFormatter.number(from: stringRepresentation) ?? self
            } else {
                formattedNumber = self
            }
        }
        
        return formattedNumber
    }
}
