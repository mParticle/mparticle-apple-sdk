import RoktContracts
import StripePayments

enum BillingDetailsMapping {
    /// Maps a ``ContactAddress`` to Stripe billing details for Afterpay payment method params.
    static func map(from address: ContactAddress, fallbackName: String? = nil) -> STPPaymentMethodBillingDetails {
        let billing = STPPaymentMethodBillingDetails()
        billing.name = resolvedName(address.name, fallback: fallbackName)
        billing.email = address.email

        let stripeAddress = STPPaymentMethodAddress()
        stripeAddress.line1 = address.addressLine1
        stripeAddress.line2 = address.addressLine2
        stripeAddress.city = address.city
        stripeAddress.state = address.state
        stripeAddress.postalCode = address.postalCode
        stripeAddress.country = address.country
        billing.address = stripeAddress

        return billing
    }

    /// Maps a ``ContactAddress`` to Stripe shipping details for the PaymentIntent.
    static func mapShipping(
        from address: ContactAddress,
        fallbackName: String? = nil
    ) -> STPPaymentIntentShippingDetailsParams {
        let shippingAddress = STPPaymentIntentShippingDetailsAddressParams(line1: address.addressLine1 ?? "")
        shippingAddress.line2 = address.addressLine2
        shippingAddress.city = address.city
        shippingAddress.state = address.state
        shippingAddress.postalCode = address.postalCode
        shippingAddress.country = address.country

        return STPPaymentIntentShippingDetailsParams(
            address: shippingAddress,
            name: resolvedName(address.name, fallback: fallbackName) ?? ""
        )
    }

    static func resolvedName(_ name: String?, fallback: String? = nil) -> String? {
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            return trimmed
        }

        let fallback = fallback?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let fallback, !fallback.isEmpty {
            return fallback
        }

        return nil
    }
}
