Pod::Spec.new do |s|
  s.name = 'RoktSDKPlus'
  s.version = '9.1.0'
  s.summary = 'Rokt SDK+ umbrella: mParticle Apple SDK, mParticle–Rokt kit, and Rokt Payment Extension.'
  s.description = <<-DESC
    Single CocoaPods entry point for the mParticle Apple SDK, the mParticle Rokt integration kit
    (mParticle-Rokt with RoktContracts 2.x), and Rokt Payment Extension (Shoppable Ads).
  DESC
  s.homepage = 'https://github.com/ROKT/rokt-sdk-plus-ios'
  s.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author = { 'ROKT' => 'nativeappsdev@rokt.com' }
  s.source = { :git => 'https://github.com/ROKT/rokt-sdk-plus-ios.git', :tag => 'v' + s.version.to_s }
  s.swift_version = '5.9'
  s.ios.deployment_target = '15.6'
  s.requires_arc = true
  s.source_files = 'Sources/RoktSDKPlus/**/*.swift'
  s.dependency 'mParticle-Rokt', s.version.to_s
  s.dependency 'RoktPaymentExtension', '~> 2.0'
end
