Pod::Spec.new do |s|
    s.name             = "mParticle-AppsFlyer-6"
    s.version          = "8.4.3"
    s.summary          = "AppsFlyer integration for mParticle"
    s.description      = <<-DESC
                       This is the AppsFlyer integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'kits/appsflyer/appsflyer-6/Sources/mParticle-AppsFlyer/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-AppsFlyer-6-Privacy' => ['kits/appsflyer/appsflyer-6/Sources/mParticle-AppsFlyer/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'AppsFlyerFramework', '~> 6.0'
end
