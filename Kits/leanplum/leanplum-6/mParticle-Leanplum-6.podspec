Pod::Spec.new do |s|
    s.name             = "mParticle-Leanplum-6"
    s.module_name      = 'mParticle_Leanplum'
    s.version          = "9.0.0"
    s.summary          = "Leanplum integration for mParticle"
    s.description      = <<-DESC
                       This is the Leanplum integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Leanplum/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Leanplum-6-Privacy' => ['Sources/mParticle-Leanplum/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'Leanplum-iOS-SDK', '~> 6.0'
end
