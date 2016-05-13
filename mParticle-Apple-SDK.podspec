Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-SDK"
    s.version          = "6.0.5"
    s.summary          = "mParticle Apple SDK."

    s.description      = <<-DESC
                         Hello! This is the unified mParticle Apple SDK built for the iOS and tvOS platforms.

                         At mParticle our mission is straightforward: make it really easy for apps and app services to connect and take ownership of your 1st party data.
                         Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing,
                         monetization, etc. However, embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs.

                         The mParticle platform addresses all these problems. We support an ever growing number of integrations with services and SDKs, including developer
                         tools, analytics, attribution, messaging, advertising, and more. mParticle has been designed to be the central hub connecting all these services –
                         check [our site](https://www.mparticle.com), or hit us at <dev@mparticle.com> to learn more.
                         DESC

    s.homepage          = "http://www.mparticle.com"
    s.license           = { :type => 'Apache 2.0', :file => 'LICENSE'}
    s.author            = { "mParticle" => "support@mparticle.com" }
    s.source            = { :git => "https://github.com/mParticle/mparticle-apple-sdk.git", :tag => s.version.to_s }
    s.documentation_url = "http://docs.mparticle.com"
    s.social_media_url  = "https://twitter.com/mparticles"
    s.requires_arc      = true
    s.default_subspec   = 'mParticle'
    s.module_name       = "mParticle_Apple_SDK"

    pch_mParticle       = <<-EOS
                          #ifndef TARGET_OS_IOS
                              #define TARGET_OS_IOS TARGET_OS_IPHONE
                          #endif

                          #ifndef TARGET_OS_WATCH
                              #define TARGET_OS_WATCH 0
                          #endif

                          #ifndef TARGET_OS_TV
                              #define TARGET_OS_TV 0
                          #endif
                          EOS
    s.prefix_header_contents = pch_mParticle
    s.ios.deployment_target  = "7.0"
    s.tvos.deployment_target = "9.0"

    s.subspec 'mParticle' do |ss|
        ss.public_header_files = 'mParticle-Apple-SDK/mParticle.h', 'mParticle-Apple-SDK/MPEnums.h', 'mParticle-Apple-SDK/MPUserSegments.h', \
                                 'mParticle-Apple-SDK/Event/MPEvent.h', 'mParticle-Apple-SDK/Ecommerce/MPCommerce.h', 'mParticle-Apple-SDK/Ecommerce/MPCommerceEvent.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPCart.h', 'mParticle-Apple-SDK/Ecommerce/MPProduct.h', 'mParticle-Apple-SDK/Ecommerce/MPPromotion.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPTransactionAttributes.h', 'mParticle-Apple-SDK/Ecommerce/MPBags.h', \
                                 'mParticle-Apple-SDK/MPExtensionProtocol.h', 'mParticle-Apple-SDK/Kits/MPKitProtocol.h', 'mParticle-Apple-SDK/Kits/MPKitRegister.h', \
                                 'mParticle-Apple-SDK/Kits/MPKitExecStatus.h', 'mParticle-Apple-SDK/MPIHasher.h', 'mParticle-Apple-SDK/Ecommerce/MPCommerceEvent+Dictionary.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPCommerceEventInstruction.h','mParticle-Apple-SDK/Ecommerce/MPProduct+Dictionary.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPTransactionAttributes+Dictionary.h', 'mParticle-Apple-SDK/Ecommerce/MPCommerceEvent+Dictionary.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPCommerceEventInstruction.h', 'mParticle-Apple-SDK/Ecommerce/MPProduct+Dictionary.h', 'mParticle-Apple-SDK/Ecommerce/MPTransactionAttributes+Dictionary.h', \
                                 'mParticle-Apple-SDK/Utils/MPDateFormatter.h', 'mParticle-Apple-SDK/Utils/NSDictionary+MPCaseInsensitive.h'

        ss.header_mappings_dir = 'mParticle-Apple-SDK'
        ss.preserve_paths      = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ss.source_files        = 'mParticle-Apple-SDK/**/*'
        ss.libraries           = 'c++', 'sqlite3', 'z'

        ss.ios.frameworks      = 'Accounts', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'Security', 'Social', 'SystemConfiguration', 'UIKit'
        ss.ios.weak_framework  = 'AdSupport', 'iAd'

        ss.tvos.frameworks     = 'CoreGraphics', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
        ss.tvos.weak_framework = 'AdSupport'
    end

    s.subspec 'CrashReporter' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'mParticle-CrashReporter', '~> 1.2'
        ss.ios.prefix_header_contents = "#define MP_CRASH_REPORTER 1"
        ss.ios.deployment_target      = "7.0"
    end
end
