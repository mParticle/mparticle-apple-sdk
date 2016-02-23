Pod::Spec.new do |s|
    s.name             = "mParticle-Apple-SDK"
    s.version          = "5.4.0-alpha-2"
    s.summary          = "mParticle Apple SDK."

    s.description      = <<-DESC
                         Hello! This is the unified mParticle Apple SDK. It currently supports iOS and tvOS, however we plan to continue adding
                         support for more platforms in the future. Since 2013 we have been working tirelessly on developing each component of our platform.
                         We could not be more excited to be able to share it with you.

                         Your job is to build an awesome app experience that consumers love. You also need several tools and services to make data-driven decisions.
                         Like most app owners, you end up implementing and maintaining numerous SDKs ranging from analytics, attribution, push notification, remarketing,
                         monetization, etc. But embedding multiple 3rd party libraries creates a number of unintended consequences and hidden costs. From not being
                         able to move as fast as you want, to bloating and destabilizing your app, to losing control and ownership of your 1st party data.

                         mParticle solves all these problems with one lightweight SDK. Implement new partners without changing code or waiting for app store approval.
                         Improve stability and security within your app. We enable our clients to spend more time innovating and less time integrating.
                         DESC

    s.homepage          = "http://www.mparticle.com"
    s.license           = { :type => 'Apache 2.0', :file => 'LICENSE'}
    s.author            = { "mParticle" => "support@mparticle.com" }
    s.source            = { :git => "https://github.com/mParticle/mParticle-ObjC-SDK.git", :tag => s.version.to_s }
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
    s.ios.deployment_target  = "8.0"
    s.tvos.deployment_target = "9.0"

    s.subspec 'Core-SDK' do |ss|
        ss.public_header_files = 'mParticle-Apple-SDK/mParticle.h', 'mParticle-Apple-SDK/MPEnums.h', 'mParticle-Apple-SDK/MPUserSegments.h', \
                                 'mParticle-Apple-SDK/Event/MPEvent.h', 'mParticle-Apple-SDK/Ecommerce/MPCommerce.h', 'mParticle-Apple-SDK/Ecommerce/MPCommerceEvent.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPCart.h', 'mParticle-Apple-SDK/Ecommerce/MPProduct.h', 'mParticle-Apple-SDK/Ecommerce/MPPromotion.h', \
                                 'mParticle-Apple-SDK/Ecommerce/MPTransactionAttributes.h', 'mParticle-Apple-SDK/Ecommerce/MPBags.h', \
                                 'mParticle-Apple-SDK/Kits/MPKitProtocol.h', 'mParticle-Apple-SDK/Kits/MPKitRegister.h', 'mParticle-Apple-SDK/Kits/MPKitContainer.h'

        ss.header_mappings_dir = 'mParticle-Apple-SDK'
        ss.preserve_paths      = 'mParticle-Apple-SDK', 'mParticle-Apple-SDK/**', 'mParticle-Apple-SDK/**/*'
        ss.source_files        = 'mParticle-Apple-SDK/**/*'
        ss.libraries           = 'c++', 'sqlite3', 'z'

        ss.ios.frameworks      = 'Accounts', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'Security', 'Social', 'SystemConfiguration', 'UIKit'
        ss.ios.weak_framework  = 'AdSupport', 'iAd'

        ss.tvos.frameworks     = 'CoreGraphics', 'Foundation', 'Security', 'SystemConfiguration', 'UIKit'
        ss.tvos.weak_framework = 'AdSupport'
    end

    s.subspec 'Adjust' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'Adjust', '~> 4.3'
        ss.ios.prefix_header_contents = "#define MP_KIT_ADJUST 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Appboy' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'Appboy-iOS-SDK', '~> 2.18'
        ss.ios.prefix_header_contents = "#define MP_KIT_APPBOY 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'AppsFlyer' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'AppsFlyer-SDK', '~> 4.3'
        ss.ios.prefix_header_contents = "#define MP_KIT_APPSFLYER 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'BranchMetrics' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'Branch', '~> 0.11'
        ss.ios.prefix_header_contents = "#define MP_KIT_BRANCHMETRICS 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'comScore' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'comScore-iOS-SDK', '~> 3.1502.26'
        ss.ios.prefix_header_contents = "#define MP_KIT_COMSCORE 1"
        ss.ios.deployment_target      = "8.0"
        ss.ios.frameworks             = 'AVFoundation', 'CoreMedia', 'MediaPlayer'
    end

    s.subspec 'Crittercism' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'CrittercismSDK', '5.4.0'
        ss.ios.prefix_header_contents = "#define MP_KIT_CRITTERCISM 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Flurry' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'Flurry-iOS-SDK/FlurrySDK'
        ss.ios.prefix_header_contents = "#define MP_KIT_FLURRY 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Kahuna' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'KahunaSDK', '1.0.571'
        ss.ios.prefix_header_contents = "#define MP_KIT_KAHUNA 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Kochava' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'Kochava'
        ss.ios.prefix_header_contents = "#define MP_KIT_KOCHAVA 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Localytics' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'Localytics', '~> 3.5'
        ss.ios.prefix_header_contents = "#define MP_KIT_LOCALYTICS 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Tune' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.prefix_header_contents = "#define MP_KIT_TUNE 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'Wootric' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'WootricSDK'
        ss.ios.prefix_header_contents = "#define MP_KIT_WOOTRIC 1"
        ss.ios.deployment_target      = "8.0"
    end

    s.subspec 'mParticle' do |ss|
        ss.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.prefix_header_contents = "#define MP_KIT_MPARTICLE 1"
    end

    s.subspec 'CrashReporter' do |ss|
        ss.ios.dependency 'mParticle-Apple-SDK/Core-SDK'
        ss.ios.dependency 'mParticle-Apple-SDK/mParticle'
        ss.ios.dependency 'mParticle-CrashReporter', '~> 1.2'
        ss.ios.prefix_header_contents = "#define MP_CRASH_REPORTER 1"
        ss.ios.deployment_target      = "8.0"
    end
end
