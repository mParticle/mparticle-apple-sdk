Pod::Spec.new do |s|
    s.name             = "mParticle-ComScore-6"
    s.module_name      = 'mParticle_ComScore'
    s.version          = "8.1.0"
    s.summary          = "comScore integration for mParticle"
    s.description      = <<-DESC
                       This is the comScore integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-ComScore/**/*.{h,m}'
    s.resource_bundles  = { 'mParticle-ComScore-6-Privacy' => ['Sources/mParticle-ComScore/PrivacyInfo.xcprivacy'] }
    s.frameworks        = 'SystemConfiguration'
    s.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.dependency 'ComScore', '~> 6.12'
end
