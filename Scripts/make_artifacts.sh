#!/bin/bash

#
# This script creates pre-built SDK artifacts that will be attached to the GitHub release.
#

# --- Functions ---

function build_xcframework_artifacts() {
	# Build modern xcframeworks which work on M1 macs and include both platforms in one package
	./Scripts/xcframework.sh mParticle-Apple-SDK mParticle_Apple_SDK

	IDENTITY="Apple Distribution: mParticle, inc (DLD43Y3TRP)"

	# mParticle_Apple_SDK.framework embeds mParticle_Apple_SDK_Swift.framework as a nested
	# framework in each platform slice. Signing the xcframework wrapper only seals its file
	# manifest - it does not add a code signature to the Mach-O binaries inside. The outer
	# framework gets re-signed by a consuming app's own build when it is embedded, but a
	# nested framework is just copied verbatim and is never re-signed by the consumer, so it
	# must already carry a valid signature here. Sign inside-out: nested framework first,
	# then the framework that embeds it, for every platform slice. Simulator slices already
	# carry an automatic ad-hoc signature from the archive step (device slices do not), so
	# --force is required or codesign refuses to replace it.
	for framework in mParticle_Apple_SDK.xcframework/*/mParticle_Apple_SDK.framework; do
		nested="${framework}/Frameworks/mParticle_Apple_SDK_Swift.framework"
		if [[ -d ${nested} ]]; then
			codesign --force --timestamp -s "${IDENTITY}" "${nested}"
		fi
		codesign --force --timestamp -s "${IDENTITY}" "${framework}"
	done

	# Sign the xcframework
	codesign --force --timestamp -s "${IDENTITY}" mParticle_Apple_SDK.xcframework

	# Zip the xcframework
	zip -r mParticle_Apple_SDK.xcframework.zip mParticle_Apple_SDK.xcframework

	# Clean up temp files
	rm -rf archives mParticle_Apple_SDK.xcframework
}

# --- Main ---

build_xcframework_artifacts

# Ensure the script always exits successfully for the release process
exit 0
