import Foundation
import PassKit
import RoktContracts
import StripeApplePay

internal class StripeApplePayManager: NSObject {

    private let apiClient: STPAPIClient
    private let merchantId: String
    private let countryCode: String

    internal init(
        apiClient: STPAPIClient,
        merchantId: String,
        countryCode: String = "US"
    ) {
        self.apiClient = apiClient
        self.merchantId = merchantId
        self.countryCode = countryCode
    }

    internal func presentPayment(
        item: PaymentItem,
        from viewController: UIViewController,
        preparePayment: @escaping (
            _ address: ContactAddress,
            _ completion: @escaping (PaymentPreparation?, Error?) -> Void
        ) -> Void,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        guard !item.name.isEmpty else {
            completion(.failed(error: "Payment item name cannot be empty"))
            return
        }

        guard !item.id.isEmpty else {
            completion(.failed(error: "Payment item id cannot be empty"))
            return
        }

        guard item.amount.compare(NSDecimalNumber.zero) == .orderedDescending else {
            completion(.failed(error: "Payment item amount must be greater than zero"))
            return
        }

        guard !item.currency.isEmpty else {
            completion(.failed(error: "Payment item currency cannot be empty"))
            return
        }

        guard PKPaymentAuthorizationController.canMakePayments() else {
            completion(.failed(error: "Apple Pay is not available on this device"))
            return
        }

        let paymentRequest = makePaymentRequest(item: item)

        let delegate = StripeApplePayDelegate(
            apiClient: apiClient,
            item: item,
            preparePayment: preparePayment,
            completion: completion
        )

        guard let applePayContext = STPApplePayContext(
            paymentRequest: paymentRequest,
            delegate: delegate
        ) else {
            completion(.failed(error: "Failed to create Apple Pay context"))
            return
        }

        applePayContext.apiClient = apiClient

        // Retain delegate for the duration of the Apple Pay flow
        objc_setAssociatedObject(applePayContext, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

        applePayContext.presentApplePay(completion: nil)
    }

    private func makePaymentRequest(item: PaymentItem) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantId
        request.countryCode = countryCode
        request.currencyCode = item.currency.uppercased()
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = [.capability3DS, .capabilityCredit, .capabilityDebit]
        request.requiredShippingContactFields = [.postalAddress, .name, .phoneNumber, .emailAddress]
        request.requiredBillingContactFields = [.postalAddress, .name]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: item.name,
                amount: item.amount
            )
        ]
        return request
    }

    /// Builds the line-itemized PassKit summary shown in the Apple Pay sheet.
    ///
    /// `total` must be taken from the server's `PaymentPreparation.totalAmount`
    /// rather than computed as `subtotal + shipping + tax` on the client — the
    /// server is the source of truth for the amount that will be charged against
    /// the PaymentIntent, and any client-side arithmetic risks drifting from it
    /// (rounding, promo codes, tax recalculation, etc.). Shipping and tax rows
    /// are only appended when positive to keep the sheet clean for orders that
    /// have neither.
    static func makeSummaryItems(
        itemName: String,
        subtotal: NSDecimalNumber,
        shippingCost: NSDecimalNumber,
        tax: NSDecimalNumber,
        total: NSDecimalNumber
    ) -> [PKPaymentSummaryItem] {
        var items: [PKPaymentSummaryItem] = [
            PKPaymentSummaryItem(label: itemName, amount: subtotal)
        ]
        if shippingCost.compare(NSDecimalNumber.zero) == .orderedDescending {
            items.append(PKPaymentSummaryItem(label: "Shipping", amount: shippingCost))
        }
        if tax.compare(NSDecimalNumber.zero) == .orderedDescending {
            items.append(PKPaymentSummaryItem(label: "Tax", amount: tax))
        }
        items.append(PKPaymentSummaryItem(label: "Total", amount: total))
        return items
    }
}

// MARK: - Private delegate

private class StripeApplePayDelegate: NSObject, ApplePayContextDelegate {

    let apiClient: STPAPIClient
    let item: PaymentItem
    let preparePayment: (
        _ address: ContactAddress,
        _ completion: @escaping (PaymentPreparation?, Error?) -> Void
    ) -> Void
    let completion: (PaymentSheetResult) -> Void

    private var clientSecret: String?
    private var isPaymentPrepared = false

    init(
        apiClient: STPAPIClient,
        item: PaymentItem,
        preparePayment: @escaping (
            _ address: ContactAddress,
            _ completion: @escaping (PaymentPreparation?, Error?) -> Void
        ) -> Void,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        self.apiClient = apiClient
        self.item = item
        self.preparePayment = preparePayment
        self.completion = completion
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didSelectShippingContact contact: PKContact,
        handler: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        let address = ContactAddressMapping.map(from: contact)

        preparePayment(address) { [weak self] preparation, _ in
            guard let self else { return }

            if let preparation {
                self.isPaymentPrepared = true
                self.clientSecret = preparation.clientSecret
                self.apiClient.stripeAccount = preparation.merchantId

                // Total must come from the server preparation, not from `item.amount` —
                // `item.amount` is the subtotal and does not include shipping or tax, so
                // using it here makes the sheet's Total disagree with the Stripe charge.
                let updatedItems = StripeApplePayManager.makeSummaryItems(
                    itemName: self.item.name,
                    subtotal: self.item.amount,
                    shippingCost: preparation.shippingCost,
                    tax: preparation.tax,
                    total: preparation.totalAmount
                )

                handler(PKPaymentRequestShippingContactUpdate(
                    errors: nil,
                    paymentSummaryItems: updatedItems,
                    shippingMethods: []
                ))
            } else {
                self.isPaymentPrepared = false
                self.clientSecret = nil

                let applePayError = PKPaymentRequest.paymentShippingAddressUnserviceableError(
                    withLocalizedDescription: "Something went wrong. Please try again."
                )
                handler(PKPaymentRequestShippingContactUpdate(
                    errors: [applePayError],
                    paymentSummaryItems: [],
                    shippingMethods: []
                ))
            }
        }
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
        paymentInformation: PKPayment
    ) async throws -> String {
        guard isPaymentPrepared, let secret = clientSecret else {
            throw NSError(
                domain: "RoktPaymentExtension",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Payment must be prepared before completion"]
            )
        }
        return secret
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPApplePayContext.PaymentStatus,
        error: Error?
    ) {
        switch status {
        case .success:
            completion(.succeeded(transactionId: StripePaymentDiagnostics.paymentIntentId(
                fromClientSecret: clientSecret
            ) ?? "unknown"))
        case .error:
            completion(.failed(error: StripePaymentDiagnostics.failureMessage(
                baseMessage: error?.localizedDescription ?? "Unknown error",
                paymentIntentId: StripePaymentDiagnostics.paymentIntentId(fromClientSecret: clientSecret),
                error: error
            )))
        case .userCancellation:
            completion(.canceled)
        @unknown default:
            completion(.failed(error: "Unknown payment status"))
        }
    }
}
