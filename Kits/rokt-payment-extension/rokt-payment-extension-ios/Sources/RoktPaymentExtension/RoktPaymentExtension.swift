import Foundation
import os.log
import PassKit
import RoktContracts
import StripeApplePay
import UIKit

/// Rokt payment extension backed by Stripe.
///
/// Currently supports Apple Pay and Afterpay/Clearpay via Stripe SDKs.
/// Partners provide what they want to support at init time:
/// - `applePayMerchantId` only  → Apple Pay (and card via Apple Pay sheet)
/// - `urlScheme` only            → Afterpay
/// - Both                        → all three methods
///
/// Returns `nil` if neither `applePayMerchantId` nor `urlScheme` is provided,
/// or if the supplied `urlScheme` is not registered under `CFBundleURLSchemes`
/// in the host app's `Info.plist`.
public class RoktPaymentExtension: PaymentExtension {

    // MARK: - PaymentExtension Protocol Properties

    public let id: String = "rokt-payment-extension"
    public let extensionDescription: String = "Rokt Payment Extension"

    /// Payment methods this extension supports, determined by which parameters
    /// were provided at initialization. Apple Pay / card require
    /// `applePayMerchantId`; Afterpay requires `urlScheme`.
    public var supportedMethods: [String] {
        var methods: [String] = []
        if let merchantId, !merchantId.isEmpty {
            methods.append(PaymentMethodType.applePay.wireValue)
            methods.append(PaymentMethodType.card.wireValue)
        }
        if let urlScheme, !urlScheme.isEmpty {
            methods.append(PaymentMethodType.afterpay.wireValue)
        }
        return methods
    }

    // MARK: - Private Properties

    private let merchantId: String?
    private let countryCode: String
    private let urlScheme: String?

    private var stripeApplePayManager: StripeApplePayManager?
    private var stripeAfterpayManager: StripeAfterpayManager?

    static let returnHost = "rokt-payment-return"

    // MARK: - Initialization

    /// Initialize the Rokt payment extension.
    ///
    /// Supply `applePayMerchantId` to enable Apple Pay / card support.
    /// Supply `urlScheme` to enable Afterpay (redirect-based). At least one of
    /// the two must be provided — otherwise the initializer returns `nil`.
    ///
    /// When `urlScheme` is provided, the SDK builds the full redirect URL
    /// (`<scheme>://rokt-payment-return`) internally and verifies the scheme
    /// is registered under `CFBundleURLSchemes` in `Info.plist`.
    ///
    /// - Parameters:
    ///   - applePayMerchantId: Apple Pay merchant identifier. Omit to disable Apple Pay.
    ///   - countryCode: ISO 3166-1 alpha-2 country code for the payment (default: "US").
    ///     Applies only to Apple Pay.
    ///   - urlScheme: Bare custom URL scheme (e.g. `"com.partner.app"`) for redirect-based
    ///     payment methods like Afterpay. The scheme must also be registered under
    ///     `CFBundleURLSchemes` in the host app's `Info.plist`. Omit to disable Afterpay.
    /// - Returns: `nil` if both `applePayMerchantId` and `urlScheme` are omitted or empty,
    ///   or if `urlScheme` is provided but not registered in `Info.plist`.
    public convenience init?(
        applePayMerchantId: String? = nil,
        countryCode: String = "US",
        urlScheme: String? = nil
    ) {
        self.init(
            applePayMerchantId: applePayMerchantId,
            countryCode: countryCode,
            urlScheme: urlScheme,
            bundle: .main
        )
    }

    /// Internal init used by tests to inject a `Bundle` whose `Info.plist`
    /// contains a controlled `CFBundleURLTypes` entry.
    internal init?(
        applePayMerchantId: String? = nil,
        countryCode: String = "US",
        urlScheme: String? = nil,
        bundle: Bundle
    ) {
        let hasApplePay = !(applePayMerchantId?.isEmpty ?? true)
        let hasAfterpay = !(urlScheme?.isEmpty ?? true)
        guard hasApplePay || hasAfterpay else { return nil }

        if hasAfterpay, let scheme = urlScheme {
            guard Self.isValidBareScheme(scheme),
                  Self.isSchemeRegistered(scheme, in: bundle) else {
                Self.reportInvalidScheme(scheme)
                return nil
            }
        }

        self.merchantId = applePayMerchantId
        self.countryCode = countryCode
        self.urlScheme = hasAfterpay ? urlScheme : nil
    }

    // MARK: - PaymentExtension Protocol Implementation

    @discardableResult
    public func onRegister(parameters: [String: String]) -> Bool {
        guard let stripeKey = parameters["stripeKey"], !stripeKey.isEmpty else {
            return false
        }

        let apiClient = STPAPIClient(publishableKey: stripeKey)

        if let merchantId, !merchantId.isEmpty {
            stripeApplePayManager = StripeApplePayManager(
                apiClient: apiClient,
                merchantId: merchantId,
                countryCode: countryCode
            )
        }

        if let urlScheme, !urlScheme.isEmpty {
            let returnURL = "\(urlScheme)://\(Self.returnHost)"
            stripeAfterpayManager = StripeAfterpayManager(
                apiClient: apiClient,
                returnURL: returnURL
            )
        }

        return true
    }

    public func onUnregister() {
        stripeApplePayManager = nil
        stripeAfterpayManager = nil
    }

    public func presentPaymentSheet(
        item: PaymentItem,
        method: PaymentMethodType,
        context: PaymentContext,
        from viewController: UIViewController,
        preparePayment: @escaping (
            _ address: ContactAddress,
            _ completion: @escaping (PaymentPreparation?, Error?) -> Void
        ) -> Void,
        completion: @escaping (PaymentSheetResult) -> Void
    ) {
        switch method {
        case .applePay, .card:
            guard let stripeApplePayManager else {
                completion(.failed(error: "Apple Pay not configured. Provide applePayMerchantId at init."))
                return
            }
            stripeApplePayManager.presentPayment(
                item: item,
                from: viewController,
                preparePayment: preparePayment,
                completion: completion
            )

        case .afterpay:
            guard let stripeAfterpayManager else {
                completion(.failed(error: "Afterpay not configured. Provide a urlScheme at init."))
                return
            }
            stripeAfterpayManager.presentPayment(
                item: item,
                context: context,
                from: viewController,
                preparePayment: preparePayment,
                completion: completion
            )

        case .paypal:
            // PayPal is defined in RoktContracts 2.x but not yet implemented here.
            // Handled explicitly (rather than falling through `@unknown default`) so the
            // compiler flags any future enum additions instead of silently accepting them.
            completion(.failed(error: "Unsupported payment method: \(method.wireValue)"))

        @unknown default:
            completion(.failed(error: "Unsupported payment method: \(method.wireValue)"))
        }
    }

    /// Forwards a redirect URL to Stripe so it can complete in-flight redirect-based
    /// flows (e.g. Afterpay). Only URLs whose scheme matches the configured
    /// `urlScheme` and whose host equals `rokt-payment-return` are forwarded —
    /// anything else returns `false`, leaving partner-owned URLs untouched.
    public func handleURLCallback(with url: URL) -> Bool {
        guard let urlScheme,
              url.scheme?.lowercased() == urlScheme.lowercased(),
              url.host == Self.returnHost else {
            return false
        }
        return StripeAPI.handleURLCallback(with: url)
    }

    // MARK: - Scheme Validation Helpers

    /// Returns `true` when the scheme is non-empty and contains no path separator
    /// characters — guarding against partners accidentally passing a full URL
    /// (e.g. `"myapp://stripe-redirect"`) or a path fragment.
    static func isValidBareScheme(_ scheme: String) -> Bool {
        !scheme.isEmpty && !scheme.contains("://") && !scheme.contains("/")
    }

    /// Returns `true` when `scheme` appears (case-insensitively) under any
    /// `CFBundleURLSchemes` array inside `CFBundleURLTypes` in the bundle's
    /// `Info.plist`.
    static func isSchemeRegistered(_ scheme: String, in bundle: Bundle) -> Bool {
        let target = scheme.lowercased()
        guard let urlTypes = bundle.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return false
        }
        for entry in urlTypes {
            if let schemes = entry["CFBundleURLSchemes"] as? [String],
               schemes.map({ $0.lowercased() }).contains(target) {
                return true
            }
        }
        return false
    }

    /// Reports an invalid / unregistered scheme.
    /// In DEBUG builds the failure is surfaced via `assertionFailure` so the
    /// integrating engineer sees it immediately. In release builds the message
    /// is logged via `os_log` at `.error` and the initializer returns `nil`,
    /// making the failure visible through the partner's `guard let ext = ...`.
    private static func reportInvalidScheme(_ scheme: String) {
        let message = """
        Rokt: URL scheme '\(scheme)' is not registered under CFBundleURLSchemes in Info.plist, \
        or contains invalid characters. Register it like this:
          <key>CFBundleURLTypes</key>
          <array>
            <dict>
              <key>CFBundleURLSchemes</key>
              <array><string>\(scheme)</string></array>
            </dict>
          </array>
        """
        #if DEBUG
        assertionFailure(message)
        #else
        os_log("%{public}s", log: .default, type: .error, message)
        #endif
    }
}
