Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-SDK"
    s.version          = "8.32.0"
    s.summary          = "mParticle Apple SDK."

    s.description      = <<-DESC
                         This is the mParticle Apple SDK for iOS and tvOS.
                         
                         At mParticle our mission is straightforward: make it really easy for apps and app services to connect and allow you to take ownership of your 1st party data.
                         Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing,
                         monetization, etc. However, embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs.

                         The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer
                         tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services –
                         read the [docs](https://docs.mparticle.com/developers/sdk/ios/) or contact us at <support@mparticle.com> to learn more.
                         DESC

    s.homepage          = "https://www.mparticle.com"
    s.license           = { :type => 'Apache 2.0', :file => 'LICENSE'}
    s.author            = { "mParticle" => "support@mparticle.com" }
    s.source            = { :git => "https://github.com/mParticle/mparticle-apple-sdk.git", :tag => "v" + s.version.to_s }
    s.documentation_url = "https://docs.mparticle.com/developers/sdk/ios/"
    s.social_media_url  = "https://twitter.com/mparticle"
    s.requires_arc      = true
    s.default_subspec   = 'mParticle'
    s.module_name       = 'mParticle_Apple_SDK'
    s.ios.deployment_target  = "9.0"
    s.tvos.deployment_target = "9.0"
    s.swift_versions = ["5.0"]

    s.subspec 'mParticle' do |ss|
        ss.public_header_files = 'mParticle-Apple-SDK/Include/*.h'
        ss.preserve_paths       = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ss.source_files         = 'mParticle-Apple-SDK/**/*.{h,m,mm,cpp,swift}'
        ss.resource_bundles = {'mParticle-Privacy' => ['PrivacyInfo.xcprivacy']}
    end
    
    s.subspec 'mParticleNoLocation' do |ss|
        ss.public_header_files = 'mParticle-Apple-SDK/Include/*.h'
        ss.preserve_paths       = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ss.source_files         = 'mParticle-Apple-SDK/**/*.{h,m,mm,cpp,swift}'
        ss.resource_bundles = {'mParticle-Privacy' => ['PrivacyInfo.xcprivacy']}
        ss.pod_target_xcconfig  = {
            'GCC_PREPROCESSOR_DEFINITIONS' => 'MPARTICLE_LOCATION_DISABLE=1',
            'OTHER_SWIFT_FLAGS' => '-D MPARTICLE_LOCATION_DISABLE'
        }
    end

    s.subspec 'AppExtension' do |ext|
        ext.public_header_files = 'mParticle-Apple-SDK/Include/*.h'
        ext.preserve_paths       = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ext.source_files         = 'mParticle-Apple-SDK/**/*.{h,m,mm,cpp,swift}'
    end
    
    s.subspec 'AppExtensionNoLocation' do |ext|
        ext.public_header_files = 'mParticle-Apple-SDK/Include/*.h'
        ext.preserve_paths       = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ext.source_files         = 'mParticle-Apple-SDK/**/*.{h,m,mm,cpp,swift}'
        ext.pod_target_xcconfig  = {
            'GCC_PREPROCESSOR_DEFINITIONS' => 'MPARTICLE_LOCATION_DISABLE=1',
            'OTHER_SWIFT_FLAGS' => '-D MPARTICLE_LOCATION_DISABLE'
        }
    end
end

