Pod::Spec.new do |s|
    s.name             = "mParticle-Kochava-9"
    s.version          = "8.7.0"
    s.summary          = "Kochava integration for mParticle"
    s.description      = <<-DESC
                       This is the Kochava integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target  = "15.6"
    s.tvos.deployment_target = "15.6"
    s.source_files      = 'Sources/mParticle-Kochava/**/*.{h,m,mm}'
    s.resource_bundles  = { 'mParticle-Kochava-9-Privacy' => ['Sources/mParticle-Kochava/PrivacyInfo.xcprivacy'] }
    s.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    s.dependency 'KochavaNetworking', '~> 9.0'
    s.dependency 'KochavaMeasurement', '~> 9.0'
    s.dependency 'KochavaTracking', '~> 9.0'
end
