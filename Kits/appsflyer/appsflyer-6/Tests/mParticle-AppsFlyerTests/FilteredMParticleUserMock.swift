//
//  FilteredMParticleUserMock.swift
//  mParticle-AppsFlyer
//

@testable import mParticle_AppsFlyer

class FilteredMParticleUserMock: FilteredMParticleUser {
    private let mockUserId: NSNumber
    private let mockUserIdentities: [NSNumber: String]

    init(userId: NSNumber, userIdentities: [NSNumber: String] = [:]) {
        mockUserId = userId
        mockUserIdentities = userIdentities
        super.init()
    }

    override var userId: NSNumber { mockUserId }
    override var userIdentities: [NSNumber: String] { mockUserIdentities }
}
