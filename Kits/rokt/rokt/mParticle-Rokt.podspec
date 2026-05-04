Pod::Spec.new do |s|
    s.name             = "mParticle-Rokt"
    s.version          = "9.1.0"
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
    s.ios.source_files      = 'Sources/mParticle-Rokt/**/*.{h,m}', 'Sources/mParticle-Rokt-Swift/**/*.swift'
    s.ios.resource_bundles  = { 'mParticle-Rokt-Privacy' => ['Sources/mParticle-Rokt/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'RoktContracts', '~> 2.0'
    s.ios.dependency 'Rokt-Widget', '~> 5.1'
end
