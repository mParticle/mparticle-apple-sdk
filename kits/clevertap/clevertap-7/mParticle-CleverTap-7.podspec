Pod::Spec.new do |s|
    s.name             = "mParticle-CleverTap-7"
    s.version          = "9.0.0"
    s.summary          = "CleverTap integration for mParticle"
    s.description      = <<-DESC
                       This is the CleverTap integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-clevertap-7.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-CleverTap/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-CleverTap-7-Privacy' => ['Sources/mParticle-CleverTap/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'CleverTap-iOS-SDK', '~> 7.0'
end
