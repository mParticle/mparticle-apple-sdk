import Foundation
import StripePayments

enum StripePaymentDiagnostics {
    private static let stripeRequestIDKey = "com.stripe.lib:StripeRequestIDKey"

    static func paymentIntentId(fromClientSecret clientSecret: String?) -> String? {
        guard let clientSecret else { return nil }
        return STPPaymentIntentParams(clientSecret: clientSecret).stripeId
    }

    static func failureMessage(
        baseMessage: String,
        paymentIntent: STPPaymentIntent?,
        error: Error?
    ) -> String {
        return failureMessage(
            baseMessage: baseMessage,
            paymentIntentId: paymentIntent?.stripeId,
            error: error
        )
    }

    static func failureMessage(
        baseMessage: String,
        paymentIntentId: String?,
        error: Error? = nil
    ) -> String {
        if let paymentIntentId, !paymentIntentId.isEmpty {
            return "\(baseMessage) (Stripe paymentIntentId: \(paymentIntentId))"
        }
        if let requestId = requestId(from: error) {
            return "\(baseMessage) (Stripe requestId: \(requestId))"
        }

        return baseMessage
    }

    static func transactionId(from paymentIntent: STPPaymentIntent?, clientSecret: String) -> String {
        paymentIntent?.stripeId
            ?? paymentIntentId(fromClientSecret: clientSecret)
            ?? "unknown"
    }

    private static func requestId(from error: Error?) -> String? {
        let requestId = (error as NSError?)?.userInfo[stripeRequestIDKey] as? String
        return requestId?.isEmpty == false ? requestId : nil
    }
}
