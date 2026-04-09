Pod::Spec.new do |s|
    s.name             = "mParticle-FirebaseGA4-11"
    s.module_name      = 'mParticle_FirebaseGA4'
    s.version          = "9.0.0"
    s.summary          = "Firebase Analytics (GA4) integration for mParticle"
    s.description      = <<-DESC
                       This is the Firebase Analytics (GA4) integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.static_framework = true
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-FirebaseGA4/**/*.{h,m}'
    s.resource_bundles  = { 'mParticle-Google-Analytics-Firebase-GA4-11-Privacy' => ['Sources/mParticle-FirebaseGA4/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.dependency 'FirebaseAnalytics', '~> 11.0'
end
