Pod::Spec.new do |s|
    s.name             = "mParticle-Google-Analytics-Firebase-GA4-11"
    s.version          = "9.0.0"
    s.summary          = "Firebase Analytics (GA4) integration for mParticle"
    s.description      = <<-DESC
                       This is the Firebase Analytics (GA4) integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-google-analytics-firebase-ga4-11.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-FirebaseGA4/**/*.{h,m,mm}'
    s.resource_bundles  = { 'mParticle-Google-Analytics-Firebase-GA4-11-Privacy' => ['Sources/mParticle-FirebaseGA4/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.dependency 'FirebaseAnalytics', '~> 11.0'
end
