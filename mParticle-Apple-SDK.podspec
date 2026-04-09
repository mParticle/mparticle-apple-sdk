Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-SDK"
    s.version          = "8.44.4"
    s.summary          = "Swift umbrella sources for mParticle Apple SDK (same paths as SwiftPM product `mParticle-Apple-SDK`)."

    s.description      = <<-DESC
                         Swift-only pod packaging `MParticle/Sources/mParticle_Apple_SDK` (exports + Rokt helpers).
                         Depends on `mParticle-Apple-SDK-ObjC` and `RoktContracts`. Intended to be versioned and tagged with the main SDK.
                         DESC

    s.homepage          = "https://www.mparticle.com"
    s.license           = { :type => 'Apache 2.0', :file => 'LICENSE'}
    s.author            = { "mParticle" => "support@mparticle.com" }
    s.source            = { :git => "https://github.com/mParticle/mparticle-apple-sdk.git", :tag => "v" + s.version.to_s }
    s.documentation_url = "https://docs.mparticle.com/developers/sdk/ios/"
    s.social_media_url  = "https://twitter.com/mparticle"
    s.requires_arc      = true
    s.module_name       = 'mParticle_Apple_SDK'
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.swift_versions = ["5.0"]

    s.source_files = 'MParticle/Sources/mParticle_Apple_SDK/**/*.swift'
    s.dependency 'mParticle-Apple-SDK-ObjC', s.version.to_s
    s.dependency 'RoktContracts', '~> 0.1'
end
