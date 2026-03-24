Pod::Spec.new do |s|
    s.name             = "mParticle-Adobe-5"
    s.module_name      = 'mParticle_Adobe'
    s.version          = "8.2.4"
    s.summary          = "Adobe integration for mParticle"
    s.description      = <<-DESC
                       This is the Adobe integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.static_framework = true
    s.swift_version    = '5.0'
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"

    s.default_subspec = 'AdobeMedia'

    s.subspec 'Adobe' do |ss|
        ss.ios.source_files      = 'Sources/mParticle-Adobe/**/*.{h,m,mm}'
        ss.ios.resource_bundles  = { 'mParticle-Adobe-5-Privacy' => ['Sources/mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
        ss.tvos.source_files     = 'Sources/mParticle-Adobe/**/*.{h,m,mm}'
        ss.tvos.resource_bundles = { 'mParticle-Adobe-5-Privacy' => ['Sources/mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        ss.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    end

    s.subspec 'AdobeMedia' do |ss|
        ss.ios.source_files      = 'Sources/mParticle-AdobeMedia/**/*.{h,m,mm}'
        ss.ios.resource_bundles  = { 'mParticle-Adobe-5-Media-Privacy' => ['Sources/mParticle-AdobeMedia/PrivacyInfo.xcprivacy'] }
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
        ss.ios.dependency 'mParticle-Apple-Media-SDK'
        ss.ios.dependency 'AEPCore',        '~> 5.0'
        ss.ios.dependency 'AEPUserProfile', '~> 5.0'
        ss.ios.dependency 'AEPAnalytics',   '~> 5.0'
        ss.ios.dependency 'AEPMedia',       '~> 5.0'
        ss.ios.dependency 'AEPIdentity',    '~> 5.0'
        ss.ios.dependency 'AEPLifecycle',   '~> 5.0'
        ss.ios.dependency 'AEPSignal',      '~> 5.0'
        # AdobeMedia not supported on tvOS; fall back to Adobe source
        ss.tvos.source_files     = 'Sources/mParticle-Adobe/**/*.{h,m,mm}'
        ss.tvos.resource_bundles = { 'mParticle-Adobe-5-Privacy' => ['Sources/mParticle-Adobe/PrivacyInfo.xcprivacy'] }
        ss.tvos.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    end
end
