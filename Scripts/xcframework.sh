#!/bin/bash

#
# xcframework.sh
# Parameters: ./xcframework.sh [project] [ios_scheme] [tvos_scheme (optional)]
# Usage examples:
#   ./xcframework.sh mParticle-Apple-SDK.xcodeproj mParticle-Apple-SDK mParticle-Apple-SDK
#   ./xcframework.sh kits/braze/braze-12/mParticle-Appboy.xcodeproj mParticle-Appboy mParticle-Appboy-tvOS
#   ./xcframework.sh kits/some-kit/SomeKit.xcodeproj SomeKit
#

set -euo pipefail

PROJECT=$1
IOS_SCHEME=$2
TVOS_SCHEME=${3-}
MODULE=${IOS_SCHEME//[-]/_}

# iOS (required)
xcodebuild archive -project "${PROJECT}" -scheme "$IOS_SCHEME" -destination "generic/platform=iOS" -archivePath "archives/$IOS_SCHEME-iOS"
xcodebuild archive -project "${PROJECT}" -scheme "$IOS_SCHEME" -destination "generic/platform=iOS Simulator" -archivePath "archives/$IOS_SCHEME-iOS_Simulator"

FRAMEWORK_ARGS=(
	-archive "archives/${IOS_SCHEME}-iOS.xcarchive" -framework "${MODULE}.framework"
	-archive "archives/${IOS_SCHEME}-iOS_Simulator.xcarchive" -framework "${MODULE}.framework"
)

# tvOS (optional)
if [[ -n ${TVOS_SCHEME} ]]; then
	xcodebuild archive -project "${PROJECT}" -scheme "$TVOS_SCHEME" -destination "generic/platform=tvOS" -archivePath "archives/$TVOS_SCHEME-tvOS"
	xcodebuild archive -project "${PROJECT}" -scheme "$TVOS_SCHEME" -destination "generic/platform=tvOS Simulator" -archivePath "archives/$TVOS_SCHEME-tvOS_Simulator"

	FRAMEWORK_ARGS+=(
		-archive "archives/${TVOS_SCHEME}-tvOS.xcarchive" -framework "${MODULE}.framework"
		-archive "archives/${TVOS_SCHEME}-tvOS_Simulator.xcarchive" -framework "${MODULE}.framework"
	)
fi

xcodebuild -create-xcframework "${FRAMEWORK_ARGS[@]}" -output "${MODULE}.xcframework"

codesign --timestamp -s "Apple Distribution: mParticle, inc (DLD43Y3TRP)" "${MODULE}.xcframework"
zip -r "${MODULE}.xcframework.zip" "${MODULE}.xcframework"
rm -rf archives "$MODULE.xcframework"
