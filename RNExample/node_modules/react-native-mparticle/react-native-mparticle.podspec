require 'json'

new_arch_enabled = ENV['RCT_NEW_ARCH_ENABLED'] == '1'
ios_platform = new_arch_enabled ? '11.0' : '9.0'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']

  s.author            = { "mParticle" => "support@mparticle.com" }

  s.homepage     = package['homepage']
  s.license      = package['license']
  s.platforms = { :ios => ios_platform, :tvos => "9.2" }

  s.source       = { :git => "https://github.com/mParticle/react-native-mparticle.git", :tag => "#{s.version}" }
  s.source_files  = "ios/**/*.{h,m}"
  
  if defined?(install_modules_dependencies()) != nil
    install_modules_dependencies(s);
  else
    s.dependency 'React'
  end
    s.dependency 'mParticle-Apple-SDK', '~> 8.0'
end
