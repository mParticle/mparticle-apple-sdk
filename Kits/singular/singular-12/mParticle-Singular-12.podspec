Pod::Spec.new do |s|
    s.name             = "mParticle-Singular-12"
    s.module_name      = 'mParticle_Singular'
    s.version          = "9.2.0"
    s.summary          = "Singular integration for mParticle"
    s.description      = <<-DESC
                       This is the Singular integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-singular-12.git", :tag => "v" + s.version.to_s }
    s.static_framework = true
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Singular/**/*.{h,m}'
    s.ios.resource_bundles  = { 'mParticle-Singular-12-Privacy' => ['Sources/mParticle-Singular/PrivacyInfo.xcprivacy'] }
    s.ios.frameworks        = 'StoreKit'
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'Singular-SDK', '~> 12.4'
end
