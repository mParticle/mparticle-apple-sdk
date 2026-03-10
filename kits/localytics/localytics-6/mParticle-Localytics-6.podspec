Pod::Spec.new do |s|
    s.name             = "mParticle-Localytics-6"
    s.version          = "8.2.0"
    s.summary          = "Localytics integration for mParticle"
    s.description      = <<-DESC
                       This is the Localytics integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'kits/localytics/localytics-6/Sources/mParticle-Localytics/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Localytics-6-Privacy' => ['kits/localytics/localytics-6/Sources/mParticle-Localytics/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'Localytics', '~> 6.3'
end
