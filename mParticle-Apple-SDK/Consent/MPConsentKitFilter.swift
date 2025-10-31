//
//  MPConsentKitFilter.swift
//  mParticle-Apple-SDK
//
//  Created by Denis Chilik on 10/28/25.
//

@objcMembers
public class MPConsentKitFilter : NSObject {
    public var shouldIncludeOnMatch: NSNumber?
    public var filterItems: [MPConsentKitFilterItem]?
}
