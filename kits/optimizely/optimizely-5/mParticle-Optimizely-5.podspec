Pod::Spec.new do |s|
    s.name             = "mParticle-Optimizely-5"
    s.version          = "9.0.0"
    s.summary          = "Optimizely integration for mParticle"
    s.description      = <<-DESC
                       This is the Optimizely integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-optimizely-5.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-Optimizely/**/*.{h,m,mm}'
    s.resource_bundles  = { 'mParticle-Optimizely-5-Privacy' => ['Sources/mParticle-Optimizely/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.dependency 'OptimizelySwiftSDK', '~> 5.0'
end
