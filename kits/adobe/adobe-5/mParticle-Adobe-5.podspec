Pod::Spec.new do |s|
    s.name             = "mParticle-Adobe-5"
    s.version          = "8.2.4"
    s.summary          = "Adobe integration for mParticle"
    s.description      = <<-DESC
                       This is the Adobe integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"

    s.subspec 'Core' do |core|
        core.source_files      = 'kits/adobe/adobe-5/Sources/mParticle-Adobe/**/*.{h,m,mm}'
        core.resource_bundles  = { 'mParticle-Adobe-5-Privacy' => ['kits/adobe/adobe-5/Sources/mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        core.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    end

    s.subspec 'Media' do |media|
        media.source_files      = 'kits/adobe/adobe-5/Sources/mParticle-AdobeMedia/**/*.{h,m,mm}'
        media.resource_bundles  = { 'mParticle-Adobe-5-Media-Privacy' => ['kits/adobe/adobe-5/Sources/mParticle-AdobeMedia/PrivacyInfo.xcprivacy'] }
        media.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
        media.dependency 'mParticle-Apple-Media-SDK'
        media.dependency 'AEPCore', '~> 5.0'
        media.dependency 'AEPUserProfile', '~> 5.0'
        media.dependency 'AEPAnalytics', '~> 5.0'
        media.dependency 'AEPMedia', '~> 5.0'
    end
end
