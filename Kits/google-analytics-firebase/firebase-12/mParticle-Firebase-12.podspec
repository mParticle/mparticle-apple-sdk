Pod::Spec.new do |s|
    s.name             = "mParticle-Firebase-12"
    s.module_name      = 'mParticle_Firebase'
    s.version          = "8.6.1"
    s.summary          = "Firebase Analytics integration for mParticle"
    s.description      = <<-DESC
                       This is the Firebase Analytics integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.static_framework = true
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Firebase/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Google-Analytics-Firebase-12-Privacy' => ['Sources/mParticle-Firebase/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'FirebaseAnalytics', '~> 12.0'
end
