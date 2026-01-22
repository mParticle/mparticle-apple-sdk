Pod::Spec.new do |s|
    s.name             = "MyModules-BObjC"
    s.version          = "1.0.0"
    s.summary          = "MyModules BObjC - Swift bridge for Objective-C"
    
    s.description      = <<-DESC
                         Swift bridge module that exports Swift API in Objective-C-compatible way.
                         This module provides @objc-friendly API for accessing Swift-only module B.
                         DESC
    
    s.homepage         = "https://github.com/example/MyModules"
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { "Your Name" => "your.email@example.com" }
    s.source           = { :git => "https://github.com/example/MyModules.git", :tag => s.version.to_s }
    s.requires_arc     = true
    s.module_name      = 'BObjC'
    s.ios.deployment_target  = "14.0"
    s.macos.deployment_target = "11.0"
    s.swift_versions   = ["5.0"]
    
    s.source_files = 'Sources/BObjC/**/*.swift'
    s.dependency 'MyModules-B', "~> #{s.version}"
end

