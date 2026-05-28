import XCTest
@testable import RoktPaymentExtension
import RoktContracts

final class RoktPaymentExtensionTests: XCTestCase {

    // MARK: - init: at-least-one-configured guard

    func testInitWithNoParamsReturnsNil() {
        XCTAssertNil(RoktPaymentExtension())
    }

    func testInitWithEmptyMerchantIdOnlyReturnsNil() {
        XCTAssertNil(RoktPaymentExtension(applePayMerchantId: ""))
    }

    func testInitWithEmptyUrlSchemeOnlyReturnsNil() {
        XCTAssertNil(RoktPaymentExtension(urlScheme: ""))
    }

    func testInitWithBothEmptyReturnsNil() {
        XCTAssertNil(RoktPaymentExtension(applePayMerchantId: "", urlScheme: ""))
    }

    // MARK: - Apple Pay only

    func testInitWithApplePayOnly() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")
        XCTAssertNotNil(ext)
        XCTAssertEqual(ext?.supportedMethods, ["apple_pay", "card"])
    }

    func testInitWithApplePayAndCustomCountryCode() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test", countryCode: "AU")
        XCTAssertNotNil(ext)
    }

    // MARK: - Afterpay only

    func testInitWithAfterpayOnly() {
        let ext = RoktPaymentExtension(
            urlScheme: "myapp",
            bundle: makeBundle(withSchemes: ["myapp"])
        )
        XCTAssertNotNil(ext)
        XCTAssertEqual(ext?.supportedMethods, ["afterpay_clearpay"])
    }

    // MARK: - Both

    func testInitWithBothMethods() {
        let ext = RoktPaymentExtension(
            applePayMerchantId: "merchant.test",
            urlScheme: "myapp",
            bundle: makeBundle(withSchemes: ["myapp"])
        )
        XCTAssertNotNil(ext)
        XCTAssertEqual(ext?.supportedMethods, ["apple_pay", "card", "afterpay_clearpay"])
    }

    // MARK: - Protocol properties

    func testProtocolProperties() {
        let ext = RoktPaymentExtension(
            applePayMerchantId: "merchant.test",
            urlScheme: "myapp",
            bundle: makeBundle(withSchemes: ["myapp"])
        )!
        XCTAssertEqual(ext.id, "rokt-payment-extension")
        XCTAssertEqual(ext.extensionDescription, "Rokt Payment Extension")
    }

    // MARK: - onRegister / onUnregister

    func testOnRegisterWithoutStripeKeyReturnsFalse() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        XCTAssertFalse(ext.onRegister(parameters: [:]))
    }

    func testOnRegisterWithEmptyStripeKeyReturnsFalse() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        XCTAssertFalse(ext.onRegister(parameters: ["stripeKey": ""]))
    }

    func testOnRegisterWithValidKeyReturnsTrue() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        XCTAssertTrue(ext.onRegister(parameters: ["stripeKey": "pk_test_123"]))
    }

    func testOnUnregisterNilsManager() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        XCTAssertTrue(ext.onRegister(parameters: ["stripeKey": "pk_test_123"]))
        ext.onUnregister()
        XCTAssertTrue(ext.onRegister(parameters: ["stripeKey": "pk_test_456"]))
    }

    // MARK: - presentPaymentSheet error paths

    func testApplePayNotConfiguredRejectsTap() {
        let ext = RoktPaymentExtension(
            urlScheme: "myapp",
            bundle: makeBundle(withSchemes: ["myapp"])
        )!
        ext.onRegister(parameters: ["stripeKey": "pk_test_123"])

        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .applePay,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, done in
                XCTFail("preparePayment should not be called when Apple Pay is not configured")
                done(nil, nil)
            },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertTrue(result.errorMessage?.contains("Apple Pay not configured") ?? false)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    func testAfterpayNotConfiguredRejectsTap() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        ext.onRegister(parameters: ["stripeKey": "pk_test_123"])

        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let context = PaymentContext(
            billingAddress: ContactAddress(name: "Test", email: "test@example.com")
        )
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .afterpay,
            context: context,
            from: UIViewController(),
            preparePayment: { _, done in
                XCTFail("preparePayment should not be called when Afterpay is not configured")
                done(nil, nil)
            },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertTrue(result.errorMessage?.contains("Provide a urlScheme") ?? false)
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    func testPaypalIsRejectedAsUnsupported() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        let item = PaymentItem(id: "item-1", name: "Widget", amount: 10.00, currency: "USD")
        let expect = expectation(description: "completion")

        ext.presentPaymentSheet(
            item: item,
            method: .paypal,
            context: PaymentContext(),
            from: UIViewController(),
            preparePayment: { _, done in
                XCTFail("preparePayment should not be called for unsupported methods")
                done(nil, nil)
            },
            completion: { result in
                XCTAssertEqual(result.outcome, .failed)
                XCTAssertEqual(result.errorMessage, "Unsupported payment method: paypal")
                expect.fulfill()
            }
        )

        waitForExpectations(timeout: 1)
    }

    // MARK: - Scheme validation helpers

    func testIsValidBareSchemeAcceptsBareScheme() {
        XCTAssertTrue(RoktPaymentExtension.isValidBareScheme("myapp"))
        XCTAssertTrue(RoktPaymentExtension.isValidBareScheme("com.partner.app"))
    }

    func testIsValidBareSchemeRejectsEmbeddedURL() {
        XCTAssertFalse(RoktPaymentExtension.isValidBareScheme(""))
        XCTAssertFalse(RoktPaymentExtension.isValidBareScheme("myapp://stripe-redirect"))
        XCTAssertFalse(RoktPaymentExtension.isValidBareScheme("myapp/something"))
    }

    func testIsSchemeRegisteredMatchesCaseInsensitive() {
        let b = makeBundle(withSchemes: ["MyApp"])
        XCTAssertTrue(RoktPaymentExtension.isSchemeRegistered("myapp", in: b))
        XCTAssertTrue(RoktPaymentExtension.isSchemeRegistered("MYAPP", in: b))
    }

    func testIsSchemeRegisteredReturnsFalseWhenMissing() {
        XCTAssertFalse(
            RoktPaymentExtension.isSchemeRegistered("myapp", in: makeBundle(withSchemes: ["other"]))
        )
        XCTAssertFalse(
            RoktPaymentExtension.isSchemeRegistered("myapp", in: makeBundleWithoutSchemes())
        )
    }

    // MARK: - handleURLCallback

    func testHandleURLCallbackApplePayOnlyAlwaysReturnsFalse() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        XCTAssertFalse(ext.handleURLCallback(with: URL(string: "myapp://rokt-payment-return")!))
        XCTAssertFalse(ext.handleURLCallback(with: URL(string: "anything://anything")!))
    }

    func testHandleURLCallbackRejectsWrongScheme() {
        let ext = RoktPaymentExtension(
            urlScheme: "myapp",
            bundle: makeBundle(withSchemes: ["myapp"])
        )!
        let url = URL(string: "other://rokt-payment-return")!
        XCTAssertFalse(ext.handleURLCallback(with: url))
    }

    func testHandleURLCallbackRejectsWrongHost() {
        let ext = RoktPaymentExtension(
            urlScheme: "myapp",
            bundle: makeBundle(withSchemes: ["myapp"])
        )!
        let url = URL(string: "myapp://stripe-redirect")!
        XCTAssertFalse(ext.handleURLCallback(with: url))
    }

    func testHandleURLCallbackReturnsFalseForUnrelatedURL() {
        let ext = RoktPaymentExtension(applePayMerchantId: "merchant.test")!
        let url = URL(string: "myapp://unrelated-callback")!
        XCTAssertFalse(ext.handleURLCallback(with: url))
    }
}
