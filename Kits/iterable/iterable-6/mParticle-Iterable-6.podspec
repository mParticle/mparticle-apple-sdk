Pod::Spec.new do |s|
    s.name             = "mParticle-Iterable-6"
    s.module_name      = 'mParticle_Iterable'
    s.version          = "8.8.0"
    s.summary          = "Iterable integration for mParticle"
    s.description      = <<-DESC
                       This is the Iterable integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Iterable/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Iterable-6-Privacy' => ['Sources/mParticle-Iterable/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    s.ios.dependency 'Iterable-iOS-SDK', '~> 6.5'
end
