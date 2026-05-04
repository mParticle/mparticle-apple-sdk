Pod::Spec.new do |s|
    s.name             = "mParticle-Rokt"
    s.version          = "9.0.1"
    s.summary          = "Rokt integration for mParticle"
    s.description      = <<-DESC
                       This is the Rokt integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mp-apple-integration-rokt.git", :tag => "v" + s.version.to_s }
    s.swift_version = "5.5"
    s.ios.deployment_target = "15.6"
    s.default_subspec = "Payments"

    s.subspec "Core" do |ss|
        ss.ios.source_files      = 'Sources/mParticle-Rokt/**/*.{h,m}', 'Sources/mParticle-Rokt-Swift/**/*.swift'
        ss.ios.resource_bundles  = { 'mParticle-Rokt-Privacy' => ['Sources/mParticle-Rokt/PrivacyInfo.xcprivacy'] }
        ss.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
        ss.ios.dependency 'RoktContracts', '~> 2.0'
        ss.ios.dependency 'Rokt-Widget', '~> 5.1'
    end

    s.subspec "Payments" do |ss|
        ss.ios.dependency 'mParticle-Rokt/Core', s.version.to_s
        ss.ios.dependency 'RoktPaymentExtension', '~> 2.0'
    end

    s.subspec "No-Payments" do |ss|
        ss.ios.dependency 'mParticle-Rokt/Core', s.version.to_s
    end
end
