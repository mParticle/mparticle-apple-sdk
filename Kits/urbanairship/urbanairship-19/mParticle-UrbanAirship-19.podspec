Pod::Spec.new do |s|
    s.name             = "mParticle-UrbanAirship-19"
    s.module_name      = 'mParticle_UrbanAirship'
    s.version          = "9.0.0"
    s.summary          = "Airship integration for mParticle"
    s.description      = <<-DESC
                       This is the Airship (Urban Airship) integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-UrbanAirship/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-UrbanAirship-19-Privacy' => ['Sources/mParticle-UrbanAirship/PrivacyInfo.xcprivacy'] }
    s.ios.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) AIRSHIP_COCOAPODS=1' }
    s.ios.dependency 'mParticle-Apple-SDK', '~> 9.0'
    s.ios.dependency 'Airship/ObjectiveC', '~> 19.1'
end
