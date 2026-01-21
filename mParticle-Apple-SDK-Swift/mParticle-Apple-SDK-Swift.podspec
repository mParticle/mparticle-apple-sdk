Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-SDK-Swift"
    s.version          = "8.40.0"
    s.summary          = "mParticle Apple SDK Swift components."
    
    s.description      = <<-DESC
                         Swift components for the mParticle Apple SDK.
                         This pod contains Swift-only code that is used by the main mParticle-Apple-SDK.
                         DESC
    
    s.homepage          = "https://www.mparticle.com"
    s.license           = { :type => 'Apache 2.0', :file => '../LICENSE'}
    s.author            = { "mParticle" => "support@mparticle.com" }
    s.source            = { :git => "https://github.com/mParticle/mparticle-apple-sdk.git", :tag => "v" + s.version.to_s }
    s.documentation_url = "https://docs.mparticle.com/developers/sdk/ios/"
    s.requires_arc      = true
    s.module_name       = 'mParticle_Apple_SDK_Swift'
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.swift_versions = ["5.0"]
    
    s.source_files = 'Sources/**/*.swift'
end
