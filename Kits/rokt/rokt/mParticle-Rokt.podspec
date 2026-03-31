Pod::Spec.new do |s|
    s.name             = "mParticle-Rokt"
    s.version          = "8.3.3"
    s.summary          = "Rokt integration for mParticle"
    s.description      = <<-DESC
                       This is the Rokt integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.swift_version = "5.5"
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Rokt/**/*.{h,m,mm}', 'Sources/mParticle-Rokt-Swift/**/*.swift'
    s.ios.resource_bundles  = { 'mParticle-Rokt-Privacy' => ['Sources/mParticle-Rokt/PrivacyInfo.xcprivacy'] }
    # Align with monorepo mParticle-Apple-SDK.podspec (8.x). When using `pod :path`, CocoaPods
    # resolves the local SDK; keep a loose constraint so `pod lib lint` and trunk releases stay valid.
    s.ios.dependency 'mParticle-Apple-SDK', '>= 8.0'
    s.ios.dependency 'RoktContracts', '~> 0.1'
    s.ios.dependency 'Rokt-Widget', '~> 5.0'
end
