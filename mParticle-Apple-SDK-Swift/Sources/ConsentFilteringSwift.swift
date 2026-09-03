import Foundation

public final class ConsentFilteringSwift: NSObject {
    public static let kMPConsentKitFilter = "crvf"
    public static let kMPConsentKitFilterIncludeOnMatch = "i"
    public static let kMPConsentKitFilterItems = "v"
    public static let kMPConsentKitFilterItemConsented = "c"
    public static let kMPConsentKitFilterItemHash = "h"
    public static let kMPConsentRegulationFilters = "reg"
    public static let kMPConsentPurposeFilters = "pur"
    @objc public static let kMPConsentGDPRRegulationType = "1"
    @objc public static let kMPConsentCCPARegulationType = "2"
    @objc public static let kMPConsentCCPAPurposeName = "data_sale_opt_out"
}
