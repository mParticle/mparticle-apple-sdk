import Foundation

@objc public extension NSNumber {
    func formatWithNonScientificNotation() -> NSNumber {
        let minThreshold = 1.0e-5
        let selfAbsoluteValue = fabs(doubleValue)
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
