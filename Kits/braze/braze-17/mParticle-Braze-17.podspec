Pod::Spec.new do |s|
    s.name             = "mParticle-Braze-17"
    s.module_name      = 'mParticle_Braze'
    s.version          = "9.4.1"
    s.summary          = "Braze integration for mParticle"
    s.description      = <<-DESC
                       This is the Braze integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-braze-17.git", :tag => "v" + s.version.to_s }
    s.static_framework = true
    s.swift_version = "5.5"
    s.ios.deployment_target  = "15.0"
    s.tvos.deployment_target = "15.0"
    s.source_files      = 'Sources/mParticle-Braze/**/*.{h,m}'
    s.resource_bundles  = { 'mParticle-Braze-17-Privacy' => ['Sources/mParticle-Braze/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.dependency 'BrazeKit', '~> 17.0'
    s.ios.dependency 'BrazeUI', '~> 17.0'
end
