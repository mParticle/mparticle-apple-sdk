Pod::Spec.new do |s|
    s.name             = "MyModules-A"
    s.version          = "1.0.0"
    s.summary          = "MyModules A - Objective-C module"
    
    s.description      = <<-DESC
                         Objective-C module that uses BObjC bridge to access Swift logic from module B.
                         This module demonstrates how to use Swift modules from Objective-C code.
                         DESC
    
    s.homepage         = "https://github.com/example/MyModules"
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { "Your Name" => "your.email@example.com" }
    s.source           = { :git => "https://github.com/example/MyModules.git", :tag => s.version.to_s }
    s.requires_arc     = true
    s.module_name      = 'A'
    s.ios.deployment_target  = "14.0"
    s.macos.deployment_target = "11.0"
    
    # Public headers are in Sources/A/include/
    s.public_header_files = 'Sources/A/include/*.h'
    # Include all source files of module A
    s.source_files = 'Sources/A/**/*.{h,m}'
    
    # Dependency on BObjC (which in turn depends on B)
    s.dependency 'MyModules-BObjC', "~> #{s.version}"
end

