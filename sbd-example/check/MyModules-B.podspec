Pod::Spec.new do |s|
    s.name             = "MyModules-B"
    s.version          = "1.0.0"
    s.summary          = "MyModules B - Pure Swift module"
    
    s.description      = <<-DESC
                         Pure Swift module with structs, generics and Swift-only features.
                         This is the core Swift module that contains the business logic.
                         DESC
    
    s.homepage         = "https://github.com/example/MyModules"
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { "Your Name" => "your.email@example.com" }
    s.source           = { :git => "https://github.com/example/MyModules.git", :tag => s.version.to_s }
    s.requires_arc     = true
    s.module_name      = 'B'
    s.ios.deployment_target  = "14.0"
    s.macos.deployment_target = "11.0"
    s.swift_versions   = ["5.0"]
    
    s.source_files = 'Sources/B/**/*.swift'
end

