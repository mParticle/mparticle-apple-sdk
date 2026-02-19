Pod::Spec.new do |s|
    s.name             = "mParticle-AppsFlyer"
    s.version          = "8.4.2"
    s.summary          = "AppsFlyer integration for mParticle"

    s.description      = <<-DESC
                       This is the AppsFlyer integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-appsflyer.git", :tag => "v" + s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"
    s.swift_versions = ["5.3"]
    
    s.static_framework = true

    s.ios.deployment_target = "12.0"
    s.ios.source_files      = 'Sources/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-AppsFlyer-Privacy' => ['Sources/mParticle-AppsFlyer/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.19'
    s.ios.dependency 'AppsFlyerFramework', '~> 6.16'
end
