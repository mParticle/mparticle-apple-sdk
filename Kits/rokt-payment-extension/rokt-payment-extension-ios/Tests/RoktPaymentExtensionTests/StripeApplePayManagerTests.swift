import PassKit
import RoktContracts
import XCTest
@testable import RoktPaymentExtension

/// Tests that exercise validation paths inside StripeApplePayManager through the public facade.
/// Direct unit tests of StripeApplePayManager internal validation use presentPaymentSheet,
/// which surfaces failures synchronously through the completion handler when item is invalid.
final class StripeApplePayManagerTests: XCTestCase {

    private var ext: RoktPaymentExtension!

    override func setUp() {
        super.setUp()
        ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        ext.onRegister(parameters: ["stripeKey": "pk_test_dummy"])
    }

    // MARK: - Validation: empty name

    func testPresentPaymentSheetWithEmptyNameFails() {
        let item = PaymentItem(id: "item-1", name: "", amount: 9.99, currency: "USD")
        let expectation = expectation(description: "completion called")

        ext.presentPaymentSheet(
            item: item,
            method: .applePay,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, _ in fatalError("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Validation: empty id

    func testPresentPaymentSheetWithEmptyIdFails() {
        let item = PaymentItem(id: "", name: "Widget", amount: 9.99, currency: "USD")
        let expectation = expectation(description: "completion called")

        ext.presentPaymentSheet(
            item: item,
            method: .applePay,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, _ in fatalError("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Validation: zero amount

    func testPresentPaymentSheetWithZeroAmountFails() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 0, currency: "USD")
        let expectation = expectation(description: "completion called")

        ext.presentPaymentSheet(
            item: item,
            method: .applePay,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, _ in fatalError("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Validation: empty currency

    func testPresentPaymentSheetWithEmptyCurrencyFails() {
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 9.99, currency: "")
        let expectation = expectation(description: "completion called")

        ext.presentPaymentSheet(
            item: item,
            method: .applePay,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, _ in fatalError("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Summary items

    func testMakeSummaryItemsIncludesShippingAndTaxAndUsesTotal() {
        let items = StripeApplePayManager.makeSummaryItems(
            itemName: "Widget",
            subtotal: NSDecimalNumber(string: "80.00"),
            shippingCost: NSDecimalNumber(string: "5.00"),
            tax: NSDecimalNumber(string: "3.53"),
            total: NSDecimalNumber(string: "88.53")
        )

        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(items[0].label, "Widget")
        XCTAssertEqual(items[0].amount, NSDecimalNumber(string: "80.00"))
        XCTAssertEqual(items[1].label, "Shipping")
        XCTAssertEqual(items[1].amount, NSDecimalNumber(string: "5.00"))
        XCTAssertEqual(items[2].label, "Tax")
        XCTAssertEqual(items[2].amount, NSDecimalNumber(string: "3.53"))
        XCTAssertEqual(items[3].label, "Total")
        XCTAssertEqual(items[3].amount, NSDecimalNumber(string: "88.53"))
    }

    func testMakeSummaryItemsSkipsZeroShippingAndZeroTax() {
        let items = StripeApplePayManager.makeSummaryItems(
            itemName: "Widget",
            subtotal: NSDecimalNumber(string: "80.00"),
            shippingCost: .zero,
            tax: .zero,
            total: NSDecimalNumber(string: "80.00")
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].label, "Widget")
        XCTAssertEqual(items[1].label, "Total")
        XCTAssertEqual(items[1].amount, NSDecimalNumber(string: "80.00"))
    }

    func testMakeSummaryItemsPreservesDecimalPrecisionForTotal() {
        // Guards against ever switching to Double-based construction (83.53 → 83.5299999...).
        let items = StripeApplePayManager.makeSummaryItems(
            itemName: "Widget",
            subtotal: NSDecimalNumber(string: "80"),
            shippingCost: .zero,
            tax: NSDecimalNumber(string: "3.53"),
            total: NSDecimalNumber(string: "83.53")
        )

        let total = items.last!
        XCTAssertEqual(total.label, "Total")
        XCTAssertEqual(total.amount, NSDecimalNumber(string: "83.53"))
    }

    // MARK: - Validation: no manager (not registered)

    func testPresentPaymentSheetWithoutRegistrationFails() {
        let unregisteredExt = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 9.99, currency: "USD")
        let expectation = expectation(description: "completion called")

        unregisteredExt.presentPaymentSheet(
            item: item,
            method: .applePay,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, _ in fatalError("should not be called") },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertNotNil(result.errorMessage)
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }
}
