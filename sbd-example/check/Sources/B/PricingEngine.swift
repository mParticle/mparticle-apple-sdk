/// Module B - pure Swift, without ObjC compatibility
/// Uses struct, generics and other Swift-specific features
public struct PricingEngine {
    public init() {}
    
    /// Calculates price for user
    /// - Parameter userId: User ID
    /// - Returns: Price as Int
    public func price(for userId: String) -> Int {
        // Let's say, complex Swift logic
        return userId.count * 10
    }
    
    /// Example method with generics (not accessible from ObjC)
    public func process<T: Numeric>(_ value: T) -> T {
        return value
    }
}
