import Foundation
import B

/// Module BObjC - Swift bridge for ObjC
/// Exports Swift API in ObjC-compatible form via @objc/NSObject
@objcMembers
public final class BPricingEngineObjC: NSObject {
    private let engine = PricingEngine()
    
    public override init() {
        super.init()
    }
    
    /// ObjC-compatible method to get price
    /// - Parameter userId: User ID
    /// - Returns: Price as NSNumber (for reliability in ObjC API)
    @objc
    public func price(forUserId userId: String) -> NSNumber {
        NSNumber(value: engine.price(for: userId))
    }
    
    /// Example method that returns String
    @objc
    public func formattedPrice(forUserId userId: String) -> String {
        let price = engine.price(for: userId)
        return "Price: \(price)"
    }
}

@objcMembers
public final class SomeType: NSObject {
    var name = "Name"
    var age: Int = 40
}
