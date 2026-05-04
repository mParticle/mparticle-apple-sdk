Pod::Spec.new do |s|
    s.name             = "mParticle-Adjust-5"
    s.module_name      = 'mParticle_Adjust'
    s.version          = "9.1.0"
    s.summary          = "Adjust integration for mParticle"
    s.description      = <<-DESC
                       This is the Adjust integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-adjust-5.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-Adjust/**/*.{h,m}'
    s.resource_bundles  = { 'mParticle-Adjust-5-Privacy' => ['Sources/mParticle-Adjust/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.dependency 'Adjust', '~> 5.0'
end
