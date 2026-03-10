Pod::Spec.new do |s|
    s.name             = "mParticle-OneTrust"
    s.version          = "8.4.0"
    s.summary          = "OneTrust integration for mParticle"
    s.description      = <<-DESC
                       This is the OneTrust integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'kits/onetrust/onetrust/Sources/mParticle-OneTrust/**/*.{h,m,mm}'
    s.resource_bundles  = { 'mParticle-OneTrust-Privacy' => ['kits/onetrust/onetrust/Sources/mParticle-OneTrust/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    s.ios.dependency 'OTPublishersHeadlessSDK'
    s.tvos.dependency 'OTPublishersHeadlessSDKtvOS'
end
