# CI stub podspec for mParticle-Apple-Media-SDK.
# The real package is at https://github.com/mparticle/mparticle-apple-media-sdk.
# This stub satisfies Adobe-5's transitive dependency on mParticle-Apple-Media-SDK during
# pod lib lint. The CDN version depends on mParticle-Apple-SDK ~> 8.37, which conflicts with
# the local SDK bumped to 9.0.0 for CI. This stub is supplied via --include-podspecs so that
# dependency resolution succeeds.
# TODO: Remove once mParticle-Apple-SDK v9.0 and mParticle-Apple-Media-SDK v9.0 are both
# published to CocoaPods CDN -- at that point all dependencies resolve without local overrides.
Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-Media-SDK"
    s.version          = "9.0.0"
    s.summary          = "mParticle Media SDK (CI stub)"
    s.description      = "CI stub podspec. See mParticle-Apple-Media-SDK.podspec comment."
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-media-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.source_files     = 'mParticle-Apple-SDK/Include/mParticle.h'

    s.subspec 'mParticleMedia' do |media|
        media.source_files = 'mParticle-Apple-SDK/Include/mParticle.h'
        media.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    end
end
