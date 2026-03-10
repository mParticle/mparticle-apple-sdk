Pod::Spec.new do |s|
    s.name             = "mParticle-Radar-3"
    s.version          = "8.2.0"
    s.summary          = "Radar integration for mParticle"
    s.description      = <<-DESC
                       This is the Radar integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'kits/radar/radar-3/Sources/mParticle-Radar/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Radar-3-Privacy' => ['kits/radar/radar-3/Sources/mParticle-Radar/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'RadarSDK', '~> 3.25'
end
