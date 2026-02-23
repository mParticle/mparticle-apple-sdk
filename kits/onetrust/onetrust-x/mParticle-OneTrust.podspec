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
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-onetrust.git", :tag => "v" + s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    
    s.ios.deployment_target = "11.0"
    s.ios.source_files      = 'mParticle-OneTrust/*.{h,m}'
    s.ios.resource_bundles  = { 'mParticle-OneTrust-Privacy' => ['mParticle-OneTrust/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    #OneTrust's unique version formating makes automatic support up to the next major version no longer possible. Additionally, as a specific version is required in their UI for their SDK to function we do not include a specific version of the 'OneTrust-CMP-XCFramework' here and expect the version to be defined in the client app.
    s.ios.dependency 'OneTrust-CMP-XCFramework'
    
    s.tvos.deployment_target = "11.0"
    s.tvos.source_files      = 'mParticle-OneTrust/*.{h,m}'
    s.tvos.resource_bundles  = { 'mParticle-OneTrust-Privacy' => ['mParticle-OneTrust/PrivacyInfo.xcprivacy'] }
    s.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    #OneTrust's unique version formating makes automatic support up to the next major version no longer possible. Additionally, as a specific version is required in their UI for their SDK to function we do not include a specific version of the 'OneTrust-CMP-XCFramework' here and expect the version to be defined in the client app.
    s.tvos.dependency 'OneTrust-CMP-tvOS-XCFramework'

end
