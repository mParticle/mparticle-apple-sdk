#!/bin/bash

#
# xcframework.sh
# Paramaters: ./xcframework.sh [scheme]
# Usage examples: 
#   ./xcframework.sh mParticle-Apple-SDK
#   ./xcframework.sh mParticle-Apple-SDK-NoLocation
#

set -euo pipefail

SCHEME=$1
MODULE=${SCHEME//[-]/_}

xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=iOS" -archivePath "archives/$SCHEME-iOS"
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=iOS Simulator" -archivePath "archives/$SCHEME-iOS_Simulator"
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=tvOS" -archivePath "archives/$SCHEME-tvOS"
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=tvOS Simulator" -archivePath "archives/$SCHEME-tvOS_Simulator"
xcodebuild -create-xcframework \
    -archive archives/$SCHEME-iOS.xcarchive -framework $MODULE.framework \
    -archive archives/$SCHEME-iOS_Simulator.xcarchive -framework $MODULE.framework \
    -archive archives/$SCHEME-tvOS.xcarchive -framework $MODULE.framework \
    -archive archives/$SCHEME-tvOS_Simulator.xcarchive -framework $MODULE.framework \
    -output $MODULE.xcframework
