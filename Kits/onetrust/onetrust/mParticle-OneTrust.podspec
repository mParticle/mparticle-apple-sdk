Pod::Spec.new do |s|
    s.name             = "mParticle-OneTrust"
    s.version          = "9.0.0"
    s.summary          = "OneTrust integration for mParticle"
    s.description      = <<-DESC
                       This is the OneTrust integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-OneTrust/**/*.{h,m}'
    s.resource_bundles  = { 'mParticle-OneTrust-Privacy' => ['Sources/mParticle-OneTrust/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'OneTrust-CMP-XCFramework'
    s.tvos.dependency 'OneTrust-CMP-tvOS-XCFramework'
end
