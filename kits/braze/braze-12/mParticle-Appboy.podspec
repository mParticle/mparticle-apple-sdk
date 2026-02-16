Pod::Spec.new do |s|
    s.name             = "mParticle-Appboy"
    s.version          = "8.13.2"
    s.summary          = "Appboy integration for mParticle"

    s.description      = <<-DESC
                       This is the Appboy integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-appboy.git", :tag => "v" + s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"
    s.static_framework = true
    s.swift_version = '5.3'

    s.ios.deployment_target = "12.0"
    s.ios.source_files      = 'Sources/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Appboy-Privacy' => ['Sources/mParticle-Appboy/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 8.19'
    s.ios.dependency 'BrazeKit', '~> 12.0'
    s.ios.dependency 'BrazeKitCompat', '~> 12.0'
    s.ios.dependency 'BrazeUI', '~> 12.0'
    
    s.tvos.deployment_target = "12.0"
    s.tvos.source_files      = 'Sources/**/*.{h,m,mm}'
    s.tvos.resource_bundles  = { 'mParticle-Appboy-Privacy' => ['Sources/mParticle-Appboy/PrivacyInfo.xcprivacy'] }
    s.tvos.dependency 'mParticle-Apple-SDK', '~> 8.19'
    s.tvos.dependency 'BrazeKit', '~> 12.0'
    s.tvos.dependency 'BrazeKitCompat', '~> 12.0'


end
