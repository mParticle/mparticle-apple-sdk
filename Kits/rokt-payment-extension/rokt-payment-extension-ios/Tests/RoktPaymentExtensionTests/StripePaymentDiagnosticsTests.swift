import XCTest
@testable import RoktPaymentExtension

final class StripePaymentDiagnosticsTests: XCTestCase {

    func testPaymentIntentIdFromClientSecretUsesStripeParser() {
        let paymentIntentId = StripePaymentDiagnostics.paymentIntentId(
            fromClientSecret: "pi_test123_secret_sensitive"
        )

        XCTAssertEqual(paymentIntentId, "pi_test123")
    }

    func testFailureMessageIncludesPaymentIntentId() {
        let message = StripePaymentDiagnostics.failureMessage(
            baseMessage: "Payment failed",
            paymentIntentId: "pi_test123"
        )

        XCTAssertEqual(
            message,
            "Payment failed (Stripe paymentIntentId: pi_test123)"
        )
    }

    func testFailureMessageFallsBackToRequestId() {
        let error = NSError(
            domain: "com.stripe.lib",
            code: 50,
            userInfo: ["com.stripe.lib:StripeRequestIDKey": "req_test123"]
        )

        let message = StripePaymentDiagnostics.failureMessage(
            baseMessage: "Payment failed",
            paymentIntentId: nil,
            error: error
        )

        XCTAssertEqual(
            message,
            "Payment failed (Stripe requestId: req_test123)"
        )
    }

    func testFailureMessageDoesNotIncludeClientSecret() {
        let clientSecret = "pi_test123_secret_sensitive"
        let message = StripePaymentDiagnostics.failureMessage(
            baseMessage: "Payment failed",
            paymentIntentId: StripePaymentDiagnostics.paymentIntentId(fromClientSecret: clientSecret)
        )

        XCTAssertTrue(message.contains("pi_test123"))
        XCTAssertFalse(message.contains("_secret_"))
        XCTAssertFalse(message.contains("sensitive"))
    }

    func testFailureMessageReturnsBaseMessageWhenPaymentIntentUnavailable() {
        let message = StripePaymentDiagnostics.failureMessage(
            baseMessage: "Payment failed",
            paymentIntentId: nil
        )

        XCTAssertEqual(message, "Payment failed")
    }
}
