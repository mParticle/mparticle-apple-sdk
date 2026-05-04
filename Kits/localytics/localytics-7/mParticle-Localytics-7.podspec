Pod::Spec.new do |s|
    s.name             = "mParticle-Localytics-7"
    s.module_name      = 'mParticle_Localytics'
    s.version          = "9.1.0"
    s.summary          = "Localytics integration for mParticle"
    s.description      = <<-DESC
                       This is the Localytics integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-localytics-7.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Localytics/**/*.{h,m}'
    s.ios.resource_bundles  = { 'mParticle-Localytics-7-Privacy' => ['Sources/mParticle-Localytics/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'Localytics', '~> 7.0'
end
