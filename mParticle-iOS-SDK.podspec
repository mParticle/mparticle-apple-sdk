Pod::Spec.new do |s|
    s.name             = "mParticle-iOS-SDK"
    s.version          = "5.1.5"
    s.summary          = "mParticle iOS SDK."

    s.description      = <<-DESC
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
    s.source            = { :git => "https://github.com/mParticle/mParticle-iOS-SDK.git", :tag => s.version.to_s }
    s.documentation_url = "http://docs.mparticle.com"
    s.docset_url        = "https://static.mparticle.com/sdk/ios/com.mparticle.mParticle-SDK.docset/Contents/Resources/Documents/index.html"
    s.social_media_url  = "https://twitter.com/mparticles"
    s.requires_arc      = true
    s.platform          = :ios, '7.0'
    s.default_subspecs  = 'mParticle', 'CrashReporter', 'Adjust', 'Appboy', 'BranchMetrics', 'comScore', 'Flurry', 'Kahuna', 'Kochava', 'Localytics'

    s.subspec 'Core-SDK' do |ss|
        ss.public_header_files = 'Pod/Classes/mParticle.h', 'Pod/Classes/MPEnums.h', 'Pod/Classes/MPUserSegments.h', \
                                 'Pod/Classes/Event/MPEvent.h', 'Pod/Classes/Ecommerce/MPCommerce.h', 'Pod/Classes/Ecommerce/MPCommerceEvent.h', \
                                 'Pod/Classes/Ecommerce/MPCart.h', 'Pod/Classes/Ecommerce/MPProduct.h', 'Pod/Classes/Ecommerce/MPPromotion.h', \
                                 'Pod/Classes/Ecommerce/MPTransactionAttributes.h', 'Pod/Classes/Ecommerce/MPBags.h'
        ss.source_files        = 'Pod/Classes/**/*'
        ss.platform            = :ios, '7.0'
        ss.frameworks          = 'Accounts', 'CoreGraphics', 'CoreLocation', 'CoreTelephony', 'Foundation', 'Security', 'Social', 'SystemConfiguration', 'UIKit'
        ss.weak_framework      = 'AdSupport', 'iAd'
        ss.libraries           = 'c++', 'sqlite3', 'z'
    end

    s.subspec 'Adjust' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'Adjust', '~> 4.3'
        ss.prefix_header_contents = "#define MP_KIT_ADJUST 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'Appboy' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'Appboy-iOS-SDK', '~> 2.17'
        ss.prefix_header_contents = "#define MP_KIT_APPBOY 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'BranchMetrics' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'Branch', '0.11'
        ss.prefix_header_contents = "#define MP_KIT_BRANCHMETRICS 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'comScore' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'comScore-iOS-SDK', '~> 3.1502.26'
        ss.prefix_header_contents = "#define MP_KIT_COMSCORE 1"
        ss.platform               = :ios, '7.0'
        ss.frameworks             = 'AVFoundation', 'CoreMedia', 'MediaPlayer'
    end

    s.subspec 'Crittercism' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'CrittercismSDK', '5.4.0'
        ss.prefix_header_contents = "#define MP_KIT_CRITTERCISM 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'Flurry' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'Flurry-iOS-SDK/FlurrySDK'
        ss.prefix_header_contents = "#define MP_KIT_FLURRY 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'Kahuna' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'KahunaSDK', '1.0.571'
        ss.prefix_header_contents = "#define MP_KIT_KAHUNA 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'Kochava' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'Kochava'
        ss.prefix_header_contents = "#define MP_KIT_KOCHAVA 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'Localytics' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'Localytics', '~> 3.5'
        ss.prefix_header_contents = "#define MP_KIT_LOCALYTICS 1"
        ss.platform               = :ios, '7.0'
    end

    s.subspec 'mParticle' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.prefix_header_contents = "#define MP_KIT_MPARTICLE 1"
        ss.platform               = :ios, '7.0'
    end
    
    s.subspec 'CrashReporter' do |ss|
        ss.dependency 'mParticle-iOS-SDK/Core-SDK'
        ss.dependency 'mParticle-iOS-SDK/mParticle'
        ss.dependency 'mParticle-CrashReporter', '~> 1.2'
        ss.prefix_header_contents = "#define MP_CRASH_REPORTER 1"
        ss.platform               = :ios, '7.0'
    end
end
