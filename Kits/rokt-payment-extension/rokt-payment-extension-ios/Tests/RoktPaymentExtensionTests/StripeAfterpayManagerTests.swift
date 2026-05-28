import RoktContracts
import XCTest
@testable import RoktPaymentExtension

/// Tests that exercise validation paths inside StripeAfterpayManager through the public facade.
final class StripeAfterpayManagerTests: XCTestCase {

    private var ext: RoktPaymentExtension!

    override func setUp() {
        super.setUp()
        ext = RoktPaymentExtension(
            applePayMerchantId: "merchant.test",
            urlScheme: "testapp",
            bundle: makeBundle(withSchemes: ["testapp"])
        )!
        ext.onRegister(parameters: ["stripeKey": "pk_test_dummy"])
    }

    private func makeContext(
        billingAddress: ContactAddress? = nil,
        shippingAddress: ContactAddress? = nil
    ) -> PaymentContext {
        PaymentContext(
            billingAddress: billingAddress,
            shippingAddress: shippingAddress,
            returnURL: "testapp://stripe-redirect"
        )
    }

    private func makeBillingAddress() -> ContactAddress {
        makeAddress(name: "Jane Smith")
    }

    private func makeAddress(name: String) -> ContactAddress {
        ContactAddress(
            name: name,
            email: "jane@example.com",
            addressLine1: "123 Main St",
            addressLine2: "Apt 4B",
            city: "New York",
            state: "NY",
            postalCode: "10001",
            country: "US"
        )
    }

    // MARK: - Validation: missing both addresses

    func testAfterpayWithoutAnyAddressFails() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let context = makeContext()
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, _ in XCTFail("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertTrue(result.errorMessage?.contains("address") ?? false)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Billing address falls back to shipping when omitted

    func testAfterpayFallsBackToShippingAddressWhenBillingMissing() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let shipping = makeBillingAddress() // reuse shape; name "Jane Smith"
        let context = makeContext(billingAddress: nil, shippingAddress: shipping)
        let expect = expectation(description: "preparePayment invoked with shipping")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { address, _ in
                XCTAssertEqual(address.name, "Jane Smith",
                               "Should have received the shipping address as the billing fallback")
                expect.fulfill()
                // Don't invoke `done` — we just care that prepare fires with the right address.
            },
            completion: { _ in }
        )

        waitForExpectations(timeout: 1)
    }

    func testAfterpayWithEmptyAddressNameFailsBeforePreparation() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let context = makeContext(billingAddress: makeAddress(name: " "))
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, _ in XCTFail("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertTrue(result.errorMessage?.contains("name") ?? false)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    func testShippingMappingFallsBackToBillingNameWhenShippingNameEmpty() {
        let shipping = makeAddress(name: " ")

        let params = BillingDetailsMapping.mapShipping(from: shipping, fallbackName: "Jane Smith")

        XCTAssertEqual(params.name, "Jane Smith")
    }

    func testShippingMappingPrefersTrimmedShippingName() {
        let shipping = makeAddress(name: "  Sam Buyer  ")

        let params = BillingDetailsMapping.mapShipping(from: shipping, fallbackName: "Jane Smith")

        XCTAssertEqual(params.name, "Sam Buyer")
    }

    func testBillingMappingIncludesAddressLine2() {
        let billing = makeBillingAddress()

        let details = BillingDetailsMapping.map(from: billing)

        XCTAssertEqual(details.address?.line2, "Apt 4B")
    }

    func testShippingMappingIncludesAddressLine2() {
        let shipping = makeAddress(name: "Jane Smith")

        let params = BillingDetailsMapping.mapShipping(from: shipping)

        XCTAssertEqual(params.address.line2, "Apt 4B")
    }

    // MARK: - Validation: empty name

    func testAfterpayWithEmptyNameFails() {
        let item = PaymentItem(id: "item-1", name: "", amount: 10.00, currency: "USD")
        let context = makeContext(billingAddress: makeBillingAddress())
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, _ in XCTFail("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Validation: empty id

    func testAfterpayWithEmptyIdFails() {
        let item = PaymentItem(id: "", name: "Widget", amount: 10.00, currency: "USD")
        let context = makeContext(billingAddress: makeBillingAddress())
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, _ in XCTFail("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Validation: zero amount

    func testAfterpayWithZeroAmountFails() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 0, currency: "USD")
        let context = makeContext(billingAddress: makeBillingAddress())
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, _ in XCTFail("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Validation: empty currency

    func testAfterpayWithEmptyCurrencyFails() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "")
        let context = makeContext(billingAddress: makeBillingAddress())
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, _ in XCTFail("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - preparePayment failure

    func testAfterpayPreparePaymentFailureReturnsError() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let context = makeContext(billingAddress: makeBillingAddress())
        let expect = expectation(description: "completion")

        struct PrepError: LocalizedError {
            var errorDescription: String? { "Backend error" }
        }

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { address, done in
                XCTAssertEqual(address.name, "Jane Smith")
                XCTAssertEqual(address.email, "jane@example.com")
                done(nil, PrepError())
            },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertEqual(result.errorMessage, "Backend error")
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }
}
