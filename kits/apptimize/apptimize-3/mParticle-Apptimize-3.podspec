Pod::Spec.new do |s|
    s.name             = "mParticle-Apptimize-3"
    s.version          = "8.2.0"
    s.summary          = "Apptimize integration for mParticle"
    s.description      = <<-DESC
                       This is the Apptimize integration for mParticle.
                       DESC
    s.homepage         = "https://www.mparticle.com"
    s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
    s.author           = { "mParticle" => "support@mparticle.com" }
    s.source           = { :git => "https://github.com/mparticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.ios.deployment_target = "15.6"
    s.ios.source_files      = 'Sources/mParticle-Apptimize/**/*.{h,m,mm}'
    s.ios.resource_bundles  = { 'mParticle-Apptimize-3-Privacy' => ['Sources/mParticle-Apptimize/PrivacyInfo.xcprivacy'] }
    s.ios.dependency 'mParticle-Apple-SDK/mParticle', '~> 9.0'
    s.ios.dependency 'Apptimize-Swift', '~> 3.5'
end
