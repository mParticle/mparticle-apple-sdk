import Foundation

@objc(MPConsentKitFilterItem)
public final class MPConsentKitFilterItem: NSObject {
    @objc public var consented: Bool = false
    @objc public var javascriptHash: Int32 = 0
}

@objc(MPConsentKitFilter)
public final class MPConsentKitFilter: NSObject {
    @objc public var shouldIncludeOnMatch: Bool = false
    @objc public var filterItems: [MPConsentKitFilterItem]?
}
