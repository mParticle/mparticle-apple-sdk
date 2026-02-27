Pod::Spec.new do |s|
    s.name             = "mParticle-Apptentive"
    s.version          = "8.3.0"
    s.summary          = "Apptentive integration for mParticle"
    s.description      = <<-DESC
                       This is the Apptentive integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-apptentive.git", :tag => "v" +s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"
    s.swift_version = "5.5"
    s.ios.deployment_target = "13.0"
    s.ios.source_files      = 'mParticle-Apptentive/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Apptentive-Privacy' => ['mParticle-Apptentive/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'ApptentiveKit', '~> 6.6'
end
