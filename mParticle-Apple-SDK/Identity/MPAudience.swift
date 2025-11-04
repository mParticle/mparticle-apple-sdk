//
//  MPAudience.swift
//  mParticle-Apple-SDK
//
//  Created by Denis Chilik on 10/28/25.
//

@objcMembers
class MPAudience: NSObject {
    static let kMPAudienceMembershipKey = "audience_memberships"
    static let kMPAudienceIdKey = "audience_id"
    
    public let audienceId: NSNumber
    
    public init(audienceId: NSNumber) {
        self.audienceId = audienceId
    }
}
