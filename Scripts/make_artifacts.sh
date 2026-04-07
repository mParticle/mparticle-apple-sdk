#!/bin/bash

#
# This script creates pre-built SDK artifacts that will be attached to the GitHub release.
#

# --- Functions ---

function build_xcframework_artifacts() {
	# Build modern xcframeworks which work on M1 macs and include both platforms in one package
	./Scripts/xcframework.sh mParticle-Apple-SDK mParticle_Apple_SDK

	# Sign the xcframework
	codesign --timestamp -s "Apple Distribution: mParticle, inc (DLD43Y3TRP)" mParticle_Apple_SDK.xcframework

	# Zip the xcframework
	zip -r mParticle_Apple_SDK.xcframework.zip mParticle_Apple_SDK.xcframework

	# Clean up temp files
	rm -rf archives mParticle_Apple_SDK.xcframework
}

# --- Main ---

build_xcframework_artifacts

# Ensure the script always exits successfully for the release process
exit 0
