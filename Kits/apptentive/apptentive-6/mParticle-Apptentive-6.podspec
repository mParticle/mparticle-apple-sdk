Pod::Spec.new do |s|
    s.name             = "mParticle-Apptentive-6"
    s.module_name      = 'mParticle_Apptentive'
    s.version          = "8.3.0"
    s.summary          = "Apptentive integration for mParticle"
    s.description      = <<-DESC
                       This is the Apptentive integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Apptentive/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Apptentive-6-Privacy' => ['Sources/mParticle-Apptentive/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'ApptentiveKit', '~> 6.6'
end
