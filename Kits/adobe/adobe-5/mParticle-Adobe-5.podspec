Pod::Spec.new do |s|
    s.name             = "mParticle-Adobe-5"
    s.module_name      = 'mParticle_Adobe'
    s.version          = "8.2.4"
    s.summary          = "Adobe integration for mParticle"
    s.description      = <<-DESC
                       This is the Adobe integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.static_framework = true
    s.swift_version    = '5.0'
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-Adobe/**/*.{h,m}'
    s.resource_bundles  = { 'mParticle-Adobe-5-Privacy' => ['Sources/mParticle-Adobe/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK', '~> 9.0'
end
