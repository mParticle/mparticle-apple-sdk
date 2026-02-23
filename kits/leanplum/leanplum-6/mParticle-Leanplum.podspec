Pod::Spec.new do |s|
    s.name             = "mParticle-Leanplum"
    s.version          = "8.5.0"
    s.summary          = "Leanplum integration for mParticle"

    s.description      = <<-DESC
                       This is the Leanplum integration for mParticle.
                       DESC

    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-leanplum.git", :tag => "v" +s.version.to_s }
    s.social_media_url = "https://twitter.com/mparticle"

    s.ios.deployment_target = "9.0"
    s.ios.source_files      = 'mParticle-Leanplum/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Leanplum-Privacy' => ['mParticle-Leanplum/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'Leanplum-iOS-SDK', '~> 6.4'
end
