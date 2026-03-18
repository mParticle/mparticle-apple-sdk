Pod::Spec.new do |s|
    s.name             = "mParticle-Braze-12"
    s.version          = "8.14.1"
    s.summary          = "Braze integration for mParticle"
    s.description      = <<-DESC
                       This is the Braze integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.swift_version = "5.5"
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-Braze/**/*.{h,m,mm}'
    s.resource_bundles  = { 'mParticle-Braze-12-Privacy' => ['Sources/mParticle-Braze/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    s.dependency 'BrazeKit', '~> 12.0'
    s.dependency 'BrazeKitCompat', '~> 12.0'
    s.ios.dependency 'BrazeUI', '~> 12.0'
end