#!/bin/bash

#
# xcframework.sh
# Paramaters: ./xcframework.sh [scheme]
# Usage example:
#   ./xcframework.sh mParticle-Apple-SDK
# Produces mParticle_Apple_SDK.xcframework and mParticle_Apple_SDK_Swift.xcframework.
#

set -euo pipefail

SCHEME=$1
MODULE=${SCHEME//[-]/_}
SWIFT_MODULE=mParticle_Apple_SDK_Swift
PLATFORMS=(iOS iOS_Simulator tvOS tvOS_Simulator)

xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=iOS" -archivePath "archives/$SCHEME-iOS"
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=iOS Simulator" -archivePath "archives/$SCHEME-iOS_Simulator"
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=tvOS" -archivePath "archives/$SCHEME-tvOS"
xcodebuild archive -project mParticle-Apple-SDK.xcodeproj -scheme $SCHEME -destination "generic/platform=tvOS Simulator" -archivePath "archives/$SCHEME-tvOS_Simulator"

# The framework target embeds $SWIFT_MODULE.framework in its own Frameworks directory, but iOS
# and tvOS do not support nested frameworks: an app's Embed & Sign never re-signs the nested
# one, so it fails to load on device, and App Store Connect rejects the bundle (ITMS-90206).
# Move it out so it ships as its own xcframework, embedded by apps beside $MODULE.xcframework.
for platform in "${PLATFORMS[@]}"; do
	frameworks="archives/${SCHEME}-${platform}.xcarchive/Products/Library/Frameworks"
	mv "${frameworks}/${MODULE}.framework/Frameworks/${SWIFT_MODULE}.framework" "${frameworks}/"
	rmdir "${frameworks}/${MODULE}.framework/Frameworks"
done

for module in ${MODULE} ${SWIFT_MODULE}; do
	args=()
	for platform in "${PLATFORMS[@]}"; do
		args+=(-archive "archives/${SCHEME}-${platform}.xcarchive" -framework "${module}.framework")
	done
	xcodebuild -create-xcframework "${args[@]}" -output "${module}.xcframework"
done
