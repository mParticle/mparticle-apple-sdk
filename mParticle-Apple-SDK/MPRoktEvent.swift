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
    @objc public class InitComplete: MPRoktEvent {
        @objc public let success: Bool

        init(success: Bool) {
            self.success = success
        }
    }

    @objc public class ShowLoadingIndicator: MPRoktEvent {}

    @objc public class HideLoadingIndicator: MPRoktEvent {}

    @objc public class PlacementInteractive: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class PlacementReady: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class OfferEngagement: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class OpenUrl: MPRoktEvent {
        @objc public let placementId: String?
        @objc public let url: String

        init(placementId: String?, url: String) {
            self.url = url
            self.placementId = placementId
        }
    }

    @objc public class PositiveEngagement: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class PlacementClosed: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class PlacementCompleted: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class PlacementFailure: MPRoktEvent {
        @objc public let placementId: String?

        init(placementId: String?) {
            self.placementId = placementId
        }
    }

    @objc public class FirstPositiveEngagement: MPRoktEvent {
        @objc public let placementId: String?
        private let onFulfillmentAttributesUpdate: ([String: String]) -> Void

        init(placementId: String?, onFulfillmentAttributesUpdate: @escaping ([String: String]) -> Void) {
            self.placementId = placementId
            self.onFulfillmentAttributesUpdate = onFulfillmentAttributesUpdate
        }

        @objc public func setFulfillmentAttributes(attributes: [String: String]) {
            onFulfillmentAttributesUpdate(attributes)
        }
    }

    @objc public class CartItemInstantPurchase: MPRoktEvent {
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

        init(placementId: String,
             name: String,
             cartItemId: String,
             catalogItemId: String,
             currency: String,
             description: String,
             linkedProductId: String?,
             providerData: String,
             quantity: Decimal?,
             totalPrice: Decimal?,
             unitPrice: Decimal?) {
            self.placementId = placementId
            self.name = name
            self.cartItemId = cartItemId
            self.catalogItemId = catalogItemId
            self.currency = currency
            self._description = description
            self.linkedProductId = linkedProductId
            self.providerData = providerData
            self.quantity = quantity.map { NSDecimalNumber(decimal: $0) }
            self.totalPrice = totalPrice.map { NSDecimalNumber(decimal: $0) }
            self.unitPrice = unitPrice.map { NSDecimalNumber(decimal: $0) }
        }
    }
}

