Pod::Spec.new do |s|
  s.name             = 'RoktPaymentExtension'
  s.version          = '9.2.1'
  s.summary          = 'Payment extension for the Rokt SDK ecosystem (Apple Pay + Afterpay via Stripe).'
  s.swift_version    = '5.9'
  s.description      = <<-DESC
  Payment integration for Rokt Shoppable Ads. Implements the PaymentExtension
  protocol from RoktContracts. Currently supports Apple Pay, card, and
  Afterpay/Clearpay via Stripe; designed to host additional providers over time.
                       DESC
  s.homepage         = 'https://github.com/ROKT/rokt-payment-extension-ios'
  s.license          = { :type => 'Rokt SDK Terms of Use 2.0', :file => 'LICENSE.md' }
  s.author           = { 'ROKT DEV' => 'nativeappsdev@rokt.com' }
  s.source           = { :git => 'https://github.com/ROKT/rokt-payment-extension-ios.git', :tag => 'v' + s.version.to_s }
  s.ios.deployment_target = '15.6'
  s.source_files = 'Sources/RoktPaymentExtension/**/*.swift'
  s.frameworks = 'Foundation', 'PassKit'
  s.dependency 'RoktContracts', '~> 2.0.2'
  s.dependency 'StripeApplePay', '~> 25.0'
  s.dependency 'StripePayments', '~> 25.0'
end
