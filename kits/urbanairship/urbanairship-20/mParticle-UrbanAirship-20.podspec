Pod::Spec.new do |s|
    s.name             = "mParticle-UrbanAirship-20"
    s.version          = "9.0.0"
    s.summary          = "Airship integration for mParticle"
    s.description      = <<-DESC
                       This is the Airship (Urban Airship) integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle-integrations/mparticle-apple-integration-urbanairship-20.git", :tag => "v" + s.version.to_s }
    s.ios.deployment_target = "16.0"
    s.ios.source_files      = 'Sources/mParticle-UrbanAirship/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-UrbanAirship-20-Privacy' => ['Sources/mParticle-UrbanAirship/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 8.22'
    s.ios.dependency 'AirshipObjectiveC', '~> 20.0'
end
