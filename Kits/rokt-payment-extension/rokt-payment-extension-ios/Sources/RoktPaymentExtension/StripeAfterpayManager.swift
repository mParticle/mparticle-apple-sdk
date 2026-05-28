import Foundation
import RoktContracts
import StripePayments
import UIKit

internal class StripeAfterpayManager {

    private let apiClient: STPAPIClient
    private let returnURL: String

    internal init(apiClient: STPAPIClient, returnURL: String) {
        self.apiClient = apiClient
        self.returnURL = returnURL
    }

    internal func presentPayment(
        item: PaymentItem,
        context: PaymentContext,
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

        // Afterpay requires billing details. If the partner only supplies a
        // shipping address, fall back to that so the payment can still be
        // confirmed.
        guard let billingAddress = context.billingAddress ?? context.shippingAddress else {
            completion(.failed(
                error: "Afterpay requires a billing or shipping address. Provide at least one in PaymentContext."
            ))
            return
        }

        guard let billingName = BillingDetailsMapping.resolvedName(
            billingAddress.name,
            fallback: context.shippingAddress?.name
        ) else {
            completion(.failed(
                error: "Afterpay requires a billing or shipping name. Provide a non-empty name in PaymentContext."
            ))
            return
        }

        // Call preparePayment with the pre-collected address before showing any UI
        preparePayment(billingAddress) { [weak self] preparation, error in
            guard let self else { return }

            if let error, preparation == nil {
                completion(.failed(error: error.localizedDescription))
                return
            }

            guard let preparation else {
                completion(.failed(error: "Payment preparation returned nil"))
                return
            }

            // STPPaymentHandler.shared() uses STPAPIClient.shared internally,
            // so we must configure the shared client with the same publishable key
            // and connected account. (Unlike STPApplePayContext which accepts a
            // custom apiClient directly.)
            STPAPIClient.shared.publishableKey = self.apiClient.publishableKey
            STPAPIClient.shared.stripeAccount = preparation.merchantId
            self.apiClient.stripeAccount = preparation.merchantId

            let params = STPPaymentIntentParams(clientSecret: preparation.clientSecret)
            params.paymentMethodParams = STPPaymentMethodParams(
                afterpayClearpay: STPPaymentMethodAfterpayClearpayParams(),
                billingDetails: BillingDetailsMapping.map(from: billingAddress, fallbackName: billingName),
                metadata: nil
            )
            params.returnURL = self.returnURL

            if let shippingAddress = context.shippingAddress {
                params.shipping = BillingDetailsMapping.mapShipping(from: shippingAddress, fallbackName: billingName)
            }

            let authContext = SimpleAuthenticationContext(presentingController: viewController)

            DispatchQueue.main.async {
                STPPaymentHandler.shared()
                    .confirmPaymentIntent(params: params, authenticationContext: authContext) { status, intent, error in
                    switch status {
                    case .succeeded:
                        completion(.succeeded(transactionId: StripePaymentDiagnostics.transactionId(
                            from: intent,
                            clientSecret: preparation.clientSecret
                        )))
                    case .canceled:
                        completion(.canceled)
                    case .failed:
                        completion(.failed(error: StripePaymentDiagnostics.failureMessage(
                            baseMessage: error?.localizedDescription ?? "Afterpay payment failed",
                            paymentIntent: intent,
                            error: error
                        )))
                    @unknown default:
                        completion(.failed(error: "Unknown payment status"))
                    }
                }
            }
        }
    }
}

// MARK: - STPAuthenticationContext wrapper

private class SimpleAuthenticationContext: NSObject, STPAuthenticationContext {
    private let controller: UIViewController

    init(presentingController: UIViewController) {
        self.controller = presentingController
    }

    func authenticationPresentingViewController() -> UIViewController {
        controller
    }
}
