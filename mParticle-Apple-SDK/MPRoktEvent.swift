//
//  MPRoktEvent.swift
//  mParticle-Apple-SDK
//
//  Created by Thomson Thomas on 6/17/25.
//
//  This file contains the Swift classes for the MPRoktEvent enum.
//

import Foundation

@objc public class MPRoktEvent: NSObject {
    @objc public class MPRoktInitComplete: MPRoktEvent {
        @objc public let success: Bool

        @objc public init(success: Bool) {
            self.success = success
            super.init()
        }
    }

    @objc public class MPRoktShowLoadingIndicator: MPRoktEvent {
        @objc public override init() {
            super.init()
        }
    }

    @objc public class MPRoktHideLoadingIndicator: MPRoktEvent {
        @objc public override init() {
            super.init()
        }
    }

    @objc public class MPRoktPlacementInteractive: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktPlacementReady: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktOfferEngagement: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktOpenUrl: MPRoktEvent {
        @objc public let placementId: String?
        @objc public let url: String

        @objc public init(placementId: String?, url: String) {
            self.url = url
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktPositiveEngagement: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktPlacementClosed: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktPlacementCompleted: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktPlacementFailure: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktFirstPositiveEngagement: MPRoktEvent {
        @objc public let placementId: String?

        @objc public init(placementId: String?) {
            self.placementId = placementId
            super.init()
        }
    }

    @objc public class MPRoktCartItemInstantPurchase: MPRoktEvent {
        @objc public let placementId: String
        @objc public let name: String?
        @objc public let cartItemId: String
        @objc public let catalogItemId: String
        @objc public let currency: String
        private let _description: String
        @objc public override var description: String {
            _description
        }
        @objc public let linkedProductId: String?
        @objc public let providerData: String
        @objc public let quantity: NSDecimalNumber?
        @objc public let totalPrice: NSDecimalNumber?
        @objc public let unitPrice: NSDecimalNumber?

        @objc public init(placementId: String,
             name: String?,
             cartItemId: String,
             catalogItemId: String,
             currency: String,
             description: String,
             linkedProductId: String?,
             providerData: String,
             quantity: NSDecimalNumber?,
             totalPrice: NSDecimalNumber?,
             unitPrice: NSDecimalNumber?) {
            self.placementId = placementId
            self.name = name
            self.cartItemId = cartItemId
            self.catalogItemId = catalogItemId
            self.currency = currency
            self._description = description
            self.linkedProductId = linkedProductId
            self.providerData = providerData
            self.quantity = quantity
            self.totalPrice = totalPrice
            self.unitPrice = unitPrice
            super.init()
        }
    }
}

